{ systems, devenv }:
{ ... }: {
  systems = import systems;

  imports = [
    devenv.flakeModule
    (import ./poetry-app)
  ];
}
