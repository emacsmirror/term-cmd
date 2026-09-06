{ lib, config, ... }:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.toml;
in
{
  options.template.languages.toml = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    template.tools.tombi.enable = mkDefault true; # is language server
  };
}
