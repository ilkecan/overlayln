use clap::{
  Parser,
  ValueHint,
  AppSettings,
};
use std::path::PathBuf;

#[derive(
  Parser,
)]
#[clap(
  version,
  author,
  about,
  arg_required_else_help = true,
  global_setting = AppSettings::DeriveDisplayOrder,
)]
pub struct Args {
  #[clap(
    long,
    short,
    value_hint = ValueHint::DirPath,
    value_name = "DIRECTORY",
  )]
  pub target_directory: PathBuf,

  #[clap(
    min_values(1),
    required(true),
    value_hint = ValueHint::DirPath,
  )]
  pub directories: Vec<PathBuf>,
}
