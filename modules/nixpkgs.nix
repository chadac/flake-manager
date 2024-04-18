{ config, lib, flake-manager-lib, inputs, ... }: let
  inherit (lib)
    attrValues
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    tryImportFlake
  ;
  nixpkgs = tryImportFlake "nixpkgs" "github:NixOS/nixpkgs/nixpkgs-unstable" [ ];
in {
  _file = __curPos.file;

  options = {
    flake-manager.overlays = mkOption {
      type = types.lazyAttrsOf (types.functionTo (types.functionTo types.pkgs));
      default = { };
    };
  };

  config.perSystem = { system, ... }: {
    # _module.args.pkgs = import nixpkgs {
    #   inherit system;
    #   overlays = attrValues config.flake-manager.overlays;
    # };
  };
}
