#!/usr/bin/env bash
#
# Reads every template the way a builder's machine reads it. Fails on a
# broken file, on a version file Monoceros leaves out, and on a workbench
# template that does not render. Expects MONOCEROS_HOME to point at a home
# whose templates/ is this checkout.
set -euo pipefail

# `list-components` loads every service and MCP server descriptor and reads
# every workbench template; it prints what it left out on stderr.
if ! warnings=$(monoceros list-components --json 2>&1 >/dev/null); then
  echo "$warnings"
  exit 1
fi
if [ -n "$warnings" ]; then
  echo "$warnings"
  echo "::error::Monoceros left files out, see above."
  exit 1
fi
echo "read every descriptor and template"

for file in workbenches/*.yml; do
  [ -e "$file" ] || continue
  name=$(basename "$file" .yml)
  monoceros init "ci-$name" --template="$name" --yes >/dev/null
  echo "rendered $file"
done
