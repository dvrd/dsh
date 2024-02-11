package wish

import "core:fmt"
import "core:os"
import "core:strings"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
}

launch :: proc(args: []string) -> StatusCode {
	wpid: Pid
	status: u32

	pid, err := fork();if err != os.ERROR_NONE {
		fmt.eprintln(ERROR, "ERROR: forking process")
		os.exit(1)
	}

	if (pid == 0) {
		err = exec(args[0], args[1:]);if err != os.ERROR_NONE {
			fmt.eprintln(ERROR, "execvp failed", err)
			os.exit(1)
		}
		os.exit(0)
	} else {
		for {
			wpid, err = waitpid(pid, &status, {Wait_Option.WUNTRACED});if err != os.ERROR_NONE {
				fmt.eprintln(ERROR, "ERROR: no child process found to wait for")
				os.exit(1)
			}

			if WIFEXITED(status) || WIFSIGNALED(status) {
				break
			}
		}
	}

	return .Ok
}

execute :: proc(args: []string) -> StatusCode {
	if len(args) == 0 {
		return .Usage
	}

	switch args[0] {
	case "cd":
		return cd(args)
	case "help":
		return help()
	case "exit":
		os.exit(0)
	case:
		return launch(args)
	}
}

main :: proc() {
	buf: [256]byte
	cmd: string
	args: []string
	status := StatusCode.Ok

	for {
		switch status {
		case .Ok:
			fmt.print(" ", PROMPT, " ")
		case .Error:
			fmt.print(" ", ERROR, " ")
		case .Usage:
			fmt.print(" ", WARNING, " ")
		}

		n, err := os.read(os.stdin, buf[:])
		if err < 0 {
			fmt.eprintln("Error reading from stdin")
			os.exit(1)
		}

		cmd = string(buf[:n])
		args = strings.fields(cmd)

		status = execute(args)
	}
}
