{ inputs, lib, flake-parts-lib, python-libraries, ... }: let
  inherit (lib)
    concatMap
    concatMapAttrs
    mapAttrs
    mapAttrs'
    mkOption
    types
  ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
  ;
  registryPackageBuilderType = types.functionTo (types.functionTo types.package);
  registryType = types.lazyAttrsOf registryPackageBuilderType;
in {
  options = {
    flake = mkSubmoduleOptions {
      registries = mkOption {
        type = types.submodule {
          options = {
            python = mkOption {
              type = registryType;
              description = "an attribute list of python packages to export";
              default = { };
            };
          };
        };
        default = { };
      };
    };
  };
  config = {
    _module.args.python-libraries = concatMapAttrs
      (name: input:
        if name == "self" then { }
        else input.registries.python or { }
      )
      inputs
    ;
    _module.args.flake-modules-lib = {
      overridePython =
        {
          pkgs,
          pyName ? "python3",
          extraOverrides ? [ ],
        }:
        pkgs.override(final: prev: let
          packageOverrides = self: super: mapAttrs'
            (_: builder: builder final self)
            (python-libraries ++ extraOverrides);
          newPython = pkgs.${pyName}.override {
            inherit packageOverrides;
            self = newPython;
          };
        in {
          ${pyName} = newPython;
        });
    };
  };
}
