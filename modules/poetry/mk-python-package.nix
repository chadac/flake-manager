# Builds a Poetry project with `buildPythonPackage`
#
# This is useful since even if we build a project with Poetry,
# consumers of that project may not also support Poetry. This
# enables developers to build Python packages
src:
pyproject:
pkgs:
pypkgs:
let
  deps = builtins.attrNames pyproject.tool.poetry.dependencies;
  buildDeps = map (buildDep: builtins.match "([A-Za-z0-9_\.\-]+).*" buildDep)
    pyproject.build-system.requires;
in rec {
  name = pyproject.tool.poetry.name;
  value = pypkgs: pypkgs.buildPythonPackage {
    pname = name;
    version = pyproject.tool.poetry.version;
    inherit src;
    format = "pyproject";

    nativeBuildInputs = map (dep: pypkgs.${dep}) buildDeps;
    buildInputs = map (dep: pypkgs.${dep}) deps;
  };
}
