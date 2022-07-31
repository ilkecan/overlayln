{
  inputs,
  lib,
  overlayln ? inputs.self.outputs.packages.${system}.overlayln,
  runCommandLocal,
  system,
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
