package wish

import "core:fmt"
import "core:os"

BUILTIN_STR: [3]string : {"cd", "help", "exit"}

cd :: proc(args: []string) -> StatusCode {
	path: string

	if len(args) < 2 {
		path = os.get_env("HOME")
	} else {
		path = args[1]
	}

	err := os.set_current_directory(path);if err != os.ERROR_NONE {
		fmt.println(ERROR, "changing directory to home")
		return .Error
	}

	return .Ok
}

/// Display information about built-in commands
help :: proc() -> StatusCode {
	fmt.println("Dan Castrillos's WISH")
	fmt.println("Type program names and arguments, and hit enter.")
	fmt.println("The following are built in:")

	for str in BUILTIN_STR {
		fmt.println("  ", str)
	}

	fmt.println("Use the man command for information on other programs.")

	return .Ok
}
