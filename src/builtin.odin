package wish

import "cmd"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:slice"

BUILTIN_CMDS := []string{"cd", "pwd", "echo", "help", "exit"}

// [C]hange [D]irectory
cd :: proc(args: []string) -> StatusCode {
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

echo :: proc(args: []string) -> StatusCode {
	echoed_str, ok := slice.get(args, 1)
	if ok do fmt.println(echoed_str)
	return ok ? .Ok : .Error
}

type :: proc(args: []string) -> StatusCode {
	command, ok := slice.get(args, 1)
	if slice.contains(BUILTIN_CMDS[:], command) {
		fmt.printfln("{} is a shell builtin", command)
	} else {
		path, found := cmd.find_program(command)
		if found {
			fmt.printfln("{} is {}", command, path)
		} else {
			fmt.printfln("{}: not found", command)
		}
	}

	return ok ? .Ok : .Error
}

pwd :: proc(args: []string) -> StatusCode {
	pwd := os.get_current_directory()
	defer delete(pwd)
	fmt.println(pwd)
	return .Ok
}

// Display information about built-in commands
help :: proc() -> StatusCode {
	fmt.println("dvrd's WISH")
	fmt.println("Type program names and arguments, and hit enter.")
	fmt.println("The following are built in:")

	for cmd in BUILTIN_CMDS {
		fmt.println("  ", cmd)
	}

	fmt.println("Use the man command for information on other programs.")

	return .Ok
}
