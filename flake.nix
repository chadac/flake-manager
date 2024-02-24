{
  description = "Additional templates for flake-parts.";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # arion = {
    #   url = "github:hercules-ci/arion";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # devenv = {
    #   url = "github:cachix/devenv";
    #   inputs.nixpkgs.follows  = "nixpkgs";
    # };
  };

  outputs = { self, systems, flake-parts, ... }@oldInputs: rec {
    flakeModule = import ./modules systems;
    lib = {
      mkFlake = { inputs, ... }@arg1: newFlakeModule:
        (inputs.flake-parts or flake-parts).lib.mkFlake (arg1 // {
          inputs = oldInputs // inputs;
        }) {
          imports = [ flakeModule newFlakeModule ];
        };
    };
  };
}
