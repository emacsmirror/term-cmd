{
  pkgs,
  lib,
  templateLib,
  config,
  ...
}:
let
  inherit (pkgs.writers) writeYAML;
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.types) json nonEmptyStr;
  inherit (templateLib) formatWithPrettier;

  cfg = config.template.ci.githubActions;
  filename = "ci.yml";
  workflow = "workflows/${filename}";
  configFile = ".github/${workflow}";
  url = "https://github.com/${cfg.owner}/${cfg.repo}";
in
{
  options.template.ci.githubActions = {
    enable = mkEnableOption "enable";

    owner = mkOption { type = nonEmptyStr; };

    repo = mkOption { type = nonEmptyStr; };

    config = mkOption {
      type = json;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    files = {
      "${configFile}" = {
        copyMode = "copy";
        source = "${formatWithPrettier config writeYAML filename cfg.config}";
      };
    };

    template = {
      ci.githubActions.config = {
        name = "CI";
        run-name = "CI \${{ github.ref_type }} \${{ github.ref_name }}: '\${{ github.event.head_commit.message }}'";
        on = [ "push" ];
        permissions = { };
        concurrency = {
          group = "\${{ github.workflow }}-\${{ github.ref }}";
          cancel-in-progress = true;
        };
        jobs = {
          ci = {
            name = "CI";
            runs-on = "ubuntu-24.04";
            steps = [
              {
                name = "Checkout";
                uses = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"; # v7.0.1
                "with" = {
                  persist-credentials = false;
                };
              }
              {
                name = "Install nix";
                uses = "cachix/install-nix-action@13d8dd58da0234aa297dedd986986ccb8e7f3e24"; # v31.11.1
              }
              {
                name = "Configure caches";
                uses = "cachix/cachix-action@5f2d7c5294214f71b873db4b969586b980625e71"; # v17
                "with" = {
                  name = "devenv";
                  extraPullNames = "nixpkgs-python";
                };
              }
              {
                name = "Install devenv";
                run = "nix profile add nixpkgs#devenv";
              }
              {
                name = "Run tests";
                env = {
                  TERM = "dumb";
                };
                run = "devenv test";
              }
            ];
          };
        };
      };

      tools = {
        actionlint.enable = true;
        zizmor.enable = true;
      };

      languages.yaml.enable = mkDefault true;

      project.readme.badges = [
        "[![CI](${url}/actions/${workflow}/badge.svg)](${url}/actions/${workflow})"
      ];
    };
  };
}
