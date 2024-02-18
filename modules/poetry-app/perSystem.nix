{ config, lib, flake-parts-lib, ... }: let
  inherit (flake-parts-lib)
    mkPerSystemOption
  ;
  collectPyLibs = inputs:
    builtins.concatLists (map
      (input: input.shared.python-modules or [ ])
    )
  ;
  poetryConfig = config.templates.poetry-app;
in {
  _file = __curPos.file;

  options.perSystem = mkPerSystemOption ({ inputs', system, pkgs, ... }: let
    # collect any Python dependencies provided by other Python applications
    pylibs = collectPyLibs inputs';
    pylibOverrides = self: super:
      builtins.mapAttrs
        (_: builder: builder self)
        (builtins.listToAttrs pylibs);

    poetry2nix = pkgs.poetry2nix;
    poetry2nixArgs = (builtins.removeAttrs ["enable"] poetryConfig) // {
      overrides = [
        (poetry2nix.overrides.withDefaults poetryConfig.overrides)
        pylibOverrides
      ];
    };
    poetry-app = poetry2nix.mkPoetryApplication poetry2nixArgs;
    poetry-scripts = poetry2nix.mkPoetryScriptsPackage poetry2nixArgs;
    poetry-pkgs = poetry2nix.mkPoetryPackages poetry2nixArgs;
  in {
    config = lib.mkIf poetryConfig.enable {
      # _module.args.pkgs = lib.mkIf poetryConfig.enable (lib.mkDefault (
      #   builtins.seq
      #     (inputs'.nixpkgs or (throw "flake-parts: The flake does not have a `nixpkgs` input. Please add it, or set `perSystem._module.args.pkgs` yourself."))
      #     (import inputs'.nixpkgs {
      #       inherit system;
      #       overlays = [
      #         (inputs'.poetry2nix.overlays.default or (final: prev: {}))
      #       ];
      #     })
      # ));
      # packages = {
      #   poetry-app = lib.mkIf poetryConfig.enable poetry-app;
      # };
      devenv.shells.default = {
        languages.python = {
          enable = true;
          # package = poetryConfig.python or pkgs.python3;
          poetry.enable = true;
        };
      };
      devenv.shells.init = {
        languages.python = {
          enable = true;
          # package = poetryConfig.python or pkgs.python3;
          poetry.enable = true;
        };
      };
    };
  });
}
