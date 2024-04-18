{ inputs, lib, flake-parts-lib, ... }@args:
let
  inherit (lib)
    concatStringSep
    foldAttrs
    evalModules
    getAttrs
    mapAttrs
    mkDeferredModuleType
    mkMerge
    mkOption
    mkEnableOption
    types
  ;
  importBasic = name: url: ''${name}.url = "${url}";'';
  importPassthru = passthru: name: url: let
    passthruFmt = builtins.concatStringsSep "  \n"
      (map (p: ''inputs.${p}.follows = "${p}";'') passthru);
  in ''
    inputs.${name} = {
      url = "${url}";
      ${passthruFmt}
    };
  '';

  mkDependencyOption = description: mkOption {
    type = types.listOf types.package;
    inherit description;
    default = [ ];
  };

  dependencyOptions = {
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
    nativeCheckInputs = mkDependencyOption "";
  };

  phaseOptions = {
    dontUnpack = mkEnableOption "";
    unpackPhase = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    dontPatch = mkEnableOption "";
    patchPhase = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    dontConfigure = mkEnableOption "";
    configureFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    configureFlagsArray = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    configurePhase = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    dontBuild = mkEnableOption "";
    buildPhase = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    makeFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    doCheck = mkOption {
      type = types.bool;
      default = true;
    };
    checkTarget = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    checkPhase = mkOption {
      type = types.nullOr types.str;
      description = "shell script run during check phase.";
      default = null;
    };

    installPhase = mkOption {
      type = types.nullOr types.str;
      description = "shell script run during install phase.";
      default = null;
    };
  };

  packageNameOptions = {
      pname = mkOption {
        type = types.str;
        description = "package name.";
      };

      version = mkOption {
        type = types.str;
        description = "package version.";
      };

      name = mkOption {
        type = types.str;
        description = "full package name.";
      };
  };
  # from https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-reference
  # TODO: make this more complete
  mkDerivationModule = { config, ... }: {
    _file = __curPos.file;

    options = (dependencyOptions // phaseOptions // packageNameOptions // {
      src = mkOption {
        type = types.path;
        description = "package source directory.";
      };

      enableParallelBuilding = mkEnableOption "";

      passthru = mkOption {
        type = types.attrs;
        description = "additional attributes";
        default = { };
      };

      meta = mkOption {
        type = types.attrs;
        description = "meta attributes";
        default = { };
      };
    });
    config = {
      name = lib.mkDefault "${config.pname}-${config.version}";
    };
  };
in {
  _file = __curPos.file;

  _module.args.flake-manager-lib = {
    inherit
      dependencyOptions
      phaseOptions
      mkDependencyOption
      packageNameOptions
    ;

    # from: https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
    # useful for defining top-level options that export both perSystem and flake-level attrs
    mkMergeTopLevel = names: attrs: passthru: getAttrs names (
      mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
    );

    tryImportFlake = name: url: passthru: let
      fn = if (builtins.length passthru) <= 0 then importBasic else importPassthru passthru;
      example = fn name url;
    in
      builtins.seq
        (inputs.${name} or (throw "input '${name}' not found. add the following to your `flake.nix`:\n\n${example}\n"))
        inputs.${name};

    # Option that is enabled by default when a flake input is present.
    mkEnableInputOption = inputName: description: mkOption {
      type = types.bool;
      inherit description;
      default = builtins.hasAttr inputName inputs;
    };

    recipeTypes = import ./recipes.nix args;
  };
}
