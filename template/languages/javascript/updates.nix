{ lib, config, ... }:
let
  inherit (builtins) readFile;
  inherit (lib) mkIf;

  cfg = config.template.languages.javascript;
  taskName = "${config.template.taskPrefix}:update-deps-javascript";
in
{
  config = mkIf cfg.enable {
    tasks = {
      "${taskName}" = {
        exec = readFile ./npm-update-deps.sh;
        cwd = config.git.root;
      };
    };

    template.updates.deps.tasks = [ taskName ];
  };
}
