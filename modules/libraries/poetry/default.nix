{ inputs, config, lib, flake-parts-lib, flake-manager-lib, python-libraries, ... }:
let
  inherit (lib)
    filterAttrs
    foldAttrs
    getAttrs
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkMerge
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    tryImportFlake
    evalBuilder
    evalBuilders
    mkBuilderOption
    mkDerivationOptions
  ;

  poetry2nixFlake = tryImportFlake "poetry2nix" "github:nix-community/poetry2nix" [ "nixpkgs" ];

  mkPoetryOptions = { pkgs, config, ... }: let
    poetryConfig = config;
  in {
    _file = __curPos.file;

    options = {
      default = mkEnableOption "if true, marks this as the default package to build in the flake.";
      projectDir = mkOption {
        type = types.path;
        description = "path to the root of the project.";
      };
      src = mkOption {
        type = types.path;
        description = "project source (default: `cleanPythonSources { src = projectDir; }`).";
        default = poetryConfig.projectDir;
      };
      pyproject = mkOption {
        type = types.path;
        description = "path to `pyproject.toml` (default: `projectDir + '/pyproject.toml'`).";
        default = poetryConfig.projectDir + "/pyproject.toml";
      };
      poetrylock = mkOption {
        type = types.path;
        description = "`poetry.lock` file path (default: `projectDir + '/poetry.lock'`).";
        default = poetryConfig.projectDir + "/poetry.lock";
      };
      overrides = mkOption {
        # TODO: explicit type
        type = types.anything;
        description = "Python overrides to apply.";
        default = self: super: {};
      };
      meta = mkOption {
        type = types.attrs;
        description = "application meta data (default: `{}`).";
        default = {};
      };
      python = mkOption {
        type = types.package;
        description = "the Python interpreter to use (default: `'python3'`).";
        default = pkgs.python3;
      };
      preferWheels = mkOption {
        type = types.bool;
        description = "use wheels rather than sdist as much as possible (default: `false`).";
        default = false;
      };
      groups = mkOption {
        type = types.listOf types.str;
        description = "which Poetry 1.2.0+ dependency groups to run install (default `[ ]`).";
        default = [ ];
      };
      checkGroups = mkOption {
        type = types.listOf types.str;
        description = "which Poetry 1.2.0+ dependency groups to run unit tests (default: `[ 'dev' ]`).";
        default = [ "dev" ];
      };
      extras = mkOption {
        type = types.listOf types.str;
        description = "which Poetry `extras` to install (default: `['*']`, all extras).";
        default = [ "*" ];
      };
    };
  };

  cfg = config.poetry;

  devenvModule = {
    config.perSystem = lib.mkIf cfg.enable ({ ... }: {
      devenv.shells.default = {
        languages.python = {
          poetry.enable = true;
        };
      };
    });
  };
in {
  _file = __curPos.file;

  imports = [ devenvModule ];

  options.poetry = {
    enable = mkEnableOption "enable building poetry projects in the flake.";
    pythonVersion = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    packages = mkBuilderOption [
      mkPoetryOptions
    ];
    apps = mkBuilderOption [
      mkPoetryOptions
    ];
  };

  config = {
    # currently the flake causes infinite recursion... so we'll just disable that overlay
    # flake-manager.overlays.poetry2nix = lib.mkIf cfg.enable poetry2nixFlake.overlays.default;

    flake.registries.python = let
      toPublish = filterAttrs
        (name: _: name == "default")
        cfg.packages
      ;
    in mapAttrs
      (_: module: pkgs: python: pythonPackages: let
        args = evalBuilder module { inherit pkgs python pythonPackages; };
        pyproject = builtins.fromTOML (builtins.readFile args.pyproject);
      in
        import ./mk-python-package.nix args.src pyproject pkgs pythonPackages)
      toPublish
    ;

    flake.builders.python-packages = 

    perSystem = lib.mkIf cfg.enable ({ inputs', pkgs, config, ... }: let
      poetry2nix = poetry2nixFlake.lib.mkPoetry2Nix { inherit pkgs; };
      python =
        if cfg.pythonVersion != null
        then pkgs."python${cfg.pythonVersion}"
        else pkgs.python3
      ;
      args = evalBuilders cfg.packages {
        inherit inputs' pkgs poetry2nix;
        inherit (pkgs) lib stdenv;
      };
      packages = mapAttrs
        (_: pkgArgs:
          poetry2nix.mkPoetryApplication pkgArgs)
        args
      ;
    in {
      inherit packages;
      devenv.shells = mapAttrs
        (_: package: {
          packages = [ package.dependencyEnv ];
        })
        packages;
    });
  };
}
