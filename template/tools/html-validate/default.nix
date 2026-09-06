{ lib, config, ... }:
let
  inherit (lib) getExe' mkEnableOption mkIf;

  cfg = config.template.tools.htmlValidate;
  configFile = ".htmlvalidate.json";
in
{
  options.template.tools.htmlValidate = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    files = {
      "${configFile}".json = {
        root = true;
        extends = [
          "html-validate:recommended"
          "html-validate:document"
          "html-validate:prettier"
        ];
      };
    };

    git-hooks.hooks.html-validate = {
      enable = true;
      name = "html: lint";
      entry = "${getExe' config.languages.javascript.npm.package "npx"} html-validate";
      types = [ "html" ];
    };

    template = {
      languages.javascript = {
        enable = true;
        seedDevDependencies = {
          html-validate = "11.8.0";
        };
      };

      gitignore = [ configFile ];
    };
  };
}
