program_name := "ktalk"
package_file := "ktalk.nix"
default_arch := "x86_64"

set quiet := true
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

[private]
default:
    @just --choose

pull_appimage version arch=default_arch:
  wget2 --force-progress -O "ktalk-{{version}}-{{arch}}.AppImage" \
    "https://st.ktalk.host/ktalk-app/linux/ktalk{{version}}{{arch}}.AppImage" >&2

  nix hash file "ktalk-{{version}}-{{arch}}.AppImage"

get_latest_appimage_version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/linux" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk([0-9]+\.[0-9]+\.[0-9]+)x86_64\.AppImage' -r '$1' \
    | head -n1

pull_latest_appimage arch=default_arch:
  just pull_appimage "$(just get_latest_appimage_version)" {{arch}}

pull_dmg version:
  wget2 --force-progress -O "ktalk-{{version}}-mac.dmg" \
    "https://st.ktalk.host/ktalk-app/mac/ktalk.{{version}}-mac.dmg" >&2

  nix hash file "ktalk-{{version}}-mac.dmg"

get_latest_dmg_version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/mac" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk\.([0-9]+\.[0-9]+\.[0-9]+)-mac\.dmg' -r '$1' \
    | head -n1

bump_application:
  #!/usr/bin/env bash
  set -euo pipefail

  echo -e "Checking for a new {{program_name}} release\n" >&2

  read_version() {
    sed -n '/^  '"$1"' = {/,/^  };/ s/^    version = "\([^"]*\)".*/\1/p' "{{package_file}}"
  }

  OLD_LINUX="$(read_version linuxSources)"
  OLD_DARWIN="$(read_version darwinSources)"
  NEW_LINUX="$(just get_latest_appimage_version)"
  NEW_DARWIN="$(just get_latest_dmg_version)"

  LINUX_CHANGED=0
  DARWIN_CHANGED=0
  [[ "$OLD_LINUX" != "$NEW_LINUX" ]] && LINUX_CHANGED=1
  [[ "$OLD_DARWIN" != "$NEW_DARWIN" ]] && DARWIN_CHANGED=1

  if [[ "$LINUX_CHANGED" == 0 && "$DARWIN_CHANGED" == 0 ]]; then
    echo -e "{{program_name}} is already up to date (linux $NEW_LINUX, darwin $NEW_DARWIN)" >&2
    exit 0
  fi

  summary=""
  if [[ "$LINUX_CHANGED" == 1 ]]; then
    HASH_X86="$(just pull_appimage "$NEW_LINUX" x86_64)"
    HASH_ARM="$(just pull_appimage "$NEW_LINUX" arm64)"
    summary="linux $OLD_LINUX -> $NEW_LINUX"
  fi
  if [[ "$DARWIN_CHANGED" == 1 ]]; then
    HASH_DARWIN="$(just pull_dmg "$NEW_DARWIN")"
    if [[ -n "$summary" ]]; then
      summary+=", "
    fi
    summary+="darwin $OLD_DARWIN -> $NEW_DARWIN"
  fi

  echo -e "\nBumping {{program_name}} ($summary)\n" >&2

  sed_args=()
  if [[ "$LINUX_CHANGED" == 1 ]]; then
    sed_args+=(
      -e '/^  linuxSources = {/,/^  };/ s/version = "[^"]*"/version = "'"$NEW_LINUX"'"/'
      -e '/x86_64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_X86"'"|'
      -e '/aarch64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_ARM"'"|'
    )
  fi
  if [[ "$DARWIN_CHANGED" == 1 ]]; then
    sed_args+=(
      -e '/^  darwinSources = {/,/^  };/ s/version = "[^"]*"/version = "'"$NEW_DARWIN"'"/'
      -e '/aarch64-darwin = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_DARWIN"'"/'
    )
  fi
  sed -i "${sed_args[@]}" {{package_file}}

  just cleanup
  echo -e "{{program_name}} successfully bumped ($summary)" >&2

cleanup:
  rm -f -- *.AppImage *.dmg

[group('prek')]
prek-install:
  nix develop -c prek install

[group('prek')]
prek-uninstall:
  nix develop -c prek uninstall

[group('prek')]
prek-run:
  nix develop -c prek run --all-files
