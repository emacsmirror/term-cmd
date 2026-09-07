{
  pkgs,
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
  inherit (pkgs) runCommandLocal;
  inherit (pkgs.writers) writeTOML;
  inherit (lib) mkDefault mkIf;
  inherit (lib.attrsets)
    genAttrs'
    mapAttrs
    mapAttrsRecursiveCond
    mapAttrsToList
    nameValuePair
    recursiveUpdate
    ;
  inherit (lib.strings) escapeShellArg;
  inherit (templateLib) readFileOr;
  inherit (templateLib.seededDeps) mergeDeps;

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

  rawPyproject = writeTOML configFile (recursiveUpdate cfg.config mergedDeps);

  pyproject = runCommandLocal configFile { } ''
    cat >tombi.toml <<EOF
      [[schemas]]
      path = "tombi://www.schemastore.org/pyproject.json"
      include = ["$out"]
    EOF

    cat >$out <<EOF
    # Mostly auto-generated; dependencies can be edited here, but everything else
    # should be edited in devenv.nix.

    EOF

    cat ${escapeShellArg rawPyproject} >>$out

    ${config.template.tools.tombi.formatCommand} --offline $out
  '';
in
{
  config = mkIf cfg.enable {
    files = {
      "${configFile}" = {
        copyMode = "copy";
        source = pyproject;
      };
    };

    template.languages.toml.enable = mkDefault true;
  };
}
