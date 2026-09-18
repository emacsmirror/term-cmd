{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) readFile replaceStrings;
  inherit (lib) mkEnableOption mkIf;

  cfg = config.template.updates.template;
  taskName = "${config.template.taskPrefix}:update-template";
in
{
  options.template.updates.template = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    packages = [ pkgs.jq ];

    tasks."${taskName}" = {
      exec =
        replaceStrings [ "@templateDir@" "@repo@" ] [ config.template.dir config.template.templateRepo ]
          (readFile ./update-template.sh);
      cwd = config.git.root;
      showOutput = true;
    };

    scripts.template-update-template.exec = ''
      devenv tasks run --input "ref=''${1:-}" ${taskName}
    '';
  };
}
