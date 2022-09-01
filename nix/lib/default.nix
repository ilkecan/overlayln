{
  inputs,
  system,

  lib ? inputs.nixpkgs.lib,
  nix-alacarte ? inputs.nix-alacarte.libs.${system},
  nix-filter ? inputs.nix-filter.lib,
  pkgs ? inputs.nixpkgs.legacyPackages.${system},
  ...
}@args:

let
  inherit (nix-alacarte)
    importDirectory
  ;

  args' = args // {
    inherit
      lib
      nix-alacarte
      nix-filter
      pkgs
    ;
  };
in

importDirectory ./. args' { }
