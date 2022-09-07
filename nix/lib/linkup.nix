let
  missingDependantOf =
    import ./../../submodules/missing-dependant-of.nix/default.nix {
      inputs = [
        "lib"
        "overlayln"
        "pkgs"
      ];

      system = [
        "overlayln"
        "pkgs"
      ];
    };
in

{
  inputs ? missingDependantOf.inputs,
  system ? missingDependantOf.system,

  lib ? inputs.nixpkgs.lib,
  overlayln ? inputs.self.packages.${system}.overlayln,

  pkgs ? inputs.nixpkgs.legacyPackages.${system},
  runCommandLocal ? pkgs.runCommandLocal,
  ...
}:

let
  inherit (lib)
    getExe
  ;
in

{
  name,
  paths,
  ...
}@args:
let
  env = args // {
    passAsFile = [ "paths" ];
  };
in
runCommandLocal name env ''
  ${getExe overlayln} --target-directory $out $(cat $pathsPath)
''
