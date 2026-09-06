{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.nixfmt;
in
{
  options.template.tools.nixfmt = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.nixfmt;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.nixfmt = {
      enable = true;
      name = "nix: format";
      package = cfg.package;
      args = [
        "--strict"
        "--verify"
      ];
    };
  };
}
