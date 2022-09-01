{
  inputs,

  lib,
  nix-alacarte,
  nix-filter,
  pkgs,

  crate2nix ? inputs.crate2nix,
  defaultCrateOverrides ? pkgs.defaultCrateOverrides,
  ...
}:

let
  inherit (lib)
    importTOML
  ;

  inherit (nix-alacarte)
    sourceOf
  ;

  inherit (nix-filter)
    inDirectory
  ;

  root = inputs.self;
  cargoToml = importTOML "${root}/Cargo.toml";
  inherit (cargoToml.package) name;

  crateTools = import "${sourceOf crate2nix}/tools.nix" { inherit pkgs; };
  cargoNix = import (crateTools.generatedCargoNix {
    inherit name;
    src = nix-filter {
      inherit name root;
      include = [
        "Cargo.lock"
        "Cargo.toml"
        (inDirectory "src")
      ];
    };
  }) { inherit pkgs defaultCrateOverrides; };
in

cargoNix.rootCrate.build
