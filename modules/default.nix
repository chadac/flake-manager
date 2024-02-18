{ systems, devenv, nix2container, mk-shell-bin }:
{ inputs, ... }: {
  systems = import systems;
  _module.args.inputs = inputs ++ [ nix2container mk-shell-bin ];

  imports = [
    devenv.flakeModule
    (import ./poetry-app)
  ];
}
