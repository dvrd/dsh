package wish

import "cmd"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
	Exit,
}

TRACK_LEAKS :: #config(TRACK_LEAKS, true)
LOG_FILE :: #config(LOG_FILE, "wish.log")

main :: proc() {
	fd, _ := os.open(LOG_FILE, os.O_WRONLY | os.O_CREATE | os.O_APPEND, 0o777)
	context.logger = log.create_file_logger(fd, opt = {.Level, .Short_File_Path, .Terminal_Color})
	when TRACK_LEAKS {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}

	buf: [256]byte
	args: []string
	status := StatusCode.Ok

	for status != .Exit {
		print_prompt(status)
		args = readline(buf[:])
		status = execute(args)

		when TRACK_LEAKS {
			for b in track.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}

			clear(&track.bad_free_array)
		}

		free_all(context.temp_allocator)
	}

	when TRACK_LEAKS {
		for _, value in track.allocation_map {
			log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
		}

		mem.tracking_allocator_destroy(&track)
	}
}

readline :: proc(buf: []byte, allocator := context.temp_allocator) -> []string {
	n, err := os.read(os.stdin, buf)
	if cmd.Errno(err) != .ERROR_NONE {
		log.error(ERROR, "os.read: ", ERROR_MSG[err])
		return {}
	}

	command := cast(string)buf[:n - 1]
	log.debugf("cmd: '{}' | buf: {}", command, buf[:n])
	return strings.fields(command, allocator)
}

execute :: proc(args: []string) -> StatusCode {
	command, ok := slice.get(args, 0)
	if !ok do return .Usage

	switch command {
	case "^L":
		return cmd.launch({"clear"}) == .ERROR_NONE ? .Ok : .Error
	case "cd":
		return cd(args)
	case "echo":
		return echo(args)
	case "type":
		return type(args)
	case "help":
		return help()
	case "exit":
		return .Exit
	case:
		return cmd.launch(args) == .ERROR_NONE ? .Ok : .Error
	}
}
