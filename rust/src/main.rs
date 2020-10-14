#![feature(vec_spare_capacity)]
#[allow(unused_macros)]
#[allow(unused_variables)]
#[allow(dead_code)]
#[allow(non_upper_case_globals)]
#[allow(non_snake_case)]

#[path="lex.yy.rs"]
mod lex;

use std::ffi::CString;
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    let mut scanner: lex::Scanner<()> = lex::Scanner::new();
    //let path = CString::new("../README.md")?;
    let path = CString::new("src/lex.yy.rs")?;
    let mode = CString::new("r")?;
    let file = unsafe { libc::fopen(path.as_ptr(), mode.as_ptr()) };
    scanner.yyin_r = if file.is_null() { None } else { Some(lex::FILE::new(file)) };
    let mut data = ();
    scanner.lex(&mut data)?;
    Ok(())
}
