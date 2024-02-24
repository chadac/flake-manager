{ config, inputs, flake-parts-lib, flake-manager-lib, lib, ... }:
let
  inherit (lib)
    concatMapAttrs
    mkDefault
    mkEnableOption
    mkOption
    types
  ;
  inherit (flake-parts-lib)
    mkPerSystemOption
  ;
  inherit (flake-manager-lib)
    tryImportFlake
  ;
  arion = tryImportFlake "arion" "github:hercules-ci/arion" "nixpkgs";
  enable = config.compose.enable;
in {
  options.compose.enable = mkEnableOption "enable arion compose files";
  options.perSystem = mkPerSystemOption ({ inputs', config, pkgs, ... }: let
      arionType = (arion.lib.eval {
        inherit pkgs;
        modules = [
          # flake-parts specific additional modules if necessary
        ];
      }).type;
    in {
      _file = __curPos.file;

      options.compose.files = mkOption {
        # this is a risk!!
        type = types.lazyAttrsOf arionType;
        description = ''
          Set up an arion-compose configuration.
        '';
        default = { };
      };

      config = lib.mkIf enable {
        packages = concatMapAttrs
          (name: compose: {
            # TODO: add package to spin up yaml
            "${name}-yaml" = compose.dockerComposeYaml;
          })
          config.compose.files
        ;
        devenv.shells.default = config.mkIf enable {
          packages = [
            inputs'.arion.packages.arion
          ];
        };
      };
    });
}
