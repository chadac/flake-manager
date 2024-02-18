{
  description = "Additional templates for flake-parts.";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows  = "nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows  = "nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = { self, systems, devenv, nix2container, mk-shell-bin, ... }: {
    flakeModule = import ./modules { inherit systems devenv nix2container mk-shell-bin; };
  };
}
