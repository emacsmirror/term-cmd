{ config, ... }:
let
  forge = "https://codeberg.org";
  owner = "calliecameron";
  repo = "project-template";
in
{
  template = {
    dir = "template";
    templateDev = true;

    project = {
      name = "Project Template";
      author = "Callie Cameron";
      version = "0.2.2";
      copyrightYears = {
        start = "2025";
        end = "2026";
      };
      readme.text = ''
        A [Devenv](https://devenv.sh/) template for multi-language projects.

        This is mainly intended for personal use – it includes the languages and tools that I use.

        ## Installation

        Run `./install.sh` in your project directory.

        ## Usage

        Edit `devenv.nix` to enable the desired languages, e.g.:

        ```nix
        { ... }: {
          template = {
            languages = {
              shell.enable = true;
              python = {
                enable = true;
                versions = [
                  "3.14"
                ];
              };
            };
          };
        }
        ```

        ## Updating

        Run `template-update-template`.
      '';
    };

    languages = {
      css.enable = true;
      html.enable = true;
      javascript.enable = true;
      json.enable = true;
      markdown.enable = true;
      nix.enable = true;
      protobuf.enable = true;
      python = {
        enable = true;
        versions = [ config.template.languages.python.internalVersion ];
        pytest.enable = true;
      };
      shell = {
        enable = true;
        bats.enable = true;
      };
      toml.enable = true;
      yaml.enable = true;
    };
  };

  files = {
    "${config.template.dir}/template-repo" = {
      copyMode = "copy";
      text = "${forge}/${owner}/${repo}\n";
    };
  };
}
