package wish

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

RED :: "\x1b[31m"
GREEN :: "\x1b[32m"
BLUE :: "\x1b[34m"
YELLOW :: "\x1b[33m"

RESET :: "\x1b[0m"

SUCCESS :: GREEN + CHECK + RESET
ERROR :: RED + XCROSS + RESET
WARNING :: YELLOW + ALERT + RESET

Color :: [3]byte
colorize :: proc(str: string, color: Color) -> string {
	color := fmt.tprintf("\x1B[38;2;%d;%d;%dm", color.r, color.g, color.b)
	return strings.concatenate({color, str, RESET})
}

print_prompt :: proc(status: StatusCode) {
	pwd := os.get_current_directory()
	defer delete(pwd)
	pwd_short_stem := filepath.short_stem(pwd)
	stdout := os.stream_from_handle(os.stdout)

	#partial switch status {
	case .Ok:
		fmt.wprintf(stdout, "{}{}\n{} ", BLUE, pwd_short_stem, GREEN + ARROW_RIGHT + RESET)
	case .Error:
		fmt.wprintf(stdout, "{}{}\n{} ", BLUE, pwd_short_stem, RED + CHEVRON_RIGHT + RESET)
	case .Usage:
		fmt.wprintf(stdout, "{}{}\n{} ", BLUE, pwd_short_stem, YELLOW + CHEVRON_RIGHT + RESET)
	}
}
