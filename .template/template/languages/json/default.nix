{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.json;
in
{
  options.template.languages.json = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.vscode-json-languageserver ];

    template.tools.prettier.enable = mkDefault true;
  };
}
