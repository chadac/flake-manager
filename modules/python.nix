{ inputs, config, lib, flake-parts-lib, flake-parts-templates-lib, python-libraries, ... }:
let
  inherit (lib)
    concatMapAttrs
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
  inherit (flake-parts-templates-lib)
    mkDerivationOptions
  ;
  pythonOverride = overrides: pkgs: python: let
    packageOverrides = self: super: mapAttrs
      (name: builder: builder python self)
      python-libraries;
    newPython = python.override {
      inherit packageOverrides;
      self = newPython;
    };
  in newPython;

  pythonBuilderOptions = {
    format = mkOption {
      type = types.str;
    };
    pythonVersion = mkOption {
      type = types.str;
      default = cfg.package;
    };
  };
  pythonPackageType = types.submodule ({
  } // pythonBuilderOptions // mkDerivationOptions);
  pythonAppType = types.submodule ({
  } // pythonBuilderOptions // mkDerivationOptions);
  cfg = config.python;
in {
  options.python = {
    enable = true;
    package = mkOption {
      type = types.str;
      default = "python3";
    };
    packages = {
      type = types.lazyAttrsOf pythonPackageType;
      default = { };
    };
    apps = {
      type = types.lazyAttrsOf pythonAppType;
      default = { };
    };
  };
  config.perSystem = { pkgs, ... }: let
    python3 = pkgs.${cfg.package}.override (pythonOverride (python-libraries // overridePackages));
    packages = mapAttrs (_: args: python3.mkPythonPackage args) cfg.packages;
    apps = mapAttrs (_: args: python3.mkPythonApplication args) cfg.apps;
    overridePackages = mapAttrs (_: pkg: { name = pkg.pname; value = pkg; }) packages;
  in lib.mkIf cfg.enable (
    mkMerge (mapAttrs (name: pkg: { packages.${name} = pkg; }) (apps // packages))
  );

  config.flake.registries.python = mapAttrs
    (name: args: let
      pname = args.pname or (throw "flake-modules: could not infer Python package name for '${name}'. Ensure you include a `pname` parameter.");
    in {
      ${pname} = (_: pyPkgs: pyPkgs.buildPythonPackage args);
    })
    cfg.packages
  ;
}
