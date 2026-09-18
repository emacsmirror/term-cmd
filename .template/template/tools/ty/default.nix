{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (builtins) pathExists;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.strings) escapeShellArg join;
  inherit (lib.types) package toml;
  inherit (templateLib.types) relativePath;

  cfg = config.template.tools.ty;
  python = config.template.languages.python;

  targetVersion = python.minVersion;
in
{
  options.template.tools.ty = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.ty;
    };

    stubDir = mkOption {
      type = relativePath;
      default = "stubs";
    };

    config = mkOption {
      type = toml;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.ty = {
      enable = true;
      name = "python: typecheck";
      entry = join " " [
        "${getExe cfg.package}"
        "check"
        "--python-version "
        "${escapeShellArg targetVersion}"
      ];
      types_or = python.fileTags;
    };

    template = {
      languages.python.config.tool.ty = cfg.config;

      tools.ty.config = {
        rules = {
          all = "error";
        };
        environment = {
          extra-paths = mkIf (pathExists "${config.git.root}/${cfg.stubDir}") [ cfg.stubDir ];
          python-version = targetVersion;
        };
      };
    };
  };
}
