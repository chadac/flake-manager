{ inputs, config, lib, flake-parts-lib, flake-manager-lib, ... }:
let
  inherit (lib)
    concatMapAttrs
    filterAttrs
    listToAttrs
    mkEnableOption
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    recipeTypes
    mkDerivationModule
  ;
  rootConfig = config;
  cfg = config.libraries.python;

  pythonLibraryType = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        default = "${inputs.self}";
      };

      pythonVersion = mkOption {
        type = types.str;
        description = "Name of the nixpkgs python version to use by default.";
        default = "python3";
      };

      additionalPythonVersions = mkOption {
        type = types.listOf types.str;
        description = "List of additional Python versions to test against + release as packages.";
        default = [ ];
      };

      args = mkOption {
        type = types.deferredModuleWith ({
          staticModules = [ mkDerivationModule ];
        });
        description = ''
          Additional build arguments to supply to the recipe builder.
        '';
        example = ''
          libraries.python.my-package = {
            args = { pkgs, ... }: {
              propagatedBuildInputs = with pkgs; [ curl ];
            };
          };
        '';
      };

      recipe = mkOption {
        type = recipeTypes.python;
        description = ''
          Recipe used to build this package. By default this auto-populates
          parameters, but it can be manually overridden.
        '';
      };

      format = mkOption {
        type = types.nullOr (types.enum ["pyproject.toml" "setup.cfg" "setup.py" "requirements.txt"]);
        default = null;
        description = "Project format. Used to infer build parameters.";
      };

      # TODO: enable automatic checks
      # checks = {
      #   ruff = {
      #     enable = mkEnableOption "";
      #   };
      #   black = {
      #     enable = mkEnableOption "";
      #   };
      #   isort = {
      #     enable = mkEnableOption "";
      #   };
      # };

      registry.enable = mkOption {
        type = types.bool;
        default = true;
        description = "If true, publishes this to the Python registry to make it available for others to consume.";
      };

      devenv.enable = mkOption {
        type = types.bool;
        description = "If true, configures the default development environment to use this package.";
      };
    };

    config = {
      args = {
        src = lib.mkDefault config.src;
      };
      recipe = lib.mkDefault (args: import ./infer-builder.nix args config);
      devenv.enable = rootConfig.devenv.enable;
    };
  });
in {
  _file = __curPos.file;

  options.libraries.python = mkOption {
    type = types.lazyAttrsOf pythonLibraryType;
    default = { };
  };

  config = {
    recipes.python = map (lib: lib.recipe) cfg;
    registries.python = map (lib: lib.recipe)
      (filterAttrs (lib: lib.registry.enable) cfg);
  };

  perSystem = { pkgs, ... }: let
    packages = concatMapAttrs (name: lib: let
      pyDefault = pkgs.${lib.pythonVersion};
      pyAdditional = listToAttrs (map
        (pyVer: { name = "${name}-${pyVer}";
                  value = lib.recipe {
                    inherit pkgs;
                    python3 = pkgs.${pyVer};
                    python3Packages = pkgs.${pyVer}.pythonPackages;
                  }; })
        lib.additionalPythonVersions
      );
    in {
      "${name}" = lib.recipe {
        inherit pkgs;
        python3 = pyDefault;
        python3Packages = pyDefault.pythonPackages;
      };
    } // pyAdditional) cfg;
  in {
    inherit packages;
  };
}
