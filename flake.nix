{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nix-utils = {
      url = "github:ilkecan/nix-utils";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (builtins)
        baseNameOf
      ;

      inherit (inputs.nixpkgs.lib)
        removeSuffix
      ;

      mkOverlay = drvFuncFile:
        (final: _prev: {
          ${removeSuffix ".nix" (baseNameOf drvFuncFile)} =
              final.callPackage drvFuncFile { inherit inputs; };
        });
    in
    {
      overlays = rec {
        default = overlayln;
        overlayln = mkOverlay ./nix/overlayln.nix;
        linkup = mkOverlay ./nix/linkup.nix;
      };
    } // inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        inherit (pkgs) callPackage;

        mkPackage = drvFuncFile:
          callPackage drvFuncFile { inherit inputs; };
      in
      {
        packages = rec {
          overlayln = mkPackage ./nix/overlayln.nix;
          default = overlayln;
        };

        lib = {
          linkup = mkPackage ./nix/linkup.nix;
        };
      }
    );
}
