{
  inputs ? assert false; "must be called with either 'inputs' or all of [ 'lib' 'nix-alacarte' ]",

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
