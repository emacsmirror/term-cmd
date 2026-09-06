{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) package toml;

  cfg = config.template.tools.typos;
  configFile = ".typos.toml";
in
{
  options.template.tools.typos = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.typos;
    };

    config = mkOption {
      type = toml;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".toml = cfg.config;

    git-hooks.hooks.typos = {
      enable = true;
      name = "general: spellcheck";
      package = cfg.package;
      settings.write = true;
    };

    template = {
      gitignore = [ configFile ];

      tools.typos.config = {
        default = {
          extend-ignore-re = [
            "(?Rm)^.*(#|//)\\s*spellchecker: *disable-line$"
            "(?s)(#|//)\\s*spellchecker:* off.*?\\n\\s*(#|//)\\s*spellchecker:* on"
            "(#|//)\\s*spellchecker:* disable-next-line\\n.*"
          ];
        };
      };
    };
  };
}
