let
  missingDependantOf =
    import ./../../submodules/missing-dependant-of.nix/default.nix {
      inputs = [
        "lib"
        "nix-alacarte"
      ];
    };
in

{
  inputs ? missingDependantOf.inputs,

  lib ? inputs.nixpkgs.lib,
  nix-alacarte ? inputs.nix-alacarte.libs.default,
}:
let
  inherit (builtins)
    mapAttrs
  ;

  inherit (lib)
    pipe
  ;

  inherit (nix-alacarte)
    mergeListOfAttrs
    mkOverlay
    nixFiles
  ;

  dirs = [
    ../lib
    ../pkgs
  ];

  getNixFiles = dir:
    nixFiles dir { };

  overlays = pipe dirs [
    (map getNixFiles)
    mergeListOfAttrs
    (mapAttrs (_: mkOverlay { inherit inputs; }))
  ];
in
overlays
