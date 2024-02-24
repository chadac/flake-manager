{ inputs, config, lib, flake-parts-lib, flake-manager-lib, ... }:
let
  inherit (lib)
    evalModules
    mapAttrs
    mkEnableOption
    mkOption
    types
  ;
  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  mkDependencyOption = description: mkOption {
    type = types.listOf types.package;
    inherit description;
  };

  # from https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-reference
  # TODO: make this more complete
  mkDerivationOptions = {
    name = mkOption {
      type = types.str;
      description = "full package name.";
    };
    pname = mkOption {
      type = types.str;
      description = "package name.";
    };
    version = mkOption {
      type = types.str;
      description = "package version.";
    };
    src = mkOption {
      type = types.path;
      description = "package source directory.";
    };

    enableParallelBuilding = mkEnableOption "";

    depsBuildBuild = mkDependencyOption "dependencies whose host and target platform are the same.";
    nativeBuildInputs = mkDependencyOption "";
    depsBuildTarget = mkDependencyOption "";
    depsHostHost = mkDependencyOption "";
    buildInputs = mkDependencyOption "";
    depsTargetTarget = mkDependencyOption "";
    depsBuildBuildPropagated = mkDependencyOption "";
    propagatedNativeBuildInputs = mkDependencyOption "";
    depsBuildTargetPropagated = mkDependencyOption "";
    depsHostHostPropagated = mkDependencyOption "";
    propagatedBuildInputs = mkDependencyOption "";
    depsTargetTargetPropagated = mkDependencyOption "";

    dontUnpack = mkEnableOption "";
    unpackPhase = mkOption {
      type = types.str;
    };

    dontPatch = mkEnableOption "";
    patchPhase = mkOption {
      type = types.str;
    };

    dontConfigure = mkEnableOption "";
    configureFlags = mkOption {
      type = types.str;
    };
    configureFlagsArray = mkOption {
      type = types.listOf types.str;
    };
    configurePhase = mkOption {
      type = types.str;
    };

    dontBuild = mkEnableOption "";
    buildPhase = mkOption {
      type = types.str;
      description = "shell script run during build phase.";
    };

    doCheck = mkOption {
      type = types.bool;
    };
    checkTarget = mkOption {
      type = types.str;
    };
    nativeCheckInputs = mkDependencyOption "";
    checkPhase = mkOption {
      type = types.str;
      description = "shell script run during check phase.";
    };

    installPhase = mkOption {
      type = types.str;
      description = "shell script run during install phase.";
    };
    passthru = mkOption {
      type = types.attrs;
      description = "additional attributes";
    };

    meta = mkOption {
      type = types.attrs;
      description = "meta attributes";
    };
  };

  mkBuilderOption =
    {
      prefix,
      options ? mkDerivationOptions,
    }:
    mkOption {
      type = mkDeferredModuleType ({ ... }: {
        inherit options;
      });

      apply = modules: specialArgs: (
        evalModules {
          inherit prefix modules;
        }
      ).config;
    };

  derivBuilderType = mkBuilderOption {
    prefix = ["builders" "packages"];
    options = mkDerivationOptions;
  };
in {
  _module.args.flake-modules-lib = {
    inherit mkDerivationOptions mkBuilderOption;
  };

  options.builders = {
    packages = mkOption {
      type = types.lazyAttrsOf mkBuilderOption;
    };
  };

  perSystem = { pkgs, ... }: {
    packages = mapAttrs
      (builder: builder { inherit pkgs; })
      config.builders.packages;
  };
}
