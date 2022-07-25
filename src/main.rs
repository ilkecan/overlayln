mod cli;
mod overlayln;
mod file;

use clap::Parser;
use std::ffi::OsString;
use once_cell::sync::Lazy;

use crate::cli::Args;
use crate::overlayln::OverlayLn;

static ARGV: Lazy<Vec<OsString>> = Lazy::new(|| wild::args_os().collect());

fn argv() -> &'static [OsString] {
  &ARGV
}

#[quit::main]
fn main() {
  let args = Args::try_parse_from(argv()).unwrap_or_else(|error| {
    error.print().expect("Could not print the error due to another error.");
    quit::with_code(exitcode::USAGE);
  });


  let overlayln = OverlayLn::new(args);
  overlayln.execute();
}
