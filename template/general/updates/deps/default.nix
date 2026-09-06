{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.updates.deps;
in
{
  options.template.updates.deps = {
    enable = mkEnableOption "enable";

    tasks = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    tasks = {
      "template:update-deps" = {
        exec = "true";
        cwd = "${config.git.root}";
        after = cfg.tasks;
      };
    };

    scripts = {
      template-update-deps.exec = ''
        devenv tasks run template:update-deps
      '';
    };
  };
}
