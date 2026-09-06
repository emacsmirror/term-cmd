{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (builtins) attrNames readFile replaceStrings;
  inherit (pkgs) runCommandLocal writeText;
  inherit (lib)
    getExe
    mkAfter
    mkBefore
    mkDefault
    mkMerge
    mkOption
    ;
  inherit (lib.strings)
    escapeShellArg
    join
    optionalString
    replaceString
    trim
    ;
  inherit (lib.types)
    enum
    lines
    listOf
    nonEmptyStr
    strMatching
    ;
  inherit (templateLib) formatWithPrettier;

  cfg = config.template.project;
  semVer = strMatching "[0-9]+\.[0-9]+\.[0-9]";
  year = strMatching "[1-9][0-9][0-9][0-9]";

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

  slugify =
    name:
    let
      file = runCommandLocal "slugify" { } ''
        ${getExe config.template.languages.python.internalPython} ${./slugify.py} ${escapeShellArg name} >$out
      '';
    in
    trim (readFile "${file}");
in
{
  options.template.project = {
    name = mkOption { type = nonEmptyStr; };

    nameSlug = mkOption {
      type = nonEmptyStr;
      default = slugify cfg.name;
    };

    nameSlugUnderscore = mkOption {
      type = nonEmptyStr;
      readOnly = true;
    };

    author = mkOption { type = nonEmptyStr; };

    version = mkOption { type = semVer; };

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
    };

    versionFile = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };

    licenseFile = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };

    readmeFile = mkOption {
      type = nonEmptyStr;
      internal = true;
      readOnly = true;
    };
  };

  config = {
    name = cfg.name;

    files = {
      "${cfg.licenseFile}" = {
        copyMode = "copy";
        text = license.text;
      };
      "${cfg.versionFile}" = {
        copyMode = "copy";
        text = "${cfg.version}\n";
      };
      "${cfg.readmeFile}" = {
        copyMode = "copy";
        source = "${formatWithPrettier config writeText cfg.readmeFile cfg.readme.text}";
      };
    };

    template = {
      project = {
        nameSlugUnderscore = replaceString "-" "_" cfg.nameSlug;
        versionFile = ".version";
        licenseFile = "LICENSE";
        readmeFile = "README.md";

        readme.text = mkMerge [
          (mkBefore (
            ''
              # ${cfg.name}
            ''
            + (optionalString (cfg.readme.badges != [ ]) "\n${join "\n" cfg.readme.badges}\n")
          ))
          (mkAfter (
            ''
              ## AI Policy

              Use of generative AI is not permitted in this project.
            ''
            + (optionalString (license.readmeText != null) license.readmeText)
          ))
        ];
      };

      languages.markdown.enable = mkDefault true;
    };
  };
}
