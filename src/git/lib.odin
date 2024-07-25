package git

import "core:log"
import "core:os"
import "core:path/filepath"

is_initialized :: proc(pwd: string) -> bool {
	return os.exists(filepath.join({pwd, ".git"}, context.temp_allocator))
}

read_head_file :: proc(pwd: string) -> (data: []byte, ok: bool) {
	git_head_file := filepath.join({pwd, ".git", "HEAD"}, context.temp_allocator)
	data, ok = os.read_entire_file(git_head_file, context.temp_allocator)

	return
}

is_head_detached :: proc(data: []byte) -> bool {
	return data[15] != '/'
}

branch :: proc() -> (name: string, ok: bool) {
	pwd := os.get_current_directory()
	defer delete(pwd)

	if !is_initialized(pwd) do return

	data: []byte
	data, ok = read_head_file(pwd)

	if !ok || is_head_detached(data) do return "", false

	name = cast(string)data[16:len(data) - 1]
	return
}
