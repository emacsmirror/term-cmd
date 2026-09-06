{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkOrder
    ;
  inherit (lib.types) lines package;

  cfg = config.template.tools.editorconfig;
  configFile = ".editorconfig";
in
{
  options.template.tools.editorconfig = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.editorconfig-checker;
    };

    config = mkOption {
      type = lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".text = cfg.config;

    git-hooks.hooks.editorconfig-checker = {
      enable = true;
      name = "general: editorconfig compliance";
      package = cfg.package;
    };

    template = {
      gitignore = [ configFile ];

      tools.editorconfig.config = mkOrder 0 ''
        root = true

        [*]
        end_of_line = lf
        charset = utf-8
        trim_trailing_whitespace = true
        insert_final_newline = true
      '';
    };
  };
}
