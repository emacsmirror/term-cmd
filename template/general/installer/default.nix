{ lib, config, ... }:
let
  inherit (builtins) readFile replaceStrings;
  inherit (lib) mkEnableOption mkIf;

  cfg = config.template.installer;
in
{
  options.template.installer = {
    enable = (mkEnableOption "enable") // {
      internal = true;
    };
  };

  config = mkIf cfg.enable {
    files."install.sh" = {
      copyMode = "copy";
      text =
        replaceStrings
          [ "@repo@" "@templateDir@" ]
          [ config.template.templateRepo config.template.defaultDir ]
          (readFile ./install.sh);
      executable = true;
    };
  };
}
