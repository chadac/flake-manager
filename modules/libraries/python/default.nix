{ inputs, config, lib, flake-parts-lib, flake-manager-lib, ... }:
let
  inherit (lib)
    concatMapAttrs
    listToAttrs
    mapAttrs
    mapAttrs'
    mkEnableOption
    mkMerge
  ;
  inherit (flake-parts-lib)
    mkOption
    mkPerSystemOption
    types
  ;
  inherit (flake-manager-lib)
    evalBuilder
    mkBuilderOption
    mkDerivationOptions
  ;
  cfg = config.python;
  pythonOptions = { config, ... }: {
    options = {
    };
  };
  pythonPackageType = mkBuilderOption [
    mkDerivationOptions
    pythonOptions
  ];

  pythonBuilder = { cmd, module }: pkgs: python3: pythonPackages: let
    args = evalBuilder module;
  in pythonPackages.${cmd} args;
in {
  _file = __curPos.file;

  options.libraries.python = mkOption {
    type = types.lazyAttrsOf pythonPackageType;
    default = { };
  };

  config = {
    flake.builders.python = mapAttrs
      (name: derivModule: pythonBuilder {
        cmd = "buildPythonPackage";
        args = derivModule;
      })
      config.libraries.python;

    perSystem = { pkgs, ... }: let
      defaultPython = pkgs."python${cfg.pythonVersion}";
      additionalPythons = listToAttrs (map
        (v: { name = "python${v}"; value = pkgs."python${v}"; })
        cfg.additionalVersions
      );
      allBuilders = config.builders.python-packages // config.builders.python-apps;
      packages = (mapAttrs
        (_: builder: builder pkgs defaultPython defaultPython.pkgs)
        allBuilders
      ) // (concatMapAttrs
        (pyVer: python3: mapAttrs'
          (name: builder: { name = "${pyVer}/${name}"; value = builder pkgs python3 python3.pkgs; })
          allBuilders)
        additionalPythons
      );
    in lib.mkIf cfg.enable packages;
  };
}
