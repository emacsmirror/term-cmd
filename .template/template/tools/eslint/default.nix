{ lib, config, ... }:
let
  inherit (lib) getExe' mkEnableOption mkIf;

  cfg = config.template.tools.eslint;
in
{
  options.template.tools.eslint = {
    enable = mkEnableOption "enable";
  };

  config = mkIf cfg.enable {
    files = {
      "eslint.config.mjs" = {
        copyMode = "copy";
        text = ''
          import js from "@eslint/js";
          import globals from "globals";
          import eslintConfigPrettier from "eslint-config-prettier/flat";
          import { defineConfig } from "eslint/config";
          import { includeIgnoreFile } from "@eslint/compat";
          import { fileURLToPath } from "node:url";

          const gitignorePath = fileURLToPath(new URL(".gitignore", import.meta.url));

          export default defineConfig([
            includeIgnoreFile(gitignorePath),
            {
              files: ["**/*.{js,mjs,cjs}"],
              plugins: { js },
              extends: ["js/recommended"],
              languageOptions: {
                globals: {
                  ...globals.browser,
                  ...globals.jquery,
                },
              },
              linterOptions: {
                reportUnusedDisableDirectives: "error",
                reportUnusedInlineConfigs: "error",
              },
            },
            eslintConfigPrettier,
          ]);
        '';
      };
    };

    git-hooks.hooks.eslint = {
      enable = true;
      name = "javascript: lint";
      entry = "${getExe' config.languages.javascript.npm.package "npx"} eslint --fix";
      files = "";
      types = [ "javascript" ];
    };

    template = {
      languages.javascript.seedDevDependencies = {
        "@eslint/compat" = "2.1.0";
        "@eslint/js" = "10.0.1";
        eslint = "10.9.0";
        eslint-config-prettier = "10.1.8";
        globals = "17.11.0";
      };
    };
  };
}
