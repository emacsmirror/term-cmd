{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) readFile;
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    ;
  inherit (lib.strings) trim;
  inherit (lib.types) bool ints nonEmptyStr;

  templateLib = import ./lib { inherit pkgs lib; };
  inherit (templateLib) findModules localRelPath;

  cfg = config.template;
  defaultDir = ".template";
  taskPrefix = "template";
in
{
  imports = findModules [
    ./ci
    ./general
    ./languages
    ./tools
  ];

  options.template = {
    dir = mkOption {
      type = localRelPath;
      default = defaultDir;
    };

    testDir = mkOption {
      type = localRelPath;
      default = "tests";
    };

    cooldownDays = mkOption {
      type = ints.positive;
      default = 7;
    };

    templateRepo = mkOption {
      type = nonEmptyStr;
      default = trim (readFile ./template-repo);
    };

    templateDev = mkOption {
      type = bool;
      default = false;
      internal = true;
    };

    defaultDir = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };

    taskPrefix = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };
  };

  config = mkMerge [
    {
      _module.args = { inherit templateLib; };

      devenv.warnOnNewVersion = false;

      template = {
        defaultDir = defaultDir;
        taskPrefix = taskPrefix;
        preCommit.enable = mkDefault true;
        clean.enable = mkDefault true;

        languages.nix.enable = mkDefault true;

        tools = {
          editorconfig.enable = mkDefault true;
          gitleaks.enable = mkDefault true;
          gitlint.enable = mkDefault true;
          shebangChecker.enable = mkDefault true;
          typos.enable = mkDefault true;
        };

        updates = {
          template.enable = mkDefault true;
          deps.enable = mkDefault true;
        };
      };
    }
    (mkIf cfg.templateDev {
      template = {
        preCommit.excludeTemplateDir = false;
        installer.enable = true;
        updates.template.enable = false;
        languages.python.includeInternalDeps = true;
      };

      files = {
        "${cfg.dir}/version" = {
          copyMode = "copy";
          text = "${cfg.project.version}\n";
        };
      };
    })
  ];
}
