{ lib, config, ... }:
let
  inherit (builtins) lessThan sort;
  inherit (lib) mkOption;
  inherit (lib.strings) join;
  inherit (lib.types) listOf nonEmptyStr;
in
{
  options.template = {
    gitignore = mkOption {
      type = listOf nonEmptyStr;
      default = [ ];
    };
  };

  config = {
    files.".gitignore" = {
      copyMode = "copy";
      text = ''
        # Auto-generated; edit devenv.nix instead

        ${join "\n" (sort lessThan config.template.gitignore)}
      '';
    };

    template.gitignore = [
      "*~"
      ".devenv*"
      "devenv.local.nix"
      "devenv.local.yaml"
      ".direnv"
    ];
  };
}
