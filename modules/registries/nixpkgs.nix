{ config, lib, flake-manager-lib, inputs, ... }: let
  inherit (lib)
    attrValues
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    tryImportFlake
    recipeTypes
  ;
  nixpkgs = tryImportFlake "nixpkgs" "github:NixOS/nixpkgs/nixpkgs-unstable" [ ];

  nixpkgsEntryType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If true, enables the given entry of the registry.";
      };
    };
  };
in {
  _file = __curPos.file;

  options = {
    self.registries.nixpkgs = mkOption {
      type = types.lazyAttrsOf recipeTypes.nixpkgs;
      default = { };
    };
  };

  config.perSystem = { system, ... }: {
    _module.args.pkgs = import nixpkgs {
      inherit system;
      overlays = attrValues config.self.registries.nixpkgs;
    };
  };
}
