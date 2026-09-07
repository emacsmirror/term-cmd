{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins)
    any
    attrNames
    readFile
    replaceStrings
    ;
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.lists) optional;
  inherit (lib.strings) escapeRegex;
  inherit (lib.types) bool listOf nonEmptyStr;

  cfg = config.template.preCommit;
in
{
  options.template.preCommit = {
    enable = mkEnableOption "enable";

    excludes = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    excludeTemplateDir = mkOption {
      type = bool;
      default = true;
      internal = true;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (
        let
          prePushHooks = attrNames (
            filterAttrs (
              _name: value: value.enable && any (stage: stage == "pre-push") value.stages
            ) config.git-hooks.hooks
          );
        in
        {
          assertion = prePushHooks == [ ];
          message = "Found hooks using the pre-push stage: ${toString prePushHooks}";
        }
      )
    ];

    git-hooks = {
      package = pkgs.prek;

      default_stages = [
        "pre-commit"
        "pre-merge-commit"
      ];

      excludes = cfg.excludes;

      hooks = {
        check-added-large-files = {
          enable = true;
          name = "general: check for added large files";
          stages = config.git-hooks.default_stages;
        };
        check-case-conflicts = {
          enable = true;
          name = "general: check for filename case conflicts";
        };
        check-executables-have-shebangs = {
          enable = true;
          name = "general: check that executables have shebangs";
          stages = config.git-hooks.default_stages;
        };
        check-merge-conflicts = {
          enable = true;
          name = "general: check for files with merge conflicts";
        };
        check-shebang-scripts-are-executable = {
          enable = true;
          name = "general: check that files with shebangs are executable";
          stages = config.git-hooks.default_stages;
        };
        check-symlinks = {
          enable = true;
          name = "general: check for broken symlinks";
        };
        check-vcs-permalinks = {
          enable = true;
          name = "general: check vcs website links are permalinks";
        };
        end-of-file-fixer = {
          enable = true;
          name = "general: check files end with a newline";
        };
        fix-byte-order-marker = {
          enable = true;
          name = "general: check files don't have utf-8 byte order markers";
        };
        forbid-new-submodules = {
          enable = true;
          name = "general: forbid new submodules";
        };
        mixed-line-endings = {
          enable = true;
          name = "general: check line endings are correct";
          args = [ "--fix=lf" ];
        };
        trim-trailing-whitespace = {
          enable = true;
          name = "general: check files don't have trailing whitespace";
          stages = config.git-hooks.default_stages;
        };
      };
    };

    files = {
      ".git/hooks/pre-push" = {
        copyMode = "copy";
        text = replaceStrings [ "@versionFile@" ] [ config.template.project.versionFile ] (
          readFile ./pre-push
        );
        executable = true;
      };
    };

    tasks = {
      "${config.template.taskPrefix}:remove-legacy-hooks" = {
        exec = "rm -f .git/hooks/*.legacy";
        before = [ "devenv:enterShell" ];
        after = [ "devenv:git-hooks:install" ];
        cwd = config.git.root;
      };
    };

    template = {
      gitignore = [ ".pre-commit-config.yaml" ];

      preCommit.excludes = [
        "^devenv\\.lock$"
        "^\\.envrc$"
      ]
      ++ (optional cfg.excludeTemplateDir "^${escapeRegex config.template.dir}/.*$");
    };
  };
}
