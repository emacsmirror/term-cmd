{
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) json;
  inherit (templateLib) prune;
  inherit (templateLib.formatters) formatJSON;

  cfg = config.template.tools.htmlValidate;
  configFile = ".htmlvalidate.json";
in
{
  options.template.tools.htmlValidate = {
    enable = mkEnableOption "enable";

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    files."${configFile}".source = formatJSON {
      inherit config;
      filename = configFile;
      data = prune cfg.config;
    };

    git-hooks.hooks.html-validate = {
      enable = true;
      name = "html: lint";
      entry = "${getExe' config.languages.javascript.npm.package "npx"} html-validate";
      types = [ "html" ];
    };

    template = {
      tools.htmlValidate.config = {
        root = true;
        extends = [
          "html-validate:recommended"
          "html-validate:document"
          "html-validate:prettier"
        ];
      };

      languages.javascript = {
        enable = true;
        seedDevDependencies = {
          html-validate = "11.8.0";
        };
      };

      gitignore.ignore = [ configFile ];
    };
  };
}
