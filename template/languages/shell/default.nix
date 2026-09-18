{
  pkgsUnstable,
  lib,
  templateLib,
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
  inherit (templateLib.types) relativePath;

  cfg = config.template.languages.shell;
in
{
  imports = [ ./bats.nix ];

  options.template.languages.shell = {
    enable = mkEnableOption "enable";

    bats = {
      enable = mkEnableOption "enable";

      package = mkOption {
        type = package;
        # TODO: switch to pkgs once this commit is in:
        # https://github.com/NixOS/nixpkgs/commit/bd41942fe66b0fe0ee02ff6de054b34839c250e0
        default = pkgsUnstable.bats.withLibraries (
          p: with p; [
            bats-assert
            bats-support
          ]
        );
      };

      testDir = mkOption {
        type = relativePath;
        default = config.template.testDir;
      };
    };
  };

  config = mkIf cfg.enable {
    languages.shell.enable = true; # includes language server

    template.tools = {
      shellcheck.enable = mkDefault true;
      shfmt.enable = mkDefault true;
      shebangChecker.allowShebangs = [
        # /bin/bash doesn't work on NixOS, so only the following is allowed
        "/usr/bin/env bash"
      ];
    };
  };
}
