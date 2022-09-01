{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nix-alacarte = {
      url = "github:ilkecan/nix-alacarte";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        overlayln.follows = "";
      };
    };
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs:
    let
      inherit (builtins)
        attrValues
        mapAttrs
      ;

      inherit (inputs.nixpkgs.lib)
        composeManyExtensions
      ;

      inherit (inputs.nix-alacarte.lib)
        mkOverlay
      ;
    in
    {
      overlays =
        let
          overlays = mapAttrs (_: mkOverlay { inherit inputs; }) {
            linkup = ./nix/linkup.nix;
            overlayln = ./nix/overlayln.nix;
            wrapPackage = ./nix/wrap-package.nix;
          };
        in
        overlays // { default = composeManyExtensions (attrValues overlays); };
    } // inputs.flake-utils.lib.eachDefaultSystem (system:
      {
        packages = {
          default = self.packages.${system}.overlayln;
          overlayln = import ./nix/overlayln.nix { inherit inputs system; };
        };

        libs = {
          linkup = import ./nix/linkup.nix { inherit inputs system; };
          wrapPackage = import ./nix/wrap-package.nix { inherit inputs system; };
        };
      }
    );
}
