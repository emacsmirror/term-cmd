# Project Template

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

## AI Policy

Use of generative AI is not permitted in this project.
