# overlayln
Creates the directory structure of the union of the given directories using
minimal number of symbolic links. Directories that come later have higher
precedence over the ones that come before in case of a path collision.

## example
``` bash
❯ tree a
a
├── 0
├── 1
├── 2
├── 3
├── 4
└── inner
    ├── 5
    ├── 6
    ├── 7
    ├── 8
    └── 9

1 directory, 10 files

❯ tree b
b
└── 4

❯ overlayln -t c a b
❯ tree c
c
├── 0 -> a/0
├── 1 -> a/1
├── 2 -> a/2
├── 3 -> a/3
├── 4 -> b/4
└── inner -> a/inner
```

The flake also provides two Nix functions:
## linkup
A function on top of `overlayln` whose parameters are similar to
`symlinkJoin`'s.

### example
``` nix
linkup {
  name = "rofi";
  paths = with pkgs; [
    rofi
    (hiPrio (writeShellScriptBin "rofi" ''
      exec ${lib.getExe rofi} -i "$@"
    ''))
  ];
}
```

## wrapPackage
A function on top of `linkup` and `makeWrapper` to wrap an executable of the
given package.

### example
``` nix
wrapPackage pkgs.rofi {
  addFlags = [ "-i" ];
}
```
