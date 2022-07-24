use std::path::PathBuf;
use std::collections::VecDeque;
use std::fs;

use crate::cli::Args;
use crate::file::{
  File,
  SymLink,
  Takeable,
};

pub struct Linkup {
  directories: Vec<PathBuf>,
  target: PathBuf,
}

impl Linkup {
  pub fn new(args: Args) -> Self {
    Self {
      directories: args.directories,
      target: args.target_directory,
    }
  }

  pub fn execute(mut self) {
    let target = self.calculate();
    self.create(target);
  }

  fn calculate(&mut self) -> File {
    let mut directories = self.directories.take().into_iter();
    let mut target = File::symlink(directories.next().unwrap());

    for dir in directories {
      target.overlay(dir);
    }

    println!("{:?}", target);

    target
  }

  fn create(&mut self, target: File) {
    let mut queue = VecDeque::new();
    queue.push_back((self.target.take(), target));

    while !queue.is_empty() {
      let (path, file) = queue.pop_front().unwrap();

      match file {
        File::Directory(directory) => {
          fs::create_dir(&path).unwrap();

          for (name, file) in directory.contents() {
            queue.push_back((path.join(name), file));
          }
        },

        File::SymLink(symlink) => {
          Self::symlink(symlink, path);
        },
      }
    }
  }

  #[cfg(target_family = "unix")]
  fn symlink(symlink: SymLink, path: PathBuf) {
    std::os::unix::fs::symlink(symlink.target, path).unwrap();
  }

  #[cfg(target_family = "windows")]
  fn symlink(symlink: SymLink, path: PathBuf) {
    use std::os::windows;

    if symlink.is_dir() {
      windows::fs::symlink_dir(symlink.target, path).unwrap();
    } else {
      windows::fs::symlink_file(symlink.target, path).unwrap();
    }
  }
}
