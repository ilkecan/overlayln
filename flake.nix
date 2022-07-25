{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (inputs.flake-utils.lib) eachDefaultSystem;
    in
    eachDefaultSystem (system:
      let
        inherit (builtins)
          baseNameOf
        ;

        inherit (inputs.nixpkgs.lib)
          removeSuffix
          callPackageWith
        ;

        pkgs = inputs.nixpkgs.legacyPackages.${system};
        inherit (pkgs) callPackage;

        derivationFunctions = {
          overlayln = {
            file = ./nix/overlayln.nix;

            args = {
              inherit self;
            };

            autoArgs = {
              inherit (inputs) crate2nix;
              nix-filter = inputs.nix-filter.lib;
            };
          };
        };

        mkOverlay = drvFunc:
          (final: prev:
            let
              pkgs = drvFunc.autoArgs // final;
              callPackage = callPackageWith pkgs;
            in
            {
              ${removeSuffix ".nix" (baseNameOf drvFunc.file)} =
                callPackage drvFunc.file drvFunc.args;
            }
          );

        mkPackage = drvFunc:
          callPackage drvFunc.file (drvFunc.autoArgs // drvFunc.args);
      in
      {
        overlays = rec {
          overlayln = mkOverlay derivationFunctions.overlayln;
          default = overlayln;
        };

        packages = rec {
          overlayln = mkPackage derivationFunctions.overlayln;
          default = overlayln;
        };
      }
    );
}
