nix_file := "ktalk.nix"

set quiet := true
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

pull_appimage version:
  wget2 --force-progress -O "ktalk-{{version}}.AppImage" \
    "https://st.ktalk.host/ktalk-app/linux/ktalk{{version}}x86_64.AppImage" >&2

  nix hash file "ktalk-{{version}}.AppImage"

get_latest_appimage_version:
  { wget2 --server-response --max-redirect=0 "https://app.ktalk.ru/system/dist/download/linux" -O /dev/null 2>&1 || true; } \
    | rg -o 'ktalk([0-9]+\.[0-9]+\.[0-9]+)x86_64\.AppImage' -r '$1' \
    | head -n1

pull_latest_appimage:
  just pull_appimage "$(just get_latest_appimage_version)"

update_application:
  #!/usr/bin/env bash
  set -euo pipefail

  OLD_VERSION="$(rg -m1 -o 'version = "[^"]+"' "{{nix_file}}" | sed 's/version = "\(.*\)"/\1/')"
  NEW_VERSION="$(just get_latest_appimage_version)"

  if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
    echo "Already up to date: $NEW_VERSION"
    exit 0
  fi

  HASH="$(just pull_appimage "$NEW_VERSION")"

  sed -i \
    -e 's/version = "[^"]*"/version = "'"$NEW_VERSION"'"/' \
    -e 's|hash = "[^"]*"|hash = "'"$HASH"'"|' \
    {{nix_file}}

  just cleanup
  echo "Updated: $OLD_VERSION -> $NEW_VERSION"

cleanup:
  rm -f -- *.AppImage
