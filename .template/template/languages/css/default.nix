{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.css;
in
{
  options.template.languages.css = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.vscode-css-languageserver ];

    template.tools = {
      prettier.enable = mkDefault true;
      stylelint.enable = mkDefault true;
    };
  };
}
