{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) nonEmptyStr package;

  cfg = config.template.tools.tombi;
  hooks = config.git-hooks.hooks;
in
{
  options.template.tools.tombi = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.tombi;
    };

    formatCommand = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks = {
      tombi-lint = {
        enable = true;
        name = "toml: lint";
        package = cfg.package;
        entry = "${getExe hooks.tombi-lint.package} lint";
        types_or = [ "toml" ];
      };
      tombi-format = {
        enable = true;
        name = "toml: format";
        package = cfg.package;
        entry = cfg.formatCommand;
        types_or = [ "toml" ];
      };
    };

    template.tools.tombi.formatCommand = "${getExe hooks.tombi-format.package} format";
  };
}
