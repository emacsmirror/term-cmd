{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (builtins) attrNames readFile replaceStrings;
  inherit (pkgs) runCommandLocal;
  inherit (lib)
    getExe
    mkAfter
    mkBefore
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
  inherit (lib.strings)
    escapeShellArg
    join
    optionalString
    trim
    ;
  inherit (lib.types)
    bool
    enum
    lines
    listOf
    nonEmptyStr
    ;
  inherit (templateLib.formatters) formatMarkdown;
  inherit (templateLib.types) relativePath threeComponentVersion year;

  cfg = config.template.project;

  licenses =
    let
      start = cfg.copyrightYears.start;
      end = cfg.copyrightYears.end;
      date = if start == end then start else "${start}-${end}";
    in
    {
      "MIT" = {
        text = replaceStrings [ "@date@" "@author@" ] [ date cfg.author ] (readFile ./mit-license.txt);
        readmeText = null;
      };
      "GPL-3.0-or-later" = {
        text = readFile ./gpl-license.txt;
        readmeText = ''
          ## License

          Copyright (C) ${date} ${cfg.author}

          This program is free software: you can redistribute it and/or modify it under
          the terms of the GNU General Public License as published by the Free Software
          Foundation, either version 3 of the License, or (at your option) any later
          version.

          This program is distributed in the hope that it will be useful, but WITHOUT ANY
          WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
          PARTICULAR PURPOSE. See the GNU General Public License for more details.

          You should have received a copy of the GNU General Public License along with
          this program. If not, see <https://www.gnu.org/licenses/>.
        '';
      };
    };

  license = licenses."${cfg.license}";

  developmentText = ''
    ## Development

    Uses [Devenv](https://devenv.sh/) with [this template](${config.template.templateRepo}).

    With Devenv installed, run `devenv shell` in the project directory, or if using
    [direnv integration](https://devenv.sh/integrations/direnv/), run `direnv allow`.
  '';

  aiPolicyText = ''
    ## AI Policy

    Use of generative AI is not permitted in this project.
  '';

  slugify =
    name:
    let
      file = runCommandLocal "slugify" { } ''
        ${getExe config.template.languages.python.internalPython} ${./slugify.py} ${escapeShellArg name} >$out
      '';
    in
    trim (readFile file);
in
{
  options.template.project = {
    name = mkOption { type = nonEmptyStr; };

    nameSlug = mkOption {
      type = nonEmptyStr;
      default = slugify cfg.name;
    };

    author = mkOption { type = nonEmptyStr; };

    version = mkOption { type = threeComponentVersion; };

    license = mkOption {
      type = enum (attrNames licenses);
      default = "MIT";
    };

    copyrightYears = {
      start = mkOption { type = year; };

      end = mkOption { type = year; };
    };

    readme = {
      text = mkOption { type = lines; };

      badges = mkOption {
        type = listOf nonEmptyStr;
        default = [ ];
      };

      sections = {
        development = mkOption {
          type = bool;
          default = true;
        };

        aiPolicy = mkOption {
          type = bool;
          default = true;
        };

        license = mkOption {
          type = bool;
          default = true;
        };
      };
    };

    licenseFile = {
      enable = mkEnableOption "enable";

      file = mkOption {
        type = relativePath;
        internal = true;
        readOnly = true;
      };
    };

    readmeFile = {
      enable = mkEnableOption "enable";

      file = mkOption {
        type = relativePath;
        internal = true;
        readOnly = true;
      };
    };

    versionFile = mkOption {
      type = relativePath;
      internal = true;
      readOnly = true;
    };
  };

  config = {
    name = cfg.name;

    files = {
      "${cfg.licenseFile.file}" = mkIf cfg.licenseFile.enable {
        copyMode = "copy";
        text = license.text;
      };
      "${cfg.readmeFile.file}" = mkIf cfg.readmeFile.enable {
        copyMode = "copy";
        source = formatMarkdown {
          inherit config;
          filename = cfg.readmeFile.file;
          text = cfg.readme.text;
        };
      };
      "${cfg.versionFile}" = {
        copyMode = "copy";
        text = "${cfg.version}\n";
      };
    };

    template = {
      project = {
        licenseFile.file = "LICENSE";
        readmeFile.file = "README.md";
        versionFile = ".version";

        readme = {
          text = mkMerge [
            (mkBefore (
              ''
                # ${cfg.name}
              ''
              + (optionalString (cfg.readme.badges != [ ]) "\n${join "\n" cfg.readme.badges}\n")
            ))
            (mkAfter (
              (optionalString cfg.readme.sections.development developmentText)
              + (optionalString cfg.readme.sections.aiPolicy aiPolicyText)
              + (optionalString (cfg.readme.sections.license && license.readmeText != null) license.readmeText)
            ))
          ];
        };
      };

      languages.markdown.enable = mkDefault true;
    };
  };
}
