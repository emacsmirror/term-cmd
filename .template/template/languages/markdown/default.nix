{ lib, config, ... }:
let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.template.languages.markdown;
in
{
  options.template.languages.markdown = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    # No language server for markdown

    template.tools = {
      prettier.enable = mkDefault true;
      markdownlint.enable = mkDefault true;
    };
  };
}
