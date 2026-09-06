{ lib, config, ... }:
let
  inherit (lib)
    getExe'
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) attrsOf json nonEmptyStr;

  cfg = config.template.languages.javascript;
  hooks = config.git-hooks.hooks;
in
{
  imports = [
    ./package-json.nix
    ./updates.nix
  ];

  options.template.languages.javascript = {
    enable = mkEnableOption "enable";

    seedDevDependencies = mkOption {
      type = attrsOf nonEmptyStr;
      default = { };
    };

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !(cfg.config ? dependencies)
          && !(cfg.config ? devDependencies)
          && !(cfg.config ? peerDependencies)
          && !(cfg.config ? peerDependenciesMeta)
          && !(cfg.config ? bundleDependencies)
          && !(cfg.config ? optionalDependencies);
        message = "NPM dependencies must not be defined directly in config; use seedDevDependencies instead";
      }
    ];

    languages.javascript = {
      enable = true; # includes language server
      npm = {
        enable = true;
        install.enable = true;
      };
    };

    files = {
      ".npmrc" = {
        copyMode = "copy";
        text = ''
          fund=false
          ignore-scripts=true
          min-release-age = ${toString config.template.cooldownDays}
        '';
      };
    };

    git-hooks.hooks.npm-sync = {
      enable = true;
      name = "npm: sync";
      package = config.languages.javascript.npm.package;
      entry = "${getExe' hooks.npm-sync.package "npm"} install";
      files = "^(package\\.json|package-lock\\.json)$";
      pass_filenames = false;
      priority = 0;
    };

    template = {
      languages.javascript.config = {
        name = config.template.project.nameSlug;
      };

      tools = {
        prettier.enable = mkDefault true;
        eslint.enable = mkDefault true;
        javascriptLicenseChecker.enable = mkDefault true;
      };

      gitignore = [ "node_modules/" ];

      preCommit.excludes = [ "^package-lock\\.json$" ];

      clean.deepCleanCommands = [ "rm -rf node_modules" ];
    };
  };
}
