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

      inherit (inputs.nix-alacarte.lib)
        importDirectory
      ;
    in
    {
      overlays =
        let
          overlays = import ./nix/overlays { inherit inputs; };
        in
        overlays // {
        default = composeManyExtensions (attrValues overlays);
      };
    } // inputs.flake-utils.lib.eachDefaultSystem (system:
      {
        packages = importDirectory ./nix/pkgs { inherit inputs system; } { } // {
          default = self.packages.${system}.overlayln;
        };

        libs = importDirectory ./nix/lib { inherit inputs system; } { };
      }
    );
}
