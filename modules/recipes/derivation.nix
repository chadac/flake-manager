{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
  ;
  recipeType = types.functionTo types.package;
  callPackageType = types.functionTo types.package;
in {
  options = {
    recipes.call-package = mkOption {
      type = types.lazyAttrsof callPackageType;
      default = { };
      description = ''
        Recipes for derivations built via callPackage.
      '';
      example = ''
        recipes.call-package.my-package = import ./default.nix;
      '';
    };

    flake.recipes = mkOption {
      type = types.lazyAttrsOf recipeType;
    };
  };
  config = {
  };
}
