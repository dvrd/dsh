package history

import "core:log"
import "core:os"
import "core:io"
import "core:strings"
import "core:bytes"

History :: struct {
	data:   [dynamic]string,
	cursor: int,
	fd:     os.Handle,
}

hist: ^History

close :: proc() {
	for cmd in hist.data do delete(cmd)
	delete(hist.data)
	os.close(hist.fd)
	free(hist)
}

last_entry :: proc() -> string {
	if hist.cursor < 0 || hist.cursor >= len(hist.data) {
		log.error("OUT OF BOUNDS ENTRY SEARCH")
		return ""
	}
	log.debugf("GETTING [{}] {}", hist.cursor, hist.data)
	return hist.data[hist.cursor]
}

travel_back :: proc() {
	log.debugf("TRAVELING BACK (LEN: {}) {} -> {}", len(hist.data), hist.cursor, min(len(hist.data) - 1, hist.cursor + 1))
	hist.cursor = max(0, hist.cursor - 1)
}

travel_forward :: proc() {
	log.debugf("TRAVELING FORWARD (LEN: {}) {} -> {}", len(hist.data), hist.cursor, min(len(hist.data) - 1, hist.cursor - 1))
	hist.cursor = min(len(hist.data) - 1, hist.cursor + 1)
}

add_entry :: proc(data: string) {
	log.debug("ADDING TO HISTORY:", data)
	os.write_string(hist.fd, data)
	os.write_byte(hist.fd, '\n')
	pop(&hist.data)
	append(&hist.data, data)
	append(&hist.data, "")
	travel_forward()
}

load_entry :: proc(buf: []byte, buf_len: ^int) {
	hist_entry := last_entry()
	log.debug("LOADING ENTRY:", hist_entry)
	for char, idx in hist_entry {
		if idx >= len(buf) do break
		buf[idx] = cast(byte)char
	}
	buf_len^ = len(hist_entry)
}

init :: proc(path: string) {
	hist = new(History)
	hist.data = make([dynamic]string)
	hist.fd, _ = os.open(path, os.O_WRONLY | os.O_CREATE | os.O_APPEND, 0o777)

	log.debug("INIT HISTORY")

	data, ok := os.read_entire_file(path)
	if !ok do log.debug("ERROR:", os.get_last_error_string)

	file_buf: bytes.Buffer
	bytes.buffer_init(&file_buf, data)
	
	err: io.Error
	entry: string
	for err != .EOF {
		entry, err = bytes.buffer_read_string(&file_buf, '\n')
		entry = strings.trim_space(entry)
		if len(entry) != 0 do append(&hist.data, entry)
	}
	hist.cursor = len(hist.data)
	append(&hist.data, "")
	log.debug("HISTORY:", hist.data)
}
