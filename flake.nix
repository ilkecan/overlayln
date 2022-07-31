{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nix-utils = {
      url = "github:ilkecan/nix-utils";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
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

      inherit (inputs.nix-utils.lib.letterCase)
        kebabToCamel
      ;

      mkOverlay = drvFuncFile:
        (final: _prev: {
          ${removeSuffix ".nix" (kebabToCamel (baseNameOf drvFuncFile))} =
              final.callPackage drvFuncFile { inherit inputs; };
        });
    in
    {
      overlays = rec {
        default = overlayln;
        linkup = mkOverlay ./nix/linkup.nix;
        overlayln = mkOverlay ./nix/overlayln.nix;
        wrapPackage = mkOverlay ./nix/wrap-package.nix;
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
          wrapPackage = mkPackage ./nix/wrap-package.nix;
        };
      }
    );
}
