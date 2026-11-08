sources_file := "_sources/generated.json"
readme_file := "README.md"
changelog_file := ".nvfetcher-changelog"
linux_name := "ktalk-linux-x86_64"
darwin_name := "ktalk-darwin"

set quiet := true
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

[private]
default:
    @just --choose

[private]
read-version name:
  jq -r '.["{{name}}"].version' "{{sources_file}}"

update-sources:
  #!/usr/bin/env bash
  set -euo pipefail
  nvfetcher -l "{{changelog_file}}"

update-badges:
  #!/usr/bin/env bash
  set -euo pipefail
  linux="$(just read-version {{linux_name}})"
  darwin="$(just read-version {{darwin_name}})"
  sed -i \
    -e 's|shields.io/badge/linux-[^-]*-|shields.io/badge/linux-'"$linux"'-|' \
    -e 's|shields.io/badge/macOS-[^-]*-|shields.io/badge/macOS-'"$darwin"'-|' \
    "{{readme_file}}"

[group('maintenance')]
update-application:
  just update-sources
  just update-badges
