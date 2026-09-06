{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) package toml;

  cfg = config.template.tools.gitleaks;
  hooks = config.git-hooks.hooks;
  configFile = ".gitleaks.toml";
in
{
  options.template.tools.gitleaks = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.gitleaks;
    };

    config = mkOption {
      type = toml;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".toml = cfg.config;

    git-hooks.hooks.gitleaks = {
      enable = true;
      name = "general: check for committed secrets";
      package = cfg.package;
      entry = "${getExe hooks.gitleaks.package} git --pre-commit --redact --staged --verbose";
      pass_filenames = false;
    };

    template = {
      gitignore = [ configFile ];

      tools.gitleaks.config = {
        extend.useDefault = true;
      };
    };
  };
}
