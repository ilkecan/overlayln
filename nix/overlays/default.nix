{
  inputs ? { },

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

  overlays = pipe dirs [
    (map (nixFiles { }))
    mergeListOfAttrs
    (mapAttrs (_: mkOverlay { inherit inputs; }))
  ];
in
overlays
