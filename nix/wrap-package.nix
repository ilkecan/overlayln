{
  inputs,
  lib,
  linkup ? inputs.self.outputs.lib.${system}.linkup,
  nix-utils ? inputs.nix-utils.lib.${system},
  system,
}:

let
  inherit (lib)
    getBin
    getName
  ;

  inherit (nix-utils)
    wrapExecutable
  ;
in

pkg:
let
  drv = getBin pkg;
  pkgName = getName pkg;
  exeName = drv.meta.mainProgram or pkgName;
in
{
  exePath ? "bin/${exeName}",
  ...
}@args:
let
  args' = removeAttrs args [
    "exePath"
  ] // {
    name = exeName;
    outPath = exePath;
  };

  wrappedExe = wrapExecutable "${drv}/${exePath}" args';
  wrappedPkg = linkup {
    name = pkgName;
    paths = [ pkg wrappedExe ];
  };
in
if drv ? outputSpecified && drv.outputSpecified then
  pkg // { ${drv.outputName} = wrappedPkg; }
else
  wrappedPkg
