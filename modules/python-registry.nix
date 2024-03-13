{ inputs, lib, config, ... }: let
  inherit (lib)
    concatMap
    concatMapAttrs
    listToAttrs
    mapAttrs
    mapAttrs'
    mkOption
    types
  ;

  # an overlay that provides all Python libraries as an overlay.
  python-registry-overlay = final: prev: let
    pyVers = map (v: "python${v}") ["38" "39" "310" "311" "312" "313"];
    pythonVersions = listToAttrs
      (map (name: { inherit name; value = final.${name}; }) pyVers);
  in concatMapAttrs
    (pyVer: finalPython: let
      packageOverrides = self: super: mapAttrs
        (_: pybuilder: pybuilder final finalPython self)
        config.flake-manager.registries.python;
      pyNew = finalPython.override {
        inherit packageOverrides;
        self = pyNew;
      };
    in {
      "${pyVer}" = pyNew;
    })
    pythonVersions
  ;

  # pkgs: python: pythonPackages: <pythonLibrary>
  pythonPackageType = types.functionTo types.functionTo types.functionTo types.package;
in {
  options = {
    flake-manager.registries.python = mkOption {
      type = types.lazyAttrsOf pythonPackageType;
      default = { };
    };

    flake.registries.python = mkOption {
      type = types.lazyAttrsOf pythonPackageType;
      default = { };
    };
  };

  config = {
    flake-manager.registries.python = concatMapAttrs
      (name: input:
        if name == "self" then { }
        else input.registries.python or { })
      inputs
    ;

    flake-manager.overlays.python-registry =
      python-registry-overlay
    ;
  };
}
