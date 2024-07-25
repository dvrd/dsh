package main

import "cmd"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "history"
import "termios"

BUILTIN_CMDS := []string{"cd", "pwd", "type", "echo", "help", "exit", "where"}

// [C]hange [D]irectory
change_directory :: proc(args: []string) -> StatusCode {
	path, ok := slice.get(args, 1)
	log.debug(path)
	if !ok || path == "~" {
		path = os.get_env("HOME", context.temp_allocator)
	}

	if path[0] == '~' {
		path = filepath.join(
			{os.get_env("HOME", context.temp_allocator), path[1:]},
			context.temp_allocator,
		)
		log.debug(path)
	}

	err := os.set_current_directory(path)

	if err != os.ERROR_NONE {
		fmt.println(RED + "ERROR:" + RESET, os.get_last_error_string())
		return .Error
	}

	return .Ok
}

find_command :: proc(args: []string) -> StatusCode {
	command, ok := slice.get(args, 1)
	if !ok do return .Error

	path, found := cmd.find_program(command)
	if found {
		fmt.printfln("{}", path)
		return .Ok
	}

	fmt.printfln("{} not found", command)
	return .Error
}

// Clear terminal screen
clear_term :: proc() -> StatusCode {
	fmt.fprint(os.stdout, GO_HOME)
	fmt.fprint(os.stdout, CLEAR_FORWARD)
	print_prompt()
	fmt.fprint(os.stdout, SAVE_CURSOR)
	return .Ok
}

// Expand string and display it
echo :: proc(args: []string) -> StatusCode {
	echoed_str, ok := slice.get(args, 1)
	if ok {
		fmt.fprintf(os.stdout, "{}\r\n", echoed_str)
	}
	return ok ? .Ok : .Error
}

// Display type of command
type_of_command :: proc(args: []string) -> StatusCode {
	command, ok := slice.get(args, 1)

	if !ok do return .Error

	if slice.contains(BUILTIN_CMDS[:], command) {
		fmt.printfln("{} is a shell builtin", command)
		return .Ok
	}

	path, found := cmd.find_program(command)
	if found {
		fmt.printfln("{} is {}", command, path)
		return .Ok
	}

	fmt.printfln("{}: not found", command)
	return .Error
}

// [P]rint [W]orking [D]irectory
print_working_directory :: proc(args: []string) -> StatusCode {
	pwd := os.get_current_directory()
	defer delete(pwd)
	fmt.println(pwd)
	return .Ok
}

// Display information about built-in commands
show_help :: proc() -> StatusCode {
	fmt.println(colorize("dsh", rgb(120, 30, 50)))
	fmt.println("Type program names and arguments, and hit enter.")
	fmt.println("The following are built in:")

	for cmd in BUILTIN_CMDS {
		fmt.println("  ", cmd)
	}

	fmt.println("Use the man command for information on other programs.")

	return .Ok
}

// Launch command on forked process
launch :: proc(command: string, args: []string) -> (res: StatusCode) {

	if command[:2] == "./" {
		termios.restore()
		res = cmd.launch(args) == .ERROR_NONE ? .Ok : .Error
		termios.set()
		return
	}

	_, found := cmd.find_program(command)
	if found {
		termios.restore()
		res = cmd.launch(args) == .ERROR_NONE ? .Ok : .Error
		termios.set()
	} else {
		fmt.printfln("command not found: {}", command)
		res = .Error
	}
	return
}

print_history :: proc() -> StatusCode {
	for entry, idx in history.hist.data[:min(len(history.hist.data), 15)] {
		fmt.fprintf(os.stdout, "{} {}\r\n", idx, entry)
	}
	return .Ok
}
