{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.clean;
  taskPrefix = config.template.taskPrefix;
  clean = "${taskPrefix}:clean";
  deepClean = "${taskPrefix}:deepclean";
in
{
  options.template.clean = {
    enable = mkEnableOption "enable";

    cleanCommands = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    deepCleanCommands = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    tasks = {
      "${clean}" = {
        exec = join "\n" cfg.cleanCommands;
        cwd = config.git.root;
      };
      "${deepClean}" = {
        exec = join "\n" cfg.deepCleanCommands;
        cwd = config.git.root;
        after = [ clean ];
      };
    };

    scripts = {
      template-clean.exec = ''
        devenv tasks run ${clean}
      '';
      template-deepclean.exec = ''
        devenv tasks run ${deepClean}
      '';
    };

    template.clean.cleanCommands = [ "find . '(' -type f -name '*~' ')' -delete" ];
  };
}
