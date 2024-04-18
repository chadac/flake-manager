{ config, inputs, lib, flake-parts-lib, flake-manager-lib, ... }: let
  inherit (lib)
    mkEnableOption
    types
  ;
  inherit (flake-parts-lib)
    mkPerSystemOption
  ;
  inherit (flake-manager-lib)
    tryImportFlake
    mkEnableInputOption
  ;
  devenv = tryImportFlake "devenv" "github:cachix/devenv" [ "nixpkgs" ];
  enable = config.devenv.enable;
in {
  _file = __curPos.file;

  # make this a top-level module for convenience
  options.devenv.enable = mkEnableOption "enables devenvs";

  options.perSystem = mkPerSystemOption ({ pkgs, config, ... }: let
    devenvType = (devenv.lib.mkEval {
      inherit inputs pkgs;
      modules = [ ];
    }).type;
    cfg = config.devenv;
  in {
    _file = __curPos.file;

    options = {
      devenv = {
        enable = mkEnableInputOption "devenv" "https://devenv.sh/";
        shells = lib.mkOption {
          type = types.lazyAttrsOf devenvType;
          default = { };
        };
      };
    };

    config.devShells = lib.mkIf enable
      (lib.mapAttrs(_name: _devenv: _devenv.shell) cfg.shells);
  });
}
