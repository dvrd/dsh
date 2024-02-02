use nix::{libc, unistd::chdir};
use std::{env, path::Path};

use crate::status::StatusCode;

static BUILTIN_STR: &[&str] = &["cd", "help", "exit"];

/// [C]hange [D]irectory
pub fn cd(args: Vec<String>) -> StatusCode {
    let home = match env::var("HOME") {
        Ok(val) => val,
        Err(_) => {
            return StatusCode::Error;
        }
    };

    let root = if !args.get(1).is_some() {
        Path::new(&home)
    } else {
        Path::new(&args[1])
    };

    if chdir(root).is_err() {
        return StatusCode::Error;
    }

    StatusCode::Ok
}

/// Display information about built-in commands
pub fn help(_args: Vec<String>) -> StatusCode {
    println!("Dan Castrillos's WISH");
    println!("Type program names and arguments, and hit enter.");
    println!("The following are built in:");

    for str in BUILTIN_STR {
        println!("  {str:}\n");
    }

    println!("Use the man command for information on other programs.");

    return StatusCode::Ok;
}

/// Exit the shell
pub fn exit(_args: Vec<String>) -> StatusCode {
    unsafe {
        libc::exit(0);
    }
}
