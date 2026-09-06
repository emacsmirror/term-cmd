{ pkgs, lib }:
let
  inherit (builtins)
    concatMap
    filter
    pathExists
    readDir
    readFile
    ;
  inherit (pkgs) runCommandLocal;
  inherit (lib.attrsets) attrsToList;
  inherit (lib.strings) escapeShellArg;
  inherit (lib.types) pathWith;

  seededDeps = import ./seeded-deps.nix { inherit lib; };

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

  localRelPath = pathWith {
    inStore = false;
    absolute = false;
  };

  readFileOr =
    config: file: parser: default:
    let
      path = "${config.devenv.root}/${file}";
    in
    if pathExists path then parser (readFile path) else default;

  formatWithPrettier =
    config: writer: filename: data:
    let
      raw = writer filename data;
    in
    runCommandLocal filename { } ''
      cat ${escapeShellArg raw} >>$out

      ${config.template.tools.prettier.formatCommand} $out
    '';
in
{
  inherit
    seededDeps
    findModules
    localRelPath
    readFileOr
    formatWithPrettier
    ;
}
