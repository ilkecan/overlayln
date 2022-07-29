use std::ffi::OsString;
use std::fs;
use std::mem;
use std::collections::HashMap;
use std::path::PathBuf;

type Name = OsString;

pub trait Takeable {
  fn take(&mut self) -> Self;
}

impl<T> Takeable for T
where
  T: Default,
{
  fn take(&mut self) -> Self {
    mem::take(self)
  }
}

#[derive(
  Debug,
)]
pub enum File {
  Directory(Directory),
  SymLink(SymLink),
}

impl File {
  pub fn symlink(target: PathBuf) -> Self {
    Self::SymLink(SymLink::new(target))
  }

  pub fn directory(path: PathBuf) -> Self {
    Self::Directory(Directory::new(path))
  }

  pub fn overlay(&mut self, path: PathBuf) {
    if let File::SymLink(symlink) = self {
      if !symlink.is_dir() {
        *self = File::symlink(path);
        return
      }

      *self = File::directory(symlink.target.take());
    }

    if let File::Directory(directory) = self {
      if path.is_dir() {
        for entry in fs::read_dir(path).unwrap() {
          directory.add(entry.unwrap().path());
        }
      } else {
        directory.add(path);
      }

      if let Some(file) = directory.fold() {
        *self = file;
      }
    }
  }
}

impl Default for File {
  fn default() -> Self {
    File::symlink(PathBuf::default())
  }
}

#[derive(
  Debug,
)]
pub struct Directory {
  contents: DirContents,
}

impl Directory {
  pub fn new(path: PathBuf) -> Self {
    let contents = DirContents::new(path);

    Self {
      contents,
    }
  }

  pub fn add(&mut self, path: PathBuf) {
    let name = path.file_name().unwrap().to_os_string();

    match self.contents.get(&name) {
      None => {
        self.contents.add(path);
      },
      Some(file) => {
        file.overlay(path);
      },
    }
  }

  pub fn contents(self) -> HashMap<Name, File> {
    self.contents.0
  }

  pub fn fold(&mut self) -> Option<File> {
    let mut entries = self.contents.0.values_mut();
    let first = entries.next().unwrap();
    if entries.next().is_none() && matches!(first, File::SymLink(_)) {
      Some(first.take())
    } else {
      None
    }
  }
}

#[derive(
  Debug,
)]
struct DirContents(HashMap<Name, File>);

impl DirContents {
  pub fn empty() -> Self {
    let contents = HashMap::new();

    Self(contents)
  }

  pub fn new(path: PathBuf) -> Self {
    let mut contents = Self::empty();
    for entry in fs::read_dir(path).unwrap() {
      let entry = entry.unwrap();
      contents.add(entry.path());
    }

    contents
  }

  pub fn add(&mut self, path: PathBuf) {
    let name = path.file_name().unwrap().to_os_string();

    self.0.insert(name, File::symlink(path));
  }

  pub fn get(&mut self, name: &Name) -> Option<&mut File> {
    self.0.get_mut(name)
  }
}

#[derive(
  Debug,
)]
pub struct SymLink {
  pub target: PathBuf,
  r#type: Type,
}

impl SymLink {
  pub fn new(target: PathBuf) -> Self {
    let r#type = if target.is_dir() {
      Type::Dir
    } else {
      Type::File
    };

    Self {
      target,
      r#type,
    }
  }

  pub fn is_dir(&self) -> bool {
    self.r#type == Type::Dir
  }
}

#[derive(
  Debug,
  PartialEq,
)]
enum Type {
  Dir,
  File,
}
