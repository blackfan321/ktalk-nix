# ktalk-nix

Nix flake for [Kontur Talk](https://kontur.ru/talk/).
Repackages the official AppImage.

## Quick Start

**Try it without installing:**
```bash
nix run github:blackfan321/ktalk-nix
```

**Install to your profile:**
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

## Justfile

Requires `wget2`.

| Command | Description |
|---|---|
| `just update_application` | Checks for a newer release and bumps `version` and `hash` in `ktalk.nix` |
| `just get_latest_appimage_version` | Prints the latest AppImage version |
| `just pull_appimage <version> [arch]` | Downloads the AppImage for a given version and arch (`x86_64` or `arm64`, default `x86_64`) and prints its sha256 hash |
| `just pull_latest_appimage` | Downloads the latest AppImage and prints its sha256 hash |
| `just cleanup` | Removes downloaded AppImages from the repo root |
| `just prek-install` | Installs the prek git hook |
| `just prek-uninstall` | Removes the prek git hook |
| `just prek-run` | Runs nixfmt, deadnix, and statix on all files |
