{
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
  inherit (lib.strings) escapeShellArg join;
  inherit (lib.types) toml;
  inherit (lib.versions) majorMinor;
  inherit (templateLib) localRelPath;

  cfg = config.template.tools.mypy;
  python = config.template.languages.python;
in
{
  options.template.tools.mypy = {
    enable = mkEnableOption "enable";

    stubDir = mkOption {
      type = localRelPath;
      default = "stubs";
    };

    config = mkOption {
      type = toml;
      default = { };
    };
  };

  config = mkIf cfg.enable {

    git-hooks.hooks = mkMerge (
      map (
        rawVersion:
        let
          version = majorMinor rawVersion;
          id = "mypy-${version}";
        in
        {
          "${id}" = {
            enable = true;
            name = "python ${version}: typecheck";
            entry = join " " [
              "${getExe config.languages.python.uv.package}"
              "run"
              "mypy"
              "--python-version"
              "${escapeShellArg version}"
            ];
            types_or = python.fileTags;
            require_serial = true;
          };
        }
      ) python.versions
    );

    template = {
      languages.python = {
        seedDevDependencies = {
          mypy = "==2.3.1";
        };
        config.tool.mypy = cfg.config;
      };

      tools.mypy.config = {
        explicit_package_bases = !python.isPackage;
        mypy_path = cfg.stubDir;
        namespace_packages = !python.isPackage;
        pretty = true;
        python_version = majorMinor python.maxVersion;
        scripts_are_modules = true;
        strict = true;
      };

      clean.deepCleanCommands = [ "rm -rf .mypy_cache" ];
    };
  };
}
