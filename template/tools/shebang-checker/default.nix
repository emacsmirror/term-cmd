{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) readFile replaceStrings;
  inherit (pkgs) writeShellApplication;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.tools.shebangChecker;

  script = writeShellApplication {
    name = "shebang-checker";
    text = replaceStrings [ "@shebangs@" ] [ (join "|" cfg.allowShebangs) ] (
      readFile ./shebang-checker.sh
    );
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gnugrep
    ];
  };
in
{
  options.template.tools.shebangChecker = {
    enable = mkEnableOption "enable";

    allowShebangs = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    git-hooks.hooks.shebang-checker = {
      enable = true;
      name = "general: check shebangs";
      entry = "${getExe script}";
      types = [ "text" ];
    };
  };
}
