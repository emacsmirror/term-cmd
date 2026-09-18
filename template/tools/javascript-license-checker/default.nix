{ lib, config, ... }:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.lists) optionals;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr;

  cfg = config.template.tools.javascriptLicenseChecker;

  forbiddenLicenses = {
    "MIT" = [
      "GPL-1.0-only"
      "GPL-1.0-or-later"
      "GPL-2.0-only"
      "GPL-2.0-or-later"
      "GPL-3.0-only"
      "GPL-3.0-or-later"
      "AGPL-1.0-only"
      "AGPL-1.0-or-later"
      "AGPL-3.0-only"
      "AGPL-3.0-or-later"
    ];
    "GPL-3.0-or-later" = [
      "AGPL-1.0-only"
      "AGPL-1.0-or-later"
    ];
  };
in
{
  options.template.tools.javascriptLicenseChecker = {
    enable = mkEnableOption "enable";

    ignorePackages = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    git-hooks.hooks.javascript-license-checker = {
      enable = true;
      name = "javascript: check dependency licenses";
      entry = join " " (
        [
          "${getExe' config.languages.javascript.npm.package "npx"}"
          "license-checker-rseidelsohn"
          "--production"
          "--failOn"
          "'${join ";" forbiddenLicenses."${config.template.project.license}"}'"
        ]
        ++ (optionals (cfg.ignorePackages != [ ]) [
          "--excludePackages"
          "'${join ";" cfg.ignorePackages}'"
        ])
      );
      files = "^(package\\.json|package-lock\\.json)$";
      pass_filenames = false;
    };

    template.languages.javascript.seedDevDependencies = {
      license-checker-rseidelsohn = "5.0.1";
    };
  };
}
