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
      ;

      inherit (inputs.nixpkgs.lib)
        composeManyExtensions
      ;
    in
    {
      overlays = import ./nix/overlays { inherit inputs; } // {
        default = composeManyExtensions (attrValues self.overlays);
      };
    } // inputs.flake-utils.lib.eachDefaultSystem (system:
      {
        packages = import ./nix/pkgs { inherit inputs system; } // {
          default = self.packages.${system}.overlayln;
        };

        libs = import ./nix/lib { inherit inputs system; };
      }
    );
}
