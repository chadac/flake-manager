{
  description = "Additional templates for flake-parts.";

  inputs = {
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, systems, devenv }: {
    flakeModule = import ./modules { inherit systems devenv; };
  };
}
