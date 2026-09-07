{ lib, config, ... }:
let
  inherit (builtins) readFile;
  inherit (lib) mkIf;

  cfg = config.template.languages.python;
  taskName = "${config.template.taskPrefix}:update-deps-python";
in
{
  config = mkIf cfg.enable {
    tasks = {
      "${taskName}" = {
        package = cfg.internalPython;
        exec = readFile ./uv_update_deps.py;
        cwd = config.git.root;
      };
    };

    template.updates.deps.tasks = [ taskName ];
  };
}
