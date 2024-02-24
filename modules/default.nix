systems:
{ inputs, ... }: {
  _file = __curPos.file;

  systems = import systems;

  imports = [
    ./all-modules.nix
  ];
}
