{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.deadnix;
in
{
  options.template.tools.deadnix = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.deadnix;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.deadnix = {
      enable = true;
      name = "nix: dead code";
      package = cfg.package;
    };
  };
}
