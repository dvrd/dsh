package wish

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import libc "system:c"
}

import "base:runtime"
import "core:c"
import "core:os"
import "core:strings"

Pid :: distinct i32
pid_t :: i32

/// Termination signal
/// Only retrieve the code if WIFSIGNALED(s) = true
WTERMSIG :: #force_inline proc "contextless" (s: u32) -> u32 {
	return s & 0x7f
}

/// Check if the process signaled
WIFSIGNALED :: #force_inline proc "contextless" (s: u32) -> bool {
	return cast(i8)(((s) & 0x7f) + 1) >> 1 > 0
}

/// Check if the process terminated normally (via exit.2)
WIFEXITED :: #force_inline proc "contextless" (s: u32) -> bool {
	return WTERMSIG(s) == 0
}

Wait_Option :: enum {
	WNOHANG     = 0,
	WUNTRACED   = 1,
	WSTOPPED    = 1,
	WEXITED     = 2,
	WCONTINUED  = 3,
	WNOWAIT     = 24,
	// // For processes created using clone
	__WNOTHREAD = 29,
	__WALL      = 30,
	__WCLONE    = 31,
}

Wait_Options :: bit_set[Wait_Option;u32]

@(default_calling_convention = "c")
foreign libc {
	@(link_name = "execve")
	_unix_execve :: proc(path: cstring, argv: [^]cstring, envp: [^]cstring) -> int ---
	@(link_name = "fork")
	_unix_fork :: proc() -> pid_t ---
	@(link_name = "waitpid")
	_unix_waitpid :: proc(pid: pid_t, stat_loc: ^c.uint, options: c.uint) -> pid_t ---
}

fork :: proc() -> (Pid, os.Errno) {
	pid := _unix_fork()
	if pid == -1 {
		return Pid(-1), os.Errno(os.get_last_error())
	}
	return Pid(pid), os.ERROR_NONE
}

exec :: proc(path: string, args: []string) -> os.Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	args_cstrs := make([]cstring, len(args) + 2, context.temp_allocator)
	args_cstrs[0] = strings.clone_to_cstring(path, context.temp_allocator)
	for i := 0; i < len(args); i += 1 {
		args_cstrs[i + 1] = strings.clone_to_cstring(args[i], context.temp_allocator)
	}

	_unix_execve(path_cstr, raw_data(args_cstrs), {})
	return os.Errno(os.get_last_error())
}

waitpid :: proc "contextless" (pid: Pid, status: ^u32, options: Wait_Options) -> (Pid, os.Errno) {
	ret := _unix_waitpid(cast(i32)pid, status, transmute(u32)options)
	return Pid(ret), os.Errno(os.get_last_error())
}

