{
  _file = __curPos.file;
  imports = [
    # internal
    ./lib
    ./nixpkgs.nix

    # external stuff
    ./devenv.nix

    # repository files
    # ./repo/file.nix
    # ./repo/pre-commit.nix
    # ./repo/docker-compose.nix
    # ./repo/flox.nix

    # ci
    # ./ci/basic
    # ./ci/gitlab-ci
    # ./ci/github-actions
    # ./ci/dagger-io

    # recipes
    ./recipes/derivation.nix
    ./recipes/python.nix

    # registries
    ./registries/nixpkgs.nix
    ./registries/python.nix

    # libraries
    ./libraries/python
    # ./libraries/poetry
  ];
}
