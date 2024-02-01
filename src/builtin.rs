use nix::unistd::chdir;
use std::{env, error::Error, path::Path};

static BUILTIN_STR: &[&str] = &["cd", "help", "exit"];

/// [C]hange [D]irectory
pub fn cd(args: Vec<String>) -> Result<bool, Box<dyn Error>> {
    let home = env::var("HOME")?;
    let root = if !args.get(1).is_some() {
        Path::new(&home)
    } else {
        Path::new(&args[1])
    };

    println!("Changing directory to: {root:?}");
    if !chdir(root).is_ok() {
        return Ok(false);
    }

    Ok(true)
}

/// Display information about built-in commands
pub fn help(_args: Vec<String>) -> Result<bool, Box<dyn Error>> {
    println!("Dan Castrillos's WISH");
    println!("Type program names and arguments, and hit enter.");
    println!("The following are built in:");

    for str in BUILTIN_STR {
        println!("  {str:}\n");
    }

    println!("Use the man command for information on other programs.");

    return Ok(true);
}

/// Exit the shell
pub fn exit(_args: Vec<String>) -> Result<bool, Box<dyn Error>> {
    return Ok(false);
}
