# todo: support poetry
pkgs: python3: python3Packages:
{
  name,
  src,
  format,
  buildArgs,
  ...
}:
let
  parsePythonName = p: builtins.head (builtins.match "([A-Za-z0-9\.\-]+)" p);

  getPythonPackage = p: builtins.getAttr (parsePythonName p) python3Packages;
  pyproject = builtins.fromTOML (builtins.readFile "${src}/pyproject.toml");
  version = pyproject.project.version or "0.0.0";

  nativeBuildInputs = map getPythonPackage pyproject.build-system.requires;
  propagatedBuildInputs = map getPythonPackage (pyproject.project.dependencies or [ ]);
  nativeCheckInputs = map getPythonPackage (pyproject.project.optional-dependencies.dev or [ ]);
in python3Packages.buildPythonPackage (buildArgs // {
  # TODO: Assert that `name` is identical to the name specified in pyproject.toml
  pname = name;
  inherit version;

  format = "pyproject";

  nativeBuildInputs = nativeBuildInputs ++ buildArgs.nativeBuildInputs;
  propagatedBuildInputs = propagatedBuildInputs ++ buildArgs.propagatedBuildInputs;
  nativeCheckInputs = nativeCheckInputs ++ buildArgs.nativeCheckInputs;
})
