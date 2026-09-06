{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package;

  cfg = config.template.tools.zizmor;
in
{
  options.template.tools.zizmor = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.zizmor;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.zizmor = {
      enable = true;
      package = cfg.package;
      name = "github actions: security";
      args = [
        "--pedantic"
        "--no-progress"
      ];
      require_serial = true;
    };
  };
}
