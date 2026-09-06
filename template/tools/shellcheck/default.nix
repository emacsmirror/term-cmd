{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) lessThan sort;
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr package;

  cfg = config.template.tools.shellcheck;
  configFile = ".shellcheckrc";
in
{
  options.template.tools.shellcheck = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.shellcheck;
    };

    config = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    disables = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".text = join "\n" cfg.config;

    git-hooks.hooks.shellcheck = {
      enable = true;
      name = "shell: lint";
      package = cfg.package;
      exclude_types = [ "zsh" ];
      require_serial = true;
    };

    template = {
      gitignore = [ configFile ];

      tools.shellcheck = {
        config = [ "disable=${join "," (sort lessThan cfg.disables)}" ];

        disables = [
          "SC1090"
          "SC1091"
        ];
      };
    };
  };
}
