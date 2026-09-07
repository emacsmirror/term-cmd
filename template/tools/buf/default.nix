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
  inherit (lib.types) json package;

  cfg = config.template.tools.buf;
  hooks = config.git-hooks.hooks;
  configFile = "buf.yaml";
in
{
  options.template.tools.buf = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.buf;
    };

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    files."${configFile}".yaml = cfg.config;

    git-hooks.hooks = {
      buf-lint = {
        enable = true;
        name = "protobuf: lint";
        package = cfg.package;
        entry = "${getExe hooks.buf-format.package} lint";
        types = [ "proto" ];
      };
      buf-format = {
        enable = true;
        name = "protobuf: format";
        package = cfg.package;
        entry = "${getExe hooks.buf-format.package} format --write";
        types = [ "proto" ];
      };
    };

    template = {
      tools.buf.config = {
        version = "v2";
        lint = {
          use = [ "BASIC" ];
        };
      };

      gitignore = [ configFile ];
    };
  };
}
