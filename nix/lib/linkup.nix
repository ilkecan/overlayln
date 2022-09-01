{
  inputs,
  system,

  lib,
  pkgs,

  overlayln ? inputs.self.packages.${system}.overlayln,
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
