{
  pkgs,
  lib,
  templateLib,
  inputs,
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
  inherit (templateLib) localRelPath;

  cfg = config.template.languages.shell;

  # TODO: remove this once https://github.com/NixOS/nixpkgs/pull/559030 is merged upstream
  pkgs-bats = import inputs.nixpkgs-bats { system = pkgs.stdenv.system; };
in
{
  imports = [ ./bats.nix ];

  options.template.languages.shell = {
    enable = mkEnableOption "enable";

    bats = {
      enable = mkEnableOption "enable";

      package = mkOption {
        type = package;
        default = pkgs-bats.bats.withLibraries (
          p: with p; [
            bats-assert
            bats-support
          ]
        );
      };

      testDir = mkOption {
        type = localRelPath;
        default = config.template.testDir;
      };
    };
  };

  config = mkIf cfg.enable {
    languages.shell.enable = true; # includes language server

    template.tools = {
      shellcheck.enable = mkDefault true;
      shfmt.enable = mkDefault true;
      shebangChecker.allowedShebangs = [
        # /bin/bash doesn't work on NixOS, so only the following is allowed
        "/usr/bin/env bash"
      ];
    };
  };
}
