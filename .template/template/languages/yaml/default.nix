{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.yaml;
in
{
  options.template.languages.yaml = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.yaml-language-server ];

    template.tools = {
      prettier.enable = mkDefault true;
      yamllint.enable = mkDefault true;
    };
  };
}
