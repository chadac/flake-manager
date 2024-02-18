# Builds a Poetry project with `buildPythonPackage`
#
# This is useful since even if we build a project with Poetry,
# consumers of that project may not also support Poetry. This
# enables developers to build Python packages
{
  src,
  pyproject,
}:
let
  toml = builtins.readTOML (builtins.readFile pyproject);
  deps = builtins.attrNames toml.tool.poetry.dependencies;
  buildDeps = map (buildDep: builtins.match "([A-Za-z0-9_\.\-]+).*" buildDep)
    toml.build-system.requires;
in rec {
  name = toml.tool.poetry.name;
  value = pypkgs: (pypkgs.buildPythonPackage {
    pname = name;
    version = toml.tool.poetry.version;
    inherit src;
    format = "pyproject";

    nativeBuildInputs = map (dep: pypkgs.${dep}) buildDeps;
    buildInputs = map (dep: pypkgs.${dep}) deps;
  });
}
