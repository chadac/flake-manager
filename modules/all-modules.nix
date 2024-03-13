{
  _file = __curPos.file;
  imports = [
    # internal libraries
    ./lib.nix
    ./builder.nix
    ./nixpkgs.nix

    # # external tools
    ./compose.nix
    ./devenv.nix

    # # python-related projects
    # ./python-registry.nix
    # # ./python.nix
    ./poetry
  ];
}
