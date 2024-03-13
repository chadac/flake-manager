{ inputs, lib, flake-parts-lib, ... }:
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

  # from https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-reference
  # TODO: make this more complete
  mkDerivationOptions = { config, ... }: {
    _file = __curPos.file;

    options = {
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
        default = "${config.pname}-${config.version}";
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
      nativeCheckInputs = mkDependencyOption "";
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
    };
  };

  mkBuilderOption = modules: let
    type = types.deferredModuleWith {
      staticModules = modules;
    };
  in mkOption {
    type = types.lazyAttrsOf type;
    default = { };
  };

  evalBuilder = module: specialArgs: (evalModules {
    modules = [ module ];
    inherit specialArgs;
  }).config;

  evalBuilders = attrModules: specialArgs: mapAttrs
    (_: module:
      (evalModules {
        modules = [ module ];
        inherit specialArgs;
      }).config)
    attrModules;
in {
  _file = __curPos.file;

  _module.args.flake-manager-lib = {
    inherit evalBuilder evalBuilders mkDependencyOption mkBuilderOption mkDerivationOptions;

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
  };
}
