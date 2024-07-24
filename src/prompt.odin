package main

import "core:encoding/ansi"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "git"

RED :: ansi.CSI + ansi.FG_RED + ansi.SGR
GREEN :: ansi.CSI + ansi.FG_GREEN + ansi.SGR
BLUE :: ansi.CSI + ansi.FG_BLUE + ansi.SGR
YELLOW :: ansi.CSI + ansi.FG_YELLOW + ansi.SGR
MAGENTA :: ansi.CSI + ansi.FG_MAGENTA + ansi.SGR

GO_HOME :: ansi.CSI + ansi.CUP
CLEAR_LINE :: ansi.CSI + "2" + ansi.EL
CLEAR_FORWARD :: ansi.CSI + "0" + ansi.ED
RESET :: ansi.CSI + ansi.RESET + ansi.SGR

SAVE_CURSOR :: ansi.CSI + ansi.SCP
RESTORE_CURSOR :: ansi.CSI + ansi.RCP

SUCCESS :: GREEN + CHECK + RESET
ERROR :: RED + XCROSS + RESET
WARNING :: YELLOW + ALERT + RESET

Color :: [3]byte
rgb :: proc(r, g, b: byte) -> Color {
	return {r, g, b}
}

colorize :: proc(str: string, color: Color, allocator := context.temp_allocator) -> string {
	color := fmt.tprintf("\x1B[38;2;%d;%d;%dm", color.r, color.g, color.b)
	return strings.concatenate({color, str, RESET}, allocator)
}

clear_input :: proc() {
	fmt.fprint(os.stdout, RESTORE_CURSOR)
	fmt.fprint(os.stdout, SAVE_CURSOR)
	fmt.fprint(os.stdout, CLEAR_FORWARD)
}


print_prompt :: proc(status := StatusCode.Ok) {
	pwd := os.get_current_directory()
	defer delete(pwd)

	pwd_short_stem := filepath.short_stem(pwd)
	stdout := os.stream_from_handle(os.stdout)
	fmt.wprintf(stdout, "\r{}{}", colorize(pwd_short_stem, rgb(24, 152, 129)), RESET)

	current_git_branch, is_git_init := git.branch()
	if is_git_init {
		fmt.wprintf(stdout, " on {}{}{}", MAGENTA, GIT, current_git_branch)
	}

	#partial switch status {
	case .Ok:
		fmt.wprintf(stdout, "\n\r{} ", GREEN + ARROW_RIGHT + RESET)
	case .Error:
		fmt.wprintf(stdout, "\n\r{} ", RED + ARROW_RIGHT + RESET)
	case .Usage:
		fmt.wprintf(stdout, "\n\r{} ", YELLOW + ARROW_RIGHT + RESET)
	}
}

read_prompt :: proc(status: StatusCode, allocator := context.temp_allocator) -> (args: []string) {
	print_prompt(status)

	// termios.set()
	// defer termios.restore()

	@(static)
	buf: [512]byte
	len := 0
	bits: int
	err: os.Errno

	fmt.fprint(os.stdout, SAVE_CURSOR)
	loop: for {
		bits, err = os.read(os.stdin, buf[len:len + 1])
		if err != os.ERROR_NONE {
			log.error(os.get_last_error_string())
			os.exit(1)
		}
		if bits < 1 do continue loop
		clear_input()

		log.debug(buf[:len])

		switch buf[len] {
		case 0xC:
			clear_term()
			os.write(os.stdout, buf[:len])
		case 0xD:
			os.write(os.stdout, buf[:len])
			os.write(os.stdout, {'\r', '\n'})
			break loop
		case 0x7F:
			len = max(0, len - 1)
			os.write(os.stdout, buf[:len])
		case:
			len = min(511, len + 1)
			os.write(os.stdout, buf[:len])
		}
	}

	args = strings.fields(cast(string)buf[:len], allocator)

	return
}
