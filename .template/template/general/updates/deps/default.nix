{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.updates.deps;
  taskName = "${config.template.taskPrefix}:update-deps";
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
    tasks."${taskName}" = {
      exec = "true";
      cwd = config.git.root;
      after = cfg.tasks;
    };

    scripts.template-update-deps.exec = ''
      devenv tasks run ${taskName}
    '';
  };
}
