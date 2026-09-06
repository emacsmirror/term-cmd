{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.nixf-diagnose;
in
{
  options.template.tools.nixf-diagnose = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.nixf-diagnose;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.nixf-diagnose = {
      enable = true;
      package = cfg.package;
      name = "nix: lint";
    };
  };
}
