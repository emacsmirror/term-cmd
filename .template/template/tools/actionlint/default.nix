{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.actionlint;
in
{
  options.template.tools.actionlint = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.actionlint;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.actionlint = {
      enable = true;
      package = cfg.package;
      name = "github actions: lint";
    };
  };
}
