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
  inherit (lib.attrsets) genAttrs' nameValuePair;
  inherit (lib.lists) optional;
  inherit (lib.strings) replaceString;
  inherit (lib.types) package toml;

  cfg = config.template.tools.ruff;
  hooks = config.git-hooks.hooks;
  python = config.template.languages.python;

  targetVersion = version: "py${replaceString "." "" version}";
in
{
  options.template.tools.ruff = {
    enable = mkEnableOption "enable";

    package = mkOption {
      type = package;
      default = pkgs.ruff;
    };

    config = mkOption {
      type = toml;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    git-hooks.hooks = {
      ruff-format = {
        enable = true;
        package = cfg.package;
        name = "python: format";
        entry = "${getExe hooks.ruff-format.package} format --force-exclude";
        types = [ ];
        types_or = python.fileTags;
        require_serial = true;
      };
    }
    // (genAttrs' python.versions (
      version:
      let
        id = "ruff-check-${version}";
      in
      nameValuePair id {
        enable = true;
        package = cfg.package;
        name = "python ${version}: lint";
        entry = "${getExe hooks."${id}".package} check --force-exclude --target-version=${targetVersion version} --fix";
        types_or = python.fileTags;
        require_serial = true;
      }
    ));

    template = {
      languages.python.config.tool.ruff = cfg.config;

      tools.ruff.config = {
        namespace-packages = [ ".template" ];
        target-version = targetVersion python.maxVersion;
        lint = {
          select = [ "ALL" ];
          ignore = [
            "C90" # mccabe:*
            # spellchecker: disable-next-line
            "CPY" # flake8-copyright:*
            "D1" # pydocstyle:undocumented-*
            "E741" # pycodestyle:ambiguous-variable-name
            "EM" # flake8-errmsg:*
            "FIX" # flake8-fixme:*
            "PLR09" # refactor:too-many-*
            "PT011" # flake8-pytest-style:pytest-raises-too-broad
            "PTH" # flake8-use-pathlib:*
            "PYI025" # flake8-pyi:unaliased-collections-abc-set-import
            "S603" # flake8-bandit:subprocess-without-shell-equals-true
            "S607" # flake8-bandit:start-process-with-partial-path
            "T20" # flake8-print:*
            "TD" # flake8-todos:*
            "TRY003" # tryceratops:raise-vanilla-args
            "TRY301" # tryceratops:raise-within-try
          ]
          ++ (optional (!python.isPackage) "INP001" # flake8-no-pep420:implicit-namespace-package
          );
        };
      };

      clean.deepCleanCommands = [ "rm -rf .ruff_cache" ];
    };
  };
}
