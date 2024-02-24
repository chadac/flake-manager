{ inputs, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    concatStringSep
    foldAttrs
    getAttrs
    mapAttrs
    mkMerge
    mkOption
    mkEnableOption
    types
  ;
  importBasic = name: url: ''${name}.url = "${url}";'';
  importPassthru = passthru: name: url: let
    passthruFmt = builtins.concatStringsSep "  \n"
      (map (p: ''inputs.${p}.follows = "${p}";'') passthru);
  in ''
    inputs.${name} = {
      url = "${url}";
      ${passthruFmt}
    };
  '';
in {
  _file = __curPos.file;

  _module.args.flake-modules-lib = {
    # from: https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
    # useful for defining top-level options that export both perSystem and flake-level attrs
    mkMergeTopLevel = names: attrs: passthru: getAttrs names (
      mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
    );

    tryImportFlake = name: url: passthru: let
      fn = if (builtins.length passthru) <= 0 then importBasic else importPassthru passthru;
      example = fn name url;
    in
      builtins.seq
        (inputs.${name} or (throw "input '${name}' not found. add the following to your `flake.nix`:\n\n${example}\n"))
        inputs.${name};
  };
}
