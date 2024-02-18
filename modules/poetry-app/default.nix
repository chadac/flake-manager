{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
  ;
  poetryConfig = config.templates.poetry-app;
in {
  _file = __curPos.file;

  imports = [ ./perSystem.nix ];

  options = {
    templates.poetry-app = {
      enable = mkEnableOption "enable the poetry project template";

      # mirrored poetry2nix options
      projectDir = mkOption {
        type = types.path;
        description = "path to the root of the project";
      };
      src = mkOption {
        type = types.path;
        description = "project source (default: `cleanPythonSources { src = projectDir; }`).";
      };
      pyproject = mkOption {
        type = types.path;
        description = "path to `pyproject.toml` (default: `projectDir + '/pyproject.toml'`).";
        default = poetryConfig.projectDir / "pyproject.toml";
      };
      poetrylock = mkOption {
        type = types.path;
        description = "`poetry.lock` file path (default: `projectDir + '/poetry.lock'`).";
        default = poetryConfig.projectDir / "poetry.lock";
      };
      overrides = mkOption {
        # TODO: explicit type
        type = types.any;
        description = "Python overrides to apply.";
        default = self: super: {};
      };
      meta = mkOption {
        type = types.attrs;
        description = "application meta data (default: `{}`).";
      };
      python = mkOption {
        type = types.package;
        description = "the Python interpreter to use (default: `pkgs.python3`).";
      };
      preferWheels = mkOption {
        type = types.bool;
        description = "use wheels rather than sdist as much as possible (default: `false`).";
      };
      groups = mkOption {
        type = types.listOf types.str;
        description = "which Poetry 1.2.0+ dependency groups to run install (default `[ ]`).";
      };
      checkGroups = mkOption {
        type = types.listOf types.str;
        description = "which Poetry 1.2.0+ dependency groups to run unit tests (default: `[ 'dev' ]`).";
      };
      extras = mkOption {
        type = types.listOf types.str;
        description = "which Poetry `extras` to install (default: `['*']`, all extras).";
      };
    };

    # flake.shared.python-modules = mkOption {
    #   type = types.list;
    # };
  };

  config = {
    # flake = {
    #   shared.python-modules = [
    #     (import ./mk-python-package.nix {
    #       inherit (config.templates.poetry-app)
    #         projectDir
    #         src
    #         pyproject
    #         ;
    #     })
    #   ];
    # };
  };
}
