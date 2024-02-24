{ inputs, config, lib, flake-parts-lib, flake-manager-lib, python-libraries, ... }:
let
  inherit (lib)
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
    tryImportFlake;

  poetry2nix = tryImportFlake "poetry2nix" "github:nix-community/poetry2nix" [ "nixpkgs" ];

  poetryAppType = types.submodule ({ config, ... }:
    let
      poetryConfig = config;
    in {
      # mirrored poetry2nix options
      options = {
        projectDir = mkOption {
          type = types.path;
          description = "path to the root of the project.";
        };
        src = mkOption {
          type = types.nullOr types.path;
          description = "project source (default: `cleanPythonSources { src = projectDir; }`).";
          default = poetryConfig.projectDir;
        };
        pyproject = mkOption {
          type = types.nullOr types.path;
          description = "path to `pyproject.toml` (default: `projectDir + '/pyproject.toml'`).";
          default = poetryConfig.projectDir + "/pyproject.toml";
        };
        poetrylock = mkOption {
          type = types.nullOr types.path;
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
          type = types.str;
          description = "the Python interpreter to use (default: `'python3'`).";
          default = "python3";
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

        doCheck = mkEnableOption "if true, runs `checkPhase`";
      };
    }
  );
  mkPoetry2Nix = inputs.poetry2nix.lib.mkPoetry2Nix or (
    throw "input 'poetry2nix' is missing. add `poetry2nix.url = \"github:nix-community/poetry2nix\"` to your `flake.nix`."
  );
  mkConfig = name: poetryConfig: let
    pyprojectFile = builtins.fromTOML (builtins.readFile poetryConfig.pyproject);
    pname = pyprojectFile.tools.poetry.name;
    version = pyprojectFile.tools.poetry.version;
  in {
    perSystem = { pkgs, inputs', ... }: let
      python-lib-overrides = self: super:
        builtins.mapAttrs (_: builder: builder pkgs self) python-libraries;
      poetry2nix = mkPoetry2Nix { inherit pkgs; };
      python = pkgs.${poetryConfig.python};
      args = poetryConfig // {
        inherit python;
        overrides = [
          poetryConfig.overrides
          python-lib-overrides
        ];
      };
      poetry-app = poetry2nix.mkPoetryApplication args;
      poetry-env = poetry2nix.mkPoetryEnv (args // {
        editablePackageSources = {
          ${pname} = args.src;
        };
      });
    in {
      config = {
        packages = {
          ${name} = poetry-app;
        };
        devenv.shells = {
          ${name} = {
            packages = [ poetry-app.dependencyEnv ];
            languages.python = {
              enable = true;
              package = python;
              poetry.enable = true;
            };
          };
        };
      };
    };
    flake = {
      registries.python.${pname} =
        import ./mk-python-package.nix poetryConfig.src pyprojectFile;
    };
  };

  # from: https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
  mkMergeTopLevel = names: attrs: getAttrs names (
    mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
  );

  cfg = config.poetry;
  enable = cfg.enable;
in {
  _file = __curPos.file;

  options.poetry = {
    enable = mkEnableOption "enables poetry in this project.";
    apps = mkOption {
      type = types.attrsOf poetryAppType;
      description = "attrs of poetry projects. options are derived from poetry2nix parameters.";
      example = ''
        poetry = {
          enable = true;
          apps.default = {
            projectSrc = ./.;
          };
        };
      '';
    };
  };

  config = lib.mkIf enable (
    mkMergeTopLevel ["perSystem" "flake"] (mapAttrsToList mkConfig cfg.apps)
  );
}
