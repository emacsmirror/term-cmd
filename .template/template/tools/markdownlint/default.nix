{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) json package;

  cfg = config.template.tools.markdownlint;
  hooks = config.git-hooks.hooks;
  configFile = ".markdownlint.json";
in
{
  options.template.tools.markdownlint = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.markdownlint-cli2;
    };

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".json = cfg.config;

    git-hooks.hooks.markdownlint = {
      enable = true;
      package = cfg.package;
      name = "markdown: lint";
      entry = "${getExe hooks.markdownlint.package} --fix";
      files = "";
      types_or = [ "markdown" ];
    };

    template = {
      gitignore = [ configFile ];

      tools.markdownlint.config = {
        extends = "markdownlint/style/prettier";
        code-block-style = {
          style = "fenced";
        };
        code-fence-style = {
          style = "backtick";
        };
      };
    };
  };
}
