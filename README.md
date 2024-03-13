# flake-manager

Experimental set of extensions to flake-parts to quickly build out
common project templates.

`flake-manager` provides a bunch of reasonable defaults for building
language-specific projects that may need to co-depend on each
other. It provides a standard set of additional exports so that
projects can codepend on each other without much issue.

## Usage

Invoking `flake-manager` is very similar to [flake-parts](https://flake.parts/):

    {
      description = "A basic app";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        flake-manager = {
          url = "github:chadac/flake-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };

      outputs = { flake-manager, ... }@inputs:
        flake-manager.lib.mkFlake { inherit inputs; } {
          packages.default = { pkgs, ... }: pkgs.callPackage ./. { };
        };
    }
