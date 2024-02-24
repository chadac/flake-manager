{
  imports = [
    # internal libraries
    ./lib.nix

    # external tools
    ./compose.nix
    ./devenv.nix

    # python-related projects
    ./python-registry.nix
    ./python.nix
    ./poetry
  ];
}
