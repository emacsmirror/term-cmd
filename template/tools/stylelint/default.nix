{ lib, config, ... }:
let
  inherit (lib) getExe' mkEnableOption mkIf;

  cfg = config.template.tools.stylelint;
in
{
  options.template.tools.stylelint = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    git-hooks.hooks.stylelint = {
      enable = true;
      name = "css: lint";
      entry = "${getExe' config.languages.javascript.npm.package "npx"} stylelint --fix";
      types = [ "css" ];
    };

    template.languages.javascript = {
      enable = true;
      seedDevDependencies = {
        stylelint = "17.14.1";
        stylelint-config-standard = "40.0.0";
      };
      config = {
        stylelint = {
          extends = [ "stylelint-config-standard" ];
          reportNeedlessDisables = true;
        };
      };
    };
  };
}
