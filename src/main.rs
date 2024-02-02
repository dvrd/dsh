pub mod builtin;
pub mod icons;
pub mod status;
pub mod utils;

use status::StatusCode;
use utils::read_line;
use utils::split_line;

use nix::{
    sys::wait::waitpid,
    unistd::{fork, ForkResult},
};
use std::{env, error::Error, fs, io::Write};

fn launch(args: Vec<String>) -> StatusCode {
    let paths = env::var("PATH");
    if paths.is_err() {
        return StatusCode::Error;
    }
    for dir in paths.unwrap().split(':') {
        let full_path = format!("{}/{}", dir, args[0]);
        if fs::metadata(&full_path).is_ok() {
            match unsafe { fork() } {
                Ok(ForkResult::Parent { child }) => {
                    if waitpid(child, None).is_err() {
                        println!("Error waiting process");
                        return StatusCode::Error;
                    }
                }
                Ok(ForkResult::Child) => {
                    return utils::exec(full_path, args);
                }
                Err(_) => {
                    println!("Error forking process");
                    return StatusCode::Error;
                }
            }
            return StatusCode::Ok;
        }
    }

    StatusCode::Error
}

fn execute(args: Vec<String>) -> StatusCode {
    if args.get(0).is_none() {
        return StatusCode::Usage;
    }

    match args[0].as_str() {
        "cd" => builtin::cd(args),
        "help" => builtin::help(args),
        "exit" => builtin::exit(args),
        _ => launch(args),
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let mut line: String;
    let mut args: Vec<String>;
    let mut status = StatusCode::Ok;
    let mut prompt: String;

    loop {
        prompt = match status {
            StatusCode::Ok => format!(" {} ", icons::PROMPT),
            StatusCode::Error => format!(" {} ", icons::ERROR),
            StatusCode::Usage => format!(" {} ", icons::WARNING),
        };
        print!("{prompt:} ");
        std::io::stdout().flush()?;
        line = read_line()?;
        args = split_line(line);
        status = execute(args);
    }
}
