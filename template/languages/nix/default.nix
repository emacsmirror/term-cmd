{ lib, config, ... }:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.nix;
in
{
  options.template.languages.nix = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    languages.nix.enable = true; # includes language server

    template.tools = {
      nixfmt.enable = mkDefault true;
      nixf-diagnose.enable = mkDefault true;
      deadnix.enable = mkDefault true;
      shebangChecker.allowShebangs = [ "/usr/bin/env nix-shell" ];
    };
  };
}
