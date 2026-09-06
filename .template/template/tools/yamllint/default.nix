{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types)
    json
    listOf
    nonEmptyStr
    package
    ;

  cfg = config.template.tools.yamllint;
  configFile = ".yamllint.yaml";
in
{
  options.template.tools.yamllint = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.yamllint;
    };

    config = mkOption {
      type = json;
      default = { };
    };

    ignore = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".yaml = cfg.config;

    git-hooks.hooks.yamllint = {
      enable = true;
      package = cfg.package;
      name = "yaml: lint";
    };

    template = {
      gitignore = [ configFile ];

      tools.yamllint = {
        config = {
          extends = "default";
          rules = {
            braces = {
              forbid = false;
              min-spaces-inside = 0;
              max-spaces-inside = 0;
              min-spaces-inside-empty = 0;
              max-spaces-inside-empty = 0;
            };
            brackets = {
              forbid = false;
              min-spaces-inside = 0;
              max-spaces-inside = 0;
              min-spaces-inside-empty = 0;
              max-spaces-inside-empty = 0;
            };
            comments = {
              require-starting-space = true;
              ignore-shebangs = true;
              min-spaces-from-content = 1; # for compatibility with prettier
            };
            document-start = "disable";
            line-length = "disable";
          };
          ignore = cfg.ignore;
        };
      };
    };
  };
}
