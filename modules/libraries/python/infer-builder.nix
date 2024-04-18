{ pkgs, python3, python3Packages, ... }@args:
{
  src,
  format ? null,
  args,
  ...
}@config:
let
  inherit (pkgs) lib;
  inferredFormat =
    if (builtins.pathExists "${src}/pyproject.toml") then "pyproject.toml"
    else if (builtins.pathExists "${src}/setup.cfg") then "setup.cfg"
    else if (builtins.pathExists "${src}/setup.py") then "setup.py"
    else if (builtins.pathExists "${src}/requirements.txt") then "requirements.txt"
    else "unknown";
  buildArgs = lib.evalModules {
    modules = [
      ({
        _modules.args = {
          inherit pkgs python3 python3Packages;
        };
      })
      args
    ];
  }.config;
  actualFormat = if (builtins.isNull format) then inferredFormat else format;
  pythonBuilders = {
    "pyproject.toml" = ./builders/pyproject-toml.nix;
    "setup.cfg" = ./builders/setup-cfg.nix;
    "setup.py" = ./builders/setup-py.nix;
    "requirements.txt" = ./builders/requirements-txt.nix;
  };
in import (
  pythonBuilders.${actualFormat}
    or (throw "could not infer project type. ensure you have a valid python project.")
) args config
