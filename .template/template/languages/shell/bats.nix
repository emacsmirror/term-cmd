{ lib, config, ... }:
let
  inherit (lib) getExe mkIf;
  inherit (lib.strings) escapeShellArg join;

  cfg = config.template.languages.shell;
  hooks = config.git-hooks.hooks;

  batsArgs =
    package: tag:
    join " " [
      (getExe package)
      "--pretty"
      "--allow-empty-suite"
      "--filter-tags"
      tag
      "-r"
      (escapeShellArg cfg.bats.testDir)
    ];
in
{
  config = mkIf (cfg.enable && cfg.bats.enable) {
    packages = [ cfg.bats.package ];

    scripts.template-new-test-bats.exec = ''
      cat ${./test-template.bats}
    '';

    git-hooks.hooks.bats-fast = {
      enable = true;
      package = cfg.bats.package;
      name = "shell: fast tests";
      entry = batsArgs hooks.bats-fast.package "!slow";
      pass_filenames = false;
    };

    enterTest = ''
      ${batsArgs cfg.bats.package "slow"}
    '';
  };
}
