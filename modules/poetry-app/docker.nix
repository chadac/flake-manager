{
  buildEnv,
  dockerTools,

  # non-defaults
  poetry-app,
}:
dockerTools.buildImage {
  name = "${poetry-app.pname}-image";
  tag = "latest";

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [ poetry-app poetry-app.dependencyEnv ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Cmd = [ "/bin/python" "-m" "${poetry-app.pname}" ];
  };
}
