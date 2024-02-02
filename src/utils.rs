use std::{
    env,
    error::Error,
    ffi::{CString, OsString},
    io,
    os::unix::ffi::OsStringExt,
};

use nix::unistd::execve;

use crate::status::StatusCode;

pub fn read_line() -> Result<String, Box<dyn Error>> {
    let mut buffer = String::new();
    io::stdin().read_line(&mut buffer)?;

    Ok(buffer)
}

pub fn split_line(line: String) -> Vec<String> {
    line.split_whitespace().map(|s| s.to_string()).collect()
}

pub fn os_string_to_c_string(s: OsString) -> CString {
    let mut v = s.into_vec();
    v.push(0);
    CString::from_vec_with_nul(v).unwrap()
}

pub fn get_env() -> Vec<CString> {
    env::vars_os()
        .map(|(key, val)| {
            [key, OsString::from("="), val]
                .into_iter()
                .collect::<OsString>()
        })
        .map(os_string_to_c_string)
        .collect()
}

pub fn args_to_c_string(args: Vec<String>) -> Vec<CString> {
    args.into_iter()
        .map(|str| os_string_to_c_string(str.into()))
        .collect()
}

pub fn exec(path: String, args: Vec<String>) -> StatusCode {
    match execve(
        &os_string_to_c_string(path.into()),
        &args_to_c_string(args),
        &get_env(),
    ) {
        Ok(_) => StatusCode::Ok,
        Err(_) => StatusCode::Error,
    }
}
