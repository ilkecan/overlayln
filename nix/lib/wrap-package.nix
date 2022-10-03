{
  inputs ? { },
  system ? "",

  lib ? inputs.nixpkgs.lib,
  linkup ? inputs.self.libs.${system}.linkup,
  nix-alacarte ? inputs.nix-alacarte.libs.${system},
  ...
}:

let
  inherit (lib)
    getBin
    getName
    getValues
    pipe
  ;

  inherit (nix-alacarte)
    attrs
    list
    optionalValue
    pair
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
      args' = pipe args [
        (attrs.remove [
          "exePath"
        ])
        (attrs.merge' {
          name = exeName;
          outPath = exePath;
        })
      ];

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
        drv
        // attrs.remove [
          "all"
          "out"
          "outputName"
          "outputs"
        ] linkedUp
        // {
          inherit (drv) passthru;
          meta =
            linkedUp.meta
            // (drv.meta or { })
            // { inherit (linkedUp.meta) position; }
          ;
          ${drv.outputName or null} = wrappedDrv;
        };

      commonAttrs =
        (attrs.remove
          [ "override" "overrideDerivation" ]
          (if pkgIsBinDrv then wrappedDrv else pkg))
        // list.toAttrs outputList
        // (attrs.optional (drv ? outputs) { inherit all outputs; });
      outputs = drv.outputs or [ ];
      all = getValues outputList;
      outputList = list.forEach outputs (outputName:
        let
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
        in
        pair outputName value
      );
    in
    commonAttrs // {
      ${optionalValue (pkg ? override) "override"} =
        args': wrapPackage (pkg.override args') args;
      ${optionalValue (pkg ? overrideDerivation) "overrideDerivation"} =
        f: wrapPackage (pkg.overrideDerivation f) args;
    };
in
wrapPackage
