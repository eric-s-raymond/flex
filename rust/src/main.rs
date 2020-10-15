#![feature(vec_spare_capacity)]
#[allow(unused_macros)]
#[allow(unused_variables)]
#[allow(dead_code)]
#[allow(non_upper_case_globals)]
#[allow(non_snake_case)]

#[path="lex.yy.rs"]
mod lex;

use std::cell::RefCell;
use std::env;
use std::error::Error;
use std::fs;
use std::rc::Rc;

fn main() -> Result<(), Box<dyn Error>> {
    let mut scanner: lex::Scanner<()> = lex::Scanner::new();
    if let Some(filename) = env::args().into_iter().nth(1) {
        let file = fs::OpenOptions::new()
            .read(true)
            .create(false)
            .open(filename)?;
        scanner.yyin_r = Some(Rc::new(RefCell::new(file)));
        scanner.set_interactive(false);
    }
    let mut data = ();
    scanner.lex(&mut data)?;
    Ok(())
}
