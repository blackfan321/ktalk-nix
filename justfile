program_name := "ktalk"
package_file := "ktalk.nix"
readme_file := "README.md"
default_arch := "x86_64"

set quiet := true
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

[private]
default:
    @just --choose

[group('linux')]
pull-appimage version arch=default_arch:
  wget2 --force-progress -O "ktalk-{{version}}-{{arch}}.AppImage" \
    "https://st.ktalk.host/ktalk-app/linux/ktalk{{version}}{{arch}}.AppImage" >&2

  nix hash file "ktalk-{{version}}-{{arch}}.AppImage"

[group('linux')]
get-latest-appimage-version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/linux" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk([0-9]+\.[0-9]+\.[0-9]+)x86_64\.AppImage' -r '$1' \
    | head -n1

[group('linux')]
pull-latest-appimage arch=default_arch:
  just pull-appimage "$(just get-latest-appimage-version)" {{arch}}

[group('macos')]
pull-dmg version:
  wget2 --force-progress -O "ktalk-{{version}}-mac.dmg" \
    "https://st.ktalk.host/ktalk-app/mac/ktalk.{{version}}-mac.dmg" >&2

  nix hash file "ktalk-{{version}}-mac.dmg"

[group('macos')]
get-latest-dmg-version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/mac" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk\.([0-9]+\.[0-9]+\.[0-9]+)-mac\.dmg' -r '$1' \
    | head -n1

[group('macos')]
pull-latest-dmg:
  just pull-dmg "$(just get-latest-dmg-version)"

[group('maintenance')]
update-application:
  #!/usr/bin/env bash
  set -euo pipefail

  echo -e "Checking for a new {{program_name}} release\n" >&2

  read_version() {
    sed -n '/^  '"$1"' = {/,/^  };/ s/^    version = "\([^"]*\)".*/\1/p' "{{package_file}}"
  }

  OLD_LINUX="$(read_version linuxSources)"
  OLD_DARWIN="$(read_version darwinSources)"
  NEW_LINUX="$(just get-latest-appimage-version)"
  NEW_DARWIN="$(just get-latest-dmg-version)"

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
    HASH_X86="$(just pull-appimage "$NEW_LINUX" x86_64)"
    HASH_ARM="$(just pull-appimage "$NEW_LINUX" arm64)"
    summary="linux $OLD_LINUX -> $NEW_LINUX"
  fi
  if [[ "$DARWIN_CHANGED" == 1 ]]; then
    HASH_DARWIN="$(just pull-dmg "$NEW_DARWIN")"
    if [[ -n "$summary" ]]; then
      summary+=", "
    fi
    summary+="darwin $OLD_DARWIN -> $NEW_DARWIN"
  fi

  echo -e "\nUpdating {{program_name}} ($summary)\n" >&2

  sed_args=()
  readme_sed_args=()
  if [[ "$LINUX_CHANGED" == 1 ]]; then
    sed_args+=(
      -e '/^  linuxSources = {/,/^  };/ s/version = "[^"]*"/version = "'"$NEW_LINUX"'"/'
      -e '/x86_64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_X86"'"|'
      -e '/aarch64-linux = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_ARM"'"|'
    )
    readme_sed_args+=(-e 's|shields.io/badge/linux-[^-]*-|shields.io/badge/linux-'"$NEW_LINUX"'-|')
  fi
  if [[ "$DARWIN_CHANGED" == 1 ]]; then
    sed_args+=(
      -e '/^  darwinSources = {/,/^  };/ s/version = "[^"]*"/version = "'"$NEW_DARWIN"'"/'
      -e '/aarch64-darwin = {/,/^    };/ s|hash = "[^"]*"|hash = "'"$HASH_DARWIN"'"|'
    )
    readme_sed_args+=(-e 's|shields.io/badge/macOS-[^-]*-|shields.io/badge/macOS-'"$NEW_DARWIN"'-|')
  fi
  sed -i "${sed_args[@]}" {{package_file}}
  sed -i "${readme_sed_args[@]}" {{readme_file}}

  just cleanup
  echo -e "{{program_name}} successfully updated ($summary)" >&2

[group('maintenance')]
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
