{ inputs, lib, config, flake-manager-lib, ... }: let
  inherit (lib)
    concatMap
    concatMapAttrs
    filterAttrs
    listToAttrs
    mapAttrs
    mapAttrs'
    mkOption
    mkMerge
    types
  ;
  inherit (flake-manager-lib)
    recipeTypes
  ;

  cfg = filterAttrs
    (pkg: pkg.enable)
    config.self.registries.python
  ;

  # an overlay that provides all Python libraries as an overlay.
  mkPythonOverlay = pyVer: final: prev: let
    finalPython = final.${pyVer};
    packageOverrides = self: super: mapAttrs
      (_: pybuilder: pybuilder final finalPython self)
      cfg
    ;
    pyNew = finalPython.override {
      inherit packageOverrides;
      self = pyNew;
    };
  in {
    "${pyVer}" = pyNew;
  };

  pythonVersions = map
    (v: "python${v}")
    [ "2" "38" "39" "310" "311" "312" "313" ]
  ;

  pythonRegistryType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If true, enables the given registry.";
      };
      recipe = mkOption {
        type = recipeTypes.python;
        description = "The Python recipe to apply.";
      };
    };
  };
in {
  options = {
    self.registries.python = mkOption {
      type = types.lazyAttrsOf pythonRegistryType;
      default = { };
    };
  };

  config = {
    self.registries.python = concatMapAttrs
      (name: input:
        if name == "self" then { }
        else input.registries.python or { })
      inputs
    ;

    self.registries.nixpkgs = mkMerge
      (map
        (pyVer: {
          "${pyVer}-packages" = mkPythonOverlay pyVer;
        })
        pythonVersions);
  };
}
