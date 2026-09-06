{
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (builtins) fromJSON;
  inherit (lib) mkDefault mkIf;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (templateLib) readFileOr;
  inherit (templateLib.seededDeps) mergeDeps;

  cfg = config.template.languages.javascript;
  configFile = "package.json";
  currentPackage = readFileOr config configFile fromJSON { };

  seedDeps = {
    devDependencies = cfg.seedDevDependencies;
  };

  currentDeps = {
    dependencies = currentPackage.dependencies or { };
    devDependencies = currentPackage.devDependencies or { };
    peerDependencies = currentPackage.peerDependencies or { };
    peerDependenciesMeta = currentPackage.peerDependenciesMeta or { };
    bundleDependencies = currentPackage.bundleDependencies or { };
    optionalDependencies = currentPackage.optionalDependencies or { };
  };

  mergedDeps = mergeDeps seedDeps currentDeps;
  mergedConfig = recursiveUpdate cfg.config mergedDeps;
in
{
  config = mkIf cfg.enable {
    files = {
      "${configFile}" = {
        copyMode = "copy";
        json = mergedConfig;
      };
    };

    template.languages.json.enable = mkDefault true;
  };
}
