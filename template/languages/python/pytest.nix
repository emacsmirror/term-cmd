{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) getExe mkIf mkMerge;
  inherit (lib.lists) optional;
  inherit (lib.strings) escapeShellArg join;
  inherit (lib.versions) majorMinor;

  cfg = config.template.languages.python;
  project = config.template.project;

  pytestArgs =
    version: tag:
    join " " (
      [
        (getExe config.languages.python.uv.package)
        "run"
      ]
      ++ (optional (version != cfg.maxVersion) "--isolated")
      ++ [
        "--python"
        (getExe inputs.nixpkgs-python.packages."${pkgs.stdenv.system}"."${version}")
        "pytest"
        "-m"
        (escapeShellArg tag)
        (escapeShellArg cfg.pytest.testDir)
      ]
    );
in
{
  config = mkIf (cfg.enable && cfg.pytest.enable) {
    files = {
      "${cfg.pytest.testDir}/__init__.py" = {
        copyMode = "copy";
        text = "";
      };
    };

    scripts.template-new-test-pytest.exec = ''
      cat ${./test-template.py}
    '';

    git-hooks.hooks = mkMerge (
      map (
        rawVersion:
        let
          version = majorMinor rawVersion;
          id = "pytest-fast-${version}";
        in
        {
          "${id}" = {
            enable = true;
            name = "python ${version}: fast tests";
            entry = pytestArgs rawVersion "not slow";
            pass_filenames = false;
          };
        }
      ) cfg.versions
    );

    enterTest = join "\n" (map (version: pytestArgs version "slow") cfg.versions);

    template = {
      languages.python = {
        config.tool = mkMerge [
          {
            coverage.run.omit = [ "/nix/store/*" ];
            pytest = {
              addopts = [
                "--cov${if cfg.isPackage then "=${project.nameSlugUnderscore}" else ""}"
                "--cov-report=term-missing"
                "--strict-markers"
                "--suppress-no-test-exit-code"
              ];
              markers = [ "slow" ];
            };
          }
          (mkIf (!cfg.isPackage) {
            coverage.run.omit = [ "${cfg.pytest.testDir}/*" ];
            pytest.pythonpath = [ "." ];
          })
        ];

        seedDevDependencies = {
          pytest = "==9.1.1";
          pytest-cov = "==7.1.0";
          pytest-custom_exit_code = "==0.3.0";
        };
      };

      gitignore = [ ".coverage" ];

      clean.deepCleanCommands = [ "rm -rf .pytest_cache .coverage" ];
    };
  };
}
