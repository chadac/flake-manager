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
    (_: pkg: pkg.enable)
    config.self.registries.python
  ;

  # an overlay that provides all Python libraries as an overlay.
  mkPythonOverlay = pyVer: final: prev: let
    prevPython = prev.${pyVer};
    packageOverrides = builtins.trace cfg (self: super: mapAttrs
      (_: pkg: pkg.recipe prev prevPython super)
      cfg
    );
  in {
    "${pyVer}" = prevPython.override {
      inherit packageOverrides;
    };
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
    flake.registries.python = mkOption {
      type = types.lazyAttrsOf recipeTypes.python;
      default = { };
    };

    self.registries.python = mkOption {
      type = types.lazyAttrsOf pythonRegistryType;
      default = { };
    };
  };

  config = {
    self.registries.python = concatMapAttrs
      (name: input: mapAttrs
        (_: recipe: { inherit recipe; })
        (input.registries.python or { }))
      (filterAttrs (name: _: name != "self") inputs)
    ;

    self.registries.nixpkgs = mkMerge
      (map
        (pyVer: {
          "${pyVer}-package-overrides" = mkPythonOverlay pyVer;
        })
        pythonVersions);
  };
}
