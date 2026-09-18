{ pkgs, lib }:
let
  inherit (builtins)
    concatMap
    filter
    isAttrs
    isList
    pathExists
    readDir
    readFile
    ;
  inherit (lib.attrsets)
    attrsToList
    filterAttrs
    mapAttrs
    recursiveUpdate
    ;

  formatters = import ./formatters.nix { inherit pkgs lib; };
  types = import ./types.nix { inherit lib; };

  findModules =
    dirs:
    let
      findModulesDir =
        dir:
        let
          contents = readDir dir;
          subDirs = map (a: a.name) (filter (a: a.value == "directory") (attrsToList contents));
        in
        if contents ? "default.nix" && contents."default.nix" == "regular" then
          [ dir ]
        else
          concatMap (d: findModulesDir (dir + "/${d}")) subDirs;
    in
    concatMap findModulesDir dirs;

  readFileOr =
    config: file: parser: default:
    let
      path = "${config.devenv.root}/${file}";
    in
    if pathExists path then parser (readFile path) else default;

  prune =
    input:
    let
      pruneAttrs =
        input:
        filterAttrs (_name: value: value != [ ] && value != { }) (
          mapAttrs (_name: value: prune value) input
        );

      pruneList = input: filter (value: value != [ ] && value != { }) (map prune input);
    in
    if isAttrs input then
      pruneAttrs input
    else if isList input then
      pruneList input
    else
      input;

  mergeDeps = seedDeps: currentDeps: prune (recursiveUpdate seedDeps currentDeps);
in
{
  inherit
    formatters
    types
    findModules
    readFileOr
    prune
    mergeDeps
    ;
}
