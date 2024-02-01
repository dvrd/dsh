pub mod builtin;

use std::{error::Error, io, io::Write};

fn read_line() -> Result<String, Box<dyn Error>> {
    let mut buffer = String::new();
    io::stdin().read_line(&mut buffer)?;

    Ok(buffer)
}

fn split_line(line: String) -> Vec<String> {
    line.split_whitespace().map(|s| s.to_string()).collect()
}

fn launch(args: Vec<String>) -> Result<bool, Box<dyn Error>> {
    if !args.get(0).is_some() {
        panic!("No command given");
    }

    let mut child = std::process::Command::new(&args[0])
        .args(&args[1..])
        .spawn()?;

    child.wait()?;

    Ok(true)
}

fn execute(args: Vec<String>) -> Result<bool, Box<dyn Error>> {
    if args.get(0).is_none() {
        return Ok(false);
    }

    match args[0].as_str() {
        "cd" => builtin::cd(args),
        "help" => builtin::help(args),
        "exit" => builtin::exit(args),
        _ => launch(args),
    }
}

fn wish_loop() -> Result<(), Box<dyn Error>> {
    let mut line: String;
    let mut args: Vec<String>;
    let mut status: bool;

    while {
        print!("> ");
        std::io::stdout().flush()?;
        line = read_line()?;
        args = split_line(line);
        status = execute(args)?;

        status
    } {}

    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    // let mut args: Vec<String> = env::args().collect();

    wish_loop()?;

    Ok(())
}
