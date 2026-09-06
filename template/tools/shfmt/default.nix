{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) package;

  cfg = config.template.tools.shfmt;
in
{
  options.template.tools.shfmt = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.shfmt;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks.shfmt = {
      enable = true;
      name = "shell: format";
      package = cfg.package;
      settings = {
        language-dialect = null;
        simplify = false;
      };
    };

    template.tools.editorconfig = {
      enable = mkDefault true;
      config = ''
        # Special match syntax for shfmt
        [[shell]]
        indent_style = space
        indent_size = 4
      '';
    };
  };
}
