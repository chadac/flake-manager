{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
  ;
in
{
  # self: super: { newPackage = < ... >; }
  nixpkgs = types.functionTo (types.functionTo (types.lazyAttrsOf types.package));

  # pkgs: python: pythonPackages: <pythonDerivation>
  python = types.functionTo (types.functionTo (types.functionTo types.package));
}
