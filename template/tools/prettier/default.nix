{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) lessThan sort;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr package;

  cfg = config.template.tools.prettier;
  hooks = config.git-hooks.hooks;
  ignoreFile = ".prettierignore";
in
{
  options.template.tools.prettier = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.prettier;
    };

    ignore = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    formatCommand = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${ignoreFile}".text = join "\n" (sort lessThan cfg.ignore);

    git-hooks.hooks.prettier = {
      enable = true;
      name = "general: prettier";
      package = cfg.package;
      entry = cfg.formatCommand;
    };

    template = {
      gitignore = [ ignoreFile ];

      tools.prettier.formatCommand = "${getExe hooks.prettier.package} --write --ignore-unknown";
    };
  };
}
