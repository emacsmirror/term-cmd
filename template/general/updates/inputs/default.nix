{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.template.updates.inputs;
in
{
  options.template.updates.inputs = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    scripts.template-update-inputs.exec = ''
      devenv update
    '';
  };
}
