package wish

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
}

launch :: proc(args: []string) -> StatusCode {
	wpid: Pid
	status: u32
	cmd_path := strings.builder_make()

	env_path := os.get_env("PATH")
	dirs := strings.split(env_path, ":")

	if len(dirs) == 0 {
		fmt.eprintln(ERROR, "missing $PATH environment variable")
		return .Error
	}

	base: for dir in dirs {
		fd, err := os.open(dir)
		defer os.close(fd)

		if err != os.ERROR_NONE {
      continue
		}

		fis: []os.File_Info
		defer os.file_info_slice_delete(fis)

		fis, _ = os.read_dir(fd, -1)

		for fi in fis {
			_, filename := filepath.split(fi.fullpath)
			if filename == args[0] {
				fmt.sbprint(&cmd_path, fi.fullpath)
				break base
			}
		}
	}

	if strings.builder_len(cmd_path) == 0 {
		fmt.eprintln(WARNING, "command not found:", args[0])
		return .Error
	}

	pid, err := fork();if err != os.ERROR_NONE {
		fmt.eprintln(ERROR, "fork:", ERROR_MSG[err])
		return .Error
	}

	if (pid == 0) {
		err = exec(strings.to_string(cmd_path), args[1:]);if err != os.ERROR_NONE {
			fmt.eprintln(WARNING, "execve:", ERROR_MSG[err])
			return .Error
		}
		os.exit(0)
	}

	wpid, _ = waitpid(pid, &status, {Wait_Option.WUNTRACED})

	return wpid == pid && WIFEXITED(status) ? .Ok : .Error
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
	cwd := os.get_current_directory()
	stdout := os.stream_from_handle(os.stdout)

	for {
		switch status {
		case .Ok:
			fmt.wprint(stdout, BLUE, cwd, "\n", PROMPT, " ")
		case .Error:
			fmt.wprint(stdout, "", ERROR, " ")
		case .Usage:
			fmt.wprint(stdout, "", WARNING, " ")
		}

		n, err := os.read(os.stdin, buf[:]);if err < 0 {
			fmt.eprintln(ERROR, "os.read: ", ERROR_MSG[err])
			os.exit(1)
		}

		cmd = string(buf[:n])
		args = strings.fields(cmd)

		status = execute(args)
	}
}
