{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
  inherit (lib.attrsets) genAttrs;
  inherit (lib.types)
    json
    listOf
    nonEmptyStr
    package
    ;
  inherit (templateLib) prune;
  inherit (templateLib.formatters) formatJSON;

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

    disableRules = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".source = formatJSON {
      inherit config;
      filename = configFile;
      data = prune cfg.config;
    };

    git-hooks.hooks.markdownlint = {
      enable = true;
      name = "markdown: lint";
      package = cfg.package;
      entry = "${getExe hooks.markdownlint.package} --fix";
      files = "";
      types_or = [ "markdown" ];
    };

    template = {
      gitignore.ignore = [ configFile ];

      tools.markdownlint = {
        config = mkMerge [
          {
            extends = "markdownlint/style/prettier";
            code-block-style = {
              style = "fenced";
            };
            code-fence-style = {
              style = "backtick";
            };
          }
          (genAttrs cfg.disableRules (_rule: {
            enabled = false;
          }))
        ];
      };
    };
  };
}
