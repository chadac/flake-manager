/**
 * Builders for flakes.
 *
 * Builders are simply functions that take some arguments (such as a nixpkgs set)
 * and return a derivation. They're dual-purpose:
 *
 * 1. Builders make it easy to expose how parts of a flake are built. Sort
 *    of like publishing the `default.nix` but it doesn't have to have a
 *    `default.nix` now.
 * 2. Builders make it easy to customize behavior. For example, if I want to
 *    create a derivation without using `stdenv.mkDerivation`, I can still
 *    override a builder and get the same functionality.
 * 3. Builders make it easy to benefit from extended behavior. For example,
 *    sometimes we may want to build a Python application for multiple
 *    interpreters. Without builders I may need to replicate this functionality
 *    for every build tool -- with builders, I can have Poetry instead export
 *    there and get the nice advantage of it.
 **/
{ inputs, config, lib, flake-manager-lib, ... }:
let
  inherit (lib)
    evalModules
    filterAttrs
    mapAttrs
    mkEnableOption
    mkOption
    types
  ;
  inherit (flake-manager-lib)
    evalBuilder
    mkBuilderOption
    mkDerivationOptions
  ;

  builderType = functionType: {
    default = mkEnableOption "if true, marks this as the default package on the flake.";
    f = mkOption {
      type = functionType;
      description = "builder function.";
    };
  };
in {
  _file = __curPos.file;

  options = {
    flake.builders.derivation = mkOption {
      type = types.lazyAttrsOf builderType;
      default = { };
    };

    derivations = mkBuilderOption [
      mkDerivationOptions
    ];
  };

  config = {
    flake.builders.derivation = mapAttrs
      (_: derivModule: pkgs: let
          derivArgs = evalBuilder derivModule { inherit pkgs; inherit (pkgs) stdenv lib; };
        in pkgs.stdenv.mkDerivation derivArgs)
      config.derivations;

    perSystem = { inputs, pkgs, ... }: {
      packages = mapAttrs
        (_: builder: builder pkgs)
        config.flake.builders.derivation;
    };
  };
}
