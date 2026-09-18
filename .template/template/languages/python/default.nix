{
  pkgs,
  lib,
  templateLib,
  inputs,
  config,
  ...
}:
let
  inherit (builtins) attrNames head readFile;
  inherit (pkgs) runCommandLocal;
  inherit (lib)
    getExe
    getExe'
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists)
    allUnique
    last
    naturalSort
    optionals
    uniqueStrings
    ;
  inherit (lib.strings) join replaceString trim;
  inherit (lib.types)
    attrsOf
    bool
    enum
    listOf
    nonEmptyListOf
    nonEmptyStr
    package
    toml
    ;
  inherit (templateLib.types) relativePath twoComponentVersion;

  cfg = config.template.languages.python;
  hooks = config.git-hooks.hooks;
  python = config.languages.python;
  project = config.template.project;

  internalVersion = "3.14";
  internalDeps = {
    boltons = "==26.1.0";
    frozendict = "==2.4.7";
    packaging = "==26.3";
  };
  internalDevDeps = {
    pyfakefs = "==6.2.0";
    pytest-mock = "==3.15.1";
    pytest-subprocess = "==1.6.0";
    types-boltons = "==26.1.0.20260724";
  };

  latestPython = last (
    naturalSort (attrNames (inputs.nixpkgs-python.packages."${pkgs.stdenv.system}"))
  );

  sortedVersions = naturalSort cfg.versions;

  nixPackagesFrom = names: (ps: map (name: ps."${name}") names);

  buildSystemRequires =
    let
      file = runCommandLocal "buildSystemRequires" { } ''
        ${getExe python.uv.package} init \
          --python=${getExe python.package} \
          --offline \
          --no-cache \
          --name=temp \
          --bare \
          --package \
          --build-backend=uv \
          --vcs=none \
          --author-from=none \
          --no-workspace \
          temp

        ${getExe' pkgs.yq "tomlq"} '."build-system".requires[0]' temp/pyproject.toml |
          ${getExe pkgs.gnused} 's/"//g' >$out
      '';
    in
    trim (readFile file);

  snapshotSource = "/${config.template.dir}/languages/python/ast-grep-snapshot.yml";

  packageSrcDir = "src/${cfg.projectNameUnderscore}";
in
{
  imports = [
    ./pyproject-toml.nix
    ./pytest.nix
    ./updates.nix
  ];

  options.template.languages.python = {
    enable = mkEnableOption "enable";

    versions = mkOption { type = nonEmptyListOf twoComponentVersion; };

    nixPackages = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };

    projectName = mkOption {
      type = nonEmptyStr;
      default = project.nameSlug;
    };

    projectNameUnderscore = mkOption {
      type = nonEmptyStr;
      readOnly = true;
    };

    isPackage = mkOption {
      type = bool;
      default = false;
    };

    seedDependencies = mkOption {
      type = attrsOf nonEmptyStr;
      default = { };
    };

    seedDevDependencies = mkOption {
      type = attrsOf nonEmptyStr;
      default = { };
    };

    exportRequirementsTxt = {
      enable = mkEnableOption "enable";

      includeHashes = mkOption {
        type = bool;
        default = true;
      };
    };

    typeChecker = mkOption {
      type = enum [
        "mypy"
        "ty"
      ];
      default = "ty";
    };

    fileTags = mkOption { type = nonEmptyListOf nonEmptyStr; };

    config = mkOption {
      type = toml;
      default = { };
    };

    package = mkOption {
      type = attrsOf package;
      readOnly = true;
    };

    minVersion = mkOption {
      type = twoComponentVersion;
      readOnly = true;
    };

    maxVersion = mkOption {
      type = twoComponentVersion;
      readOnly = true;
    };

    pytest = {
      enable = mkEnableOption "enable";

      testDir = mkOption {
        type = relativePath;
        default = config.template.testDir;
      };
    };

    internalVersion = mkOption {
      type = twoComponentVersion;
      internal = true;
      readOnly = true;
    };

    internalPython = mkOption {
      type = package;
      internal = true;
      readOnly = true;
    };

    includeInternalDeps = mkOption {
      type = bool;
      default = false;
      internal = true;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = allUnique cfg.versions;
        message = "Python versions must be different; got ${toString cfg.versions}";
      }
      {
        assertion =
          !(cfg.config.project ? dependencies)
          && !(cfg.config.project ? optional-dependencies)
          && !(cfg.config ? dependency-groups);
        message =
          "Python dependencies must not be defined directly in config; "
          + "use seedDependencies and seedDevDependencies instead";
      }
    ];

    languages.python = {
      enable = true;
      package = cfg.package."${cfg.maxVersion}";
      venv.enable = true;
      uv = {
        enable = true;
        sync = {
          enable = true;
          allExtras = true;
          allGroups = true;
        };
      };
      lsp.package = mkIf (cfg.typeChecker == "ty") config.template.tools.ty.package;
    };

    files = {
      "${packageSrcDir}/py.typed" = mkIf cfg.isPackage {
        copyMode = "copy";
        text = "";
      };
      "${packageSrcDir}/__init__.py" = mkIf cfg.isPackage {
        copyMode = "copy";
        text = ''
          __version__ = "${project.version}"
        '';
      };
    };

    git-hooks.hooks = {
      uv-sync = {
        enable = true;
        name = "uv: sync";
        package = python.uv.package;
        entry = "${getExe hooks.uv-sync.package} sync --python=3 --all-extras --all-groups";
        files = "^(pyproject\\.toml|uv\\.lock)$";
        pass_filenames = false;
        priority = 0;
      };

      uv-export = {
        enable = cfg.exportRequirementsTxt.enable;
        name = "uv: export";
        package = python.uv.package;
        entry = join " " (
          [
            "${getExe hooks.uv-export.package}"
            "export"
            "--python=3"
            "--quiet"
            "--output-file=requirements.txt"
            "--all-extras"
            "--no-default-groups"
          ]
          ++ (optionals (!cfg.exportRequirementsTxt.includeHashes) [
            "--no-editable"
            "--no-hashes"
          ])
        );
      };
    };

    scripts.template-latest-python.exec = ''
      cat <<EOF
      Latest available python version: ${latestPython}
      (Run 'devenv update' to make more versions available)
      EOF
    '';

    cachix.pull = [ "nixpkgs-python" ];

    template = {
      languages.python = {
        projectNameUnderscore = replaceString "-" "_" cfg.projectName;

        package = genAttrs cfg.versions (
          version:
          inputs.nixpkgs-python.packages."${pkgs.stdenv.system}"."${version}".withPackages (
            nixPackagesFrom (uniqueStrings cfg.nixPackages)
          )
        );

        minVersion = head sortedVersions;
        maxVersion = last sortedVersions;

        fileTags = [
          "python"
          "pyi"
        ];

        config = {
          project = {
            name = cfg.projectName;
            version = project.version;
            requires-python = ">=${cfg.minVersion}";
            readme = project.readmeFile.file;
            license = project.license;
            license-files = [ project.licenseFile.file ];
          };
          build-system = {
            requires = [ buildSystemRequires ];
            build-backend = "uv_build";
          };
          tool = {
            uv = {
              package = cfg.isPackage;
              exclude-newer = "${toString config.template.cooldownDays} days";
            };
          };
        };

        internalVersion = internalVersion;
        internalPython =
          inputs.nixpkgs-python.packages."${pkgs.stdenv.system}"."${cfg.internalVersion}".withPackages
            (nixPackagesFrom (attrNames internalDeps));
        seedDependencies = mkIf cfg.includeInternalDeps internalDeps;
        seedDevDependencies = mkIf cfg.includeInternalDeps internalDevDeps;
      };

      tools = {
        mypy.enable = mkDefault (cfg.typeChecker == "mypy");
        ty.enable = mkDefault (cfg.typeChecker == "ty");
        ruff.enable = mkDefault true;
        pythonLicenseChecker.enable = mkDefault true;
        shebangChecker.allowShebangs = [ "/usr/bin/env python3" ];

        astGrep = {
          enable = mkDefault true;
          rules.special-method-raises-notimplementederror = {
            rule = ./ast-grep.yml;
            test = ./ast-grep-test.yml;
            snapshot = ./ast-grep-snapshot.yml;
          };
        };

        # These are ignoring the snapshot source file in the template dir, not
        # the installed snapshot - that's handled by ast-grep
        prettier.ignore = [ snapshotSource ];
        yamllint.ignore = [ snapshotSource ];
      };

      project.readme.badges = mkIf cfg.isPackage [
        "![python](https://img.shields.io/badge/python-${join "_%7C_" sortedVersions}-blue)"
      ];

      gitignore.ignore = [ "__pycache__/" ];

      clean.deepCleanCommands = [
        "find . -depth '(' -type d -name '__pycache__' ')' -exec rm -r '{}' ';'"
      ];

      preCommit.exclude = [ "^uv\\.lock$" ];
    };
  };
}
