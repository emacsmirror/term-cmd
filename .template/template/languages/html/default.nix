{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.html;
in
{
  options.template.languages.html = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.vscode-langservers-extracted ];

    template.tools = {
      prettier.enable = mkDefault true;
      htmlValidate.enable = mkDefault true;
    };
  };
}
