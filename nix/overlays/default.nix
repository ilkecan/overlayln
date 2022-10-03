{
  inputs ? { },

  lib ? inputs.nixpkgs.lib,
  nix-alacarte ? inputs.nix-alacarte.libs.default,
}:
let
  inherit (lib)
    pipe
  ;

  inherit (nix-alacarte)
    attrs
    list
    mkOverlay
    nixFiles
  ;

  dirs = [
    ../lib
    ../pkgs
  ];

  overlays = pipe dirs [
    (list.map (nixFiles { }))
    attrs.concat
    (attrs.map (_: mkOverlay { inherit inputs; }))
  ];
in
overlays
