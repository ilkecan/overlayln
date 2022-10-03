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
      inherit (inputs.nixpkgs.lib)
        composeManyExtensions
      ;

      inherit (inputs.nix-alacarte.lib)
        attrs
        importDirectory
      ;
    in
    {
      overlays =
        let
          overlays = import ./nix/overlays { inherit inputs; };
        in
        overlays // {
        default = composeManyExtensions (attrs.values overlays);
      };
    } // inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        importDirectory' = path:
          importDirectory { } path { inherit inputs system; };
      in
      {
        packages = importDirectory' ./nix/pkgs // {
          default = self.packages.${system}.overlayln;
        };

        libs = importDirectory' ./nix/lib;
      }
    );
}
