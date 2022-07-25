{
  callPackage,
  crate2nix,
  lib,
  nix-filter,
  self,
}:

let
  inherit (nix-filter) inDirectory;

  root = self;
  cargoToml = lib.importTOML "${root}/Cargo.toml";
  inherit (cargoToml.package) name;

  crateTools = callPackage "${crate2nix}/tools.nix" { };
  buildRustCrateForPkgs = pkgs: with pkgs; buildRustCrate;
  cargoNix = callPackage (crateTools.generatedCargoNix {
    inherit name;
    src = nix-filter {
      inherit name root;
      include = [
        "Cargo.lock"
        "Cargo.toml"
        (inDirectory "src")
      ];
    };
  }) { inherit buildRustCrateForPkgs; };
in

cargoNix.rootCrate.build
