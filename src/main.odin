package main

import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "termios"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
	Exit,
}

TRACK_LEAKS :: #config(TRACK_LEAKS, true)
LOG_FILE :: #config(LOG_FILE, "wish.log")

main :: proc() {
	when TRACK_LEAKS {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}

	fd, errno := os.open(LOG_FILE, os.O_WRONLY | os.O_CREATE | os.O_APPEND, 0o777)
	if errno == os.ERROR_NONE {
		defer os.close(fd)
		context.logger = log.create_file_logger(fd, opt = {.Level, .Short_File_Path})
	}

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

	when TRACK_LEAKS {
		for _, value in track.allocation_map {
			log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
		}

		mem.tracking_allocator_destroy(&track)
	}
}

execute :: proc(args: []string) -> StatusCode {
	log.debug("executing", args)
	command, ok := slice.get(args, 0)
	if !ok do return .Usage

	switch command {
	case "cd":
		return change_directory(args)
	case "pwd":
		return print_working_directory(args)
	case "clear":
		return clear_term()
	case "echo":
		return echo(args)
	case "type":
		return type_of_command(args)
	case "where":
		return find_command(args)
	case "help":
		return show_help()
	case "exit":
		return .Exit
	case:
		return launch(command, args)
	}
}
