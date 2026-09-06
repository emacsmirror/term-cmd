{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (pkgs) writeShellScript;
  inherit (lib) getExe mkEnableOption mkIf;

  cfg = config.template.tools.pythonLicenseChecker;

  wrapper = writeShellScript "licensecheck-wrapper" ''
    ${getExe config.languages.python.uv.package} run licensecheck --zero --requirements-paths pyproject.toml
    EXIT_CODE="$?"
    if [ "$EXIT_CODE" = '3' ]; then
      # Exits 3 when no dependencies specified
      EXIT_CODE='0'
    fi
    exit "$EXIT_CODE"
  '';
in
{
  options.template.tools.pythonLicenseChecker = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    git-hooks.hooks.python-license-checker = {
      enable = true;
      name = "python: check dependency licenses";
      entry = "${wrapper}";
      files = "^(pyproject\\.toml|uv\\.lock)$";
      pass_filenames = false;
    };

    template.languages.python.seedDevDependencies = {
      licensecheck = "==2026.0.8";
    };
  };
}
