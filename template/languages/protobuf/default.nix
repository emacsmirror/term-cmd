{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.protobuf;
in
{
  options.template.languages.protobuf = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.protobuf ];

    template.tools.buf.enable = mkDefault true; # is language server
  };
}
