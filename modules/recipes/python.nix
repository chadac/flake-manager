{ lib, flake-manager-lib, ... }:
let
  inherit (lib)
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    recipeTypes
  ;
in {
  options = {
    recipes.python = mkOption {
      type = types.lazyAttrsOf recipeTypes.python;
      default = { };
      description = ''
        Builds Python packages.
      '';
    };
  };
}
