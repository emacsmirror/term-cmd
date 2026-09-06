{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.gitlint;
  configFile = ".gitlint";
in
{
  options.template.tools.gitlint = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.gitlint;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".text = ''
      [general]
      ignore=body-is-missing
    '';

    git-hooks.hooks.gitlint = {
      enable = true;
      name = "general: check commit message";
      package = cfg.package;
    };

    template.gitignore = [ configFile ];
  };
}
