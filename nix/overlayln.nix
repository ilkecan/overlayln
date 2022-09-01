{
  inputs,
  system,
  alacarte ? inputs.nix-alacarte.libs.${system},
  callPackage ? inputs.nixpkgs.legacyPackages.${system}.callPackage,
  crate2nix ? inputs.crate2nix,
  lib ? inputs.nixpkgs.lib,
  nix-filter ? inputs.nix-filter.lib,
}:

let
  inherit (nix-filter)
    inDirectory
  ;

  inherit (alacarte)
    sourceOf
  ;

  root = inputs.self;
  cargoToml = lib.importTOML "${root}/Cargo.toml";
  inherit (cargoToml.package) name;

  crateTools = callPackage "${sourceOf crate2nix}/tools.nix" { };
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
