{
  inputs,
  lib,
  linkup ? inputs.self.outputs.lib.${system}.linkup,
  nix-utils ? inputs.nix-utils.lib.${system},
  system,
}:

let
  inherit (builtins)
    listToAttrs
  ;

  inherit (lib)
    forEach
    getBin
    getName
    optional
  ;

  inherit (nix-utils)
    optionalValue
    wrapExecutable
  ;
in

pkg:
let
  drv = getBin pkg;
  exeName = drv.meta.mainProgram or (getName drv);
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
  linkedUp = linkup {
    inherit (pkg) name;
    paths = [ drv wrappedExe ];
  };

  outputName = drv.outputName or null;
  wrappedDrv = removeAttrs (drv // linkedUp // {
    ${optionalValue (outputName != null) "outputName"} = outputName;
    meta = linkedUp.meta // (drv.meta or { }) // { inherit (linkedUp.meta) position; };
    passthru = linkedUp.passthru // (drv.passthru or { });
  }) (
    optional (!pkg ? outputSpecified) "outputSpecified"
  );

  drv' = drv // { ${outputName} = wrappedDrv; };
  pkg' = if outputName == pkg.outputName or null then wrappedDrv else pkg;

  all = map (x: x.value) outputList;
  wrappedPkg = pkg' // listToAttrs outputList // { inherit all outputs; };
  outputs = drv.outputs or [ ];
  outputList = forEach outputs (outputName: {
    name = outputName;
    value = wrappedPkg // {
      inherit outputName;
      inherit (drv'.${outputName})
        drvPath
        outPath
        passthru
        type
      ;
      outputSpecified = true;
    };
  });
in
wrappedPkg
