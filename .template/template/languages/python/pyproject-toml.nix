{
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (builtins)
    all
    attrValues
    elemAt
    isAttrs
    match
    ;
  inherit (lib) mkDefault mkIf;
  inherit (lib.attrsets)
    genAttrs'
    mapAttrs
    mapAttrsRecursiveCond
    mapAttrsToList
    nameValuePair
    recursiveUpdate
    ;
  inherit (templateLib) mergeDeps readFileOr;
  inherit (templateLib.formatters) formatTOML;

  cfg = config.template.languages.python;
  configFile = "pyproject.toml";
  currentPyproject = readFileOr config configFile fromTOML { };

  parseDeps =
    deps:
    let
      parseDep =
        dep:
        let
          result = match "([A-Za-z0-9_.\\-]+)(.*)" dep;
          name = elemAt result 0;
          spec = elemAt result 1;
        in
        nameValuePair name spec;
    in
    genAttrs' deps parseDep;

  seedDeps = {
    project.dependencies = cfg.seedDependencies;
    dependency-groups.dev = cfg.seedDevDependencies;
  };

  currentDeps = {
    project = {
      dependencies = parseDeps (currentPyproject.project.dependencies or [ ]);
      optional-dependencies = parseDeps (currentPyproject.project.optional-dependencies or [ ]);
    };

    dependency-groups = mapAttrs (_name: value: parseDeps value) (
      currentPyproject.dependency-groups or { }
    );
  };

  renderDeps = deps: mapAttrsToList (name: value: "${name}${value}") deps;

  mergedDeps = mapAttrsRecursiveCond (set: all isAttrs (attrValues set)) (
    _path: value: renderDeps value
  ) (mergeDeps seedDeps currentDeps);
in
{
  config = mkIf cfg.enable {
    files."${configFile}" = {
      copyMode = "copy";
      source = formatTOML {
        inherit config;
        filename = configFile;
        data = recursiveUpdate cfg.config mergedDeps;
        comment = "Mostly auto-generated; dependencies can be edited here, but everything else should be edited in devenv.nix.";
        tombiConfig = {
          schemas = [
            {
              path = "tombi://www.schemastore.org/pyproject.json";
              include = [ "*" ];
            }
          ];
        };
      };
    };

    template.languages.toml.enable = mkDefault true;
  };
}
