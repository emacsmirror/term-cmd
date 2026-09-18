{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.strings) escapeRegex escapeShellArg;
  inherit (lib.types) package;
  inherit (templateLib.types) relativePath;

  cfg = config.template.tools.npins;
  taskName = "${config.template.taskPrefix}:update-deps-npins";
in
{
  options.template.tools.npins = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.npins;
    };

    root = mkOption {
      type = relativePath;
      default = "npins";
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    tasks."${taskName}" = {
      exec = ''
        npins -d ${escapeShellArg cfg.root} upgrade
        npins -d ${escapeShellArg cfg.root} update
      '';
      cwd = config.git.root;
    };

    template = {
      updates.deps.tasks = [ taskName ];

      preCommit.exclude = [ "^${escapeRegex cfg.root}/default\\.nix$" ];
    };
  };
}
