{
  inputs,
  system,
  lib ? inputs.nixpkgs.lib,
  linkup ? inputs.self.outputs.libs.${system}.linkup,
  nix-utils ? inputs.nix-utils.libs.${system},
}:

let
  inherit (builtins)
    listToAttrs
  ;

  inherit (lib)
    forEach
    getBin
    getName
    getValues
    optionalAttrs
  ;

  inherit (nix-utils)
    optionalValue
    wrapExecutable
  ;

  wrapPackage = pkg:
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

      pkgIsBinDrv = pkg == drv;
      wrappedDrv =
        let
          drv = if pkgIsBinDrv then pkg else drv;
        in
        drv // (removeAttrs linkedUp [
          "all"
          "out"
          "outputName"
          "outputs"
        ]) // {
          inherit (drv) passthru;
          meta =
            linkedUp.meta
            // (drv.meta or { })
            // { inherit (linkedUp.meta) position; }
          ;
          ${drv.outputName or null} = wrappedDrv;
        }
      ;

      commonAttrs =
        (removeAttrs (if pkgIsBinDrv then wrappedDrv else pkg) [
          "override"
          "overrideDerivation"
        ])
        // listToAttrs outputList
        // (optionalAttrs (drv ? outputs) { inherit all outputs; })
      ;
      outputs = drv.outputs or [ ];
      all = getValues outputList;
      outputList = forEach outputs (outputName: {
        name = outputName;
        value = commonAttrs // {
          inherit (wrappedDrv.${outputName})
            drvPath
            outPath
            outputName
            passthru
            type
          ;
          outputSpecified = true;
        };
      });
    in
    commonAttrs // {
      ${optionalValue (pkg ? override) "override"} =
        args': wrapPackage (pkg.override args') args;
      ${optionalValue (pkg ? overrideDerivation) "overrideDerivation"} =
        f: wrapPackage (pkg.overrideDerivation f) args;
    };
in
wrapPackage
