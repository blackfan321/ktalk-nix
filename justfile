program_name := "ktalk"
package_file := "ktalk.nix"
default_arch := "x86_64"

set quiet := true
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

[private]
default:
    @just --choose

[group('app')]
pull_appimage version arch=default_arch:
  wget2 --force-progress -O "ktalk-{{version}}-{{arch}}.AppImage" \
    "https://st.ktalk.host/ktalk-app/linux/ktalk{{version}}{{arch}}.AppImage" >&2

  nix hash file "ktalk-{{version}}-{{arch}}.AppImage"

[group('app')]
get_latest_appimage_version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/linux" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk([0-9]+\.[0-9]+\.[0-9]+)x86_64\.AppImage' -r '$1' \
    | head -n1

[group('app')]
pull_latest_appimage arch=default_arch:
  just pull_appimage "$(just get_latest_appimage_version)" {{arch}}

[group('app')]
bump_application:
  #!/usr/bin/env bash
  set -euo pipefail

  echo -e "Checking for a new {{program_name}} release\n" >&2

  OLD_VERSION="$(rg -m1 -o 'version = "[^"]+"' "{{package_file}}" | sed 's/version = "\(.*\)"/\1/')"
  NEW_VERSION="$(just get_latest_appimage_version)"

  if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
    echo -e "{{program_name}} is already up to date ($NEW_VERSION)" >&2
    exit 0
  fi

  HASH_X86="$(just pull_appimage "$NEW_VERSION" x86_64)"
  HASH_ARM="$(just pull_appimage "$NEW_VERSION" arm64)"

  echo -e "\nBumping {{program_name}} to $NEW_VERSION\n" >&2
  sed -i \
    -e 's/version = "[^"]*"/version = "'"$NEW_VERSION"'"/' \
    -e '/x86_64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_X86"'"|' \
    -e '/aarch64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_ARM"'"|' \
    {{package_file}}

  just cleanup
  echo -e "{{program_name}} successfully bumped from $OLD_VERSION to $NEW_VERSION" >&2

[group('app')]
cleanup:
  rm -f -- *.AppImage

[group('prek')]
prek-install:
  nix develop -c prek install

[group('prek')]
prek-uninstall:
  nix develop -c prek uninstall

[group('prek')]
prek-run:
  nix develop -c prek run --all-files
