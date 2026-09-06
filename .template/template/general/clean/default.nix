{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.clean;
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
      "template:clean" = {
        exec = join "\n" cfg.cleanCommands;
        cwd = "${config.git.root}";
      };
      "template:deepclean" = {
        exec = join "\n" cfg.deepCleanCommands;
        cwd = "${config.git.root}";
        after = [ "template:clean" ];
      };

    };

    scripts = {
      template-clean.exec = ''
        devenv tasks run template:clean
      '';
      template-deepclean.exec = ''
        devenv tasks run template:deepclean
      '';

    };

    template.clean.cleanCommands = [ "find . '(' -type f -name '*~' ')' -delete" ];
  };
}
