package main

import "core:fmt"
import "core:log"
import "core:strings"
import "core:mem"
import "core:os"
import "core:slice"
import "termios"
import "history"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
	Exit,
}

TRACK_LEAKS :: #config(TRACK_LEAKS, true)
LOG_FILE :: #config(LOG_FILE, "dsh.log")
HIST_FILE :: #config(HIST_FILE, "dsh.hist")

LOG: os.Handle

main :: proc() {
	when TRACK_LEAKS {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}

	LOG, _ = os.open(LOG_FILE, os.O_WRONLY | os.O_CREATE | os.O_APPEND, 0o777)
	defer os.close(LOG)
	context.logger = log.create_file_logger(LOG, opt = {.Level, .Short_File_Path, .Line})
	defer free(context.logger.data)

	history.init(HIST_FILE)
	defer history.close()

	fmt.println("\nWelcome to dsh-1.0")

	termios.set()
	defer termios.restore()

	args: []string
	status := StatusCode.Ok

	for status != .Exit {
		args = read_prompt(status)
		status = execute(args)
		os.write(os.stdout, {'\n'})

		when TRACK_LEAKS {
			for b in track.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}

			clear(&track.bad_free_array)
		}

		free_all(context.temp_allocator)
	}
}

execute :: proc(args: []string) -> (res: StatusCode) {
	log.debug("executing", args)
	command, ok := slice.get(args, 0)
	if !ok do return .Usage

	switch command {
	case "cd":
		res = change_directory(args)
	case "pwd":
		res = print_working_directory(args)
	case "clear":
		res = clear_term()
	case "echo":
		res = echo(args)
	case "type":
		res = type_of_command(args)
	case "where":
		res = find_command(args)
	case "help":
		res = show_help()
	case "exit":
		res = .Exit
	case "history":
		res = print_history()
	case:
		res = launch(command, args)
	}

	history.add_entry(strings.join(args, " "))
	return
}
