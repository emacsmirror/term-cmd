{ lib, config, ... }:
let
  inherit (lib) getExe mkIf mkMerge;
  inherit (lib.attrsets) genAttrs' nameValuePair;
  inherit (lib.lists) optional;
  inherit (lib.strings)
    concatMapStringsSep
    escapeShellArg
    join
    optionalString
    ;

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
        (getExe cfg.package."${version}")
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

    git-hooks.hooks = genAttrs' cfg.versions (
      version:
      nameValuePair "pytest-fast-${version}" {
        enable = true;
        name = "python ${version}: fast tests";
        entry = pytestArgs version "not slow";
        pass_filenames = false;
      }
    );

    enterTest = concatMapStringsSep "\n" (version: pytestArgs version "slow") cfg.versions;

    template = {
      languages.python = {
        config.tool = mkMerge [
          {
            coverage.run.omit = [ "/nix/store/*" ];
            pytest = {
              addopts = [
                "--cov${optionalString cfg.isPackage "=${project.nameSlugUnderscore}"}"
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
