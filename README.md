# ktalk-nix

Nix flake for [Kontur Talk](https://kontur.ru/talk/).
Repackages the official AppImage.

## Quick Start

**Try it without installing:**
```bash
nix run github:blackfan321/ktalk-nix
```

**Install into your profile:**
```bash
nix profile install github:blackfan321/ktalk-nix
```

## Installation

### NixOS Flake

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    ktalk = {
      url = "github:blackfan321/ktalk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ktalk, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      modules = [{ pkgs, ... }: {
        environment.systemPackages = [
          ktalk.packages.${pkgs.stdenv.hostPlatform.system}.ktalk
        ];
      }}];
    };
  };
}
```

### Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.ktalk.packages.${pkgs.stdenv.hostPlatform.system}.ktalk
  ];
}
```

## Platforms

- `x86_64-linux`
- `aarch64-linux`

## Just

Set the default arch (`x86_64` or `arm64`) at the top of `justfile`

| Command | Description |
|---|---|
| `just bump_application` | Bumps application to the latest release for every arch. |
| `just get_latest_appimage_version` | Prints the latest available AppImage version |
| `just pull_appimage <version> [arch]` | Downloads the AppImage for a given version; prints its sha256 |
| `just pull_latest_appimage [arch]` | Downloads the latest available AppImage; prints its sha256 |
| `just cleanup` | Removes downloaded AppImages from the repo root |
| `just prek-install` | Installs the pre-commit hook |
| `just prek-uninstall` | Removes the pre-commit hook |
| `just prek-run` | Runs all checks against all repo files |

## Devshell

Allow [direnv](https://direnv.net/) to activate flake devshell:

```bash
direnv allow
```

You also need [nix-direnv](https://github.com/nix-community/nix-direnv). The shell provides `just`, `rg`, `sed`, `wget2`, and the pre-commit packages.

Or enter the shell directly:

```bash
nix develop
```

## Pre-commit

TBD

## Automated Updates

TBD
