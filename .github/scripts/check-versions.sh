#!/usr/bin/env bash
#
# A service a workbench was built from must not change under it. A change
# raises `version` and keeps the previous file as services/<id>@<n>.yml,
# unchanged, and an older version never changes again. Run on a pull request
# with the base branch as the argument.
set -euo pipefail

base=$1
status=0

# The `version:` of a descriptor on stdin; 1 when it has none.
version_of() {
  awk '/^version:/ { print $2; found = 1; exit } END { if (!found) print 1 }'
}

while IFS= read -r file; do
  case "$file" in services/*.yml) ;; *) continue ;; esac
  # A new file has nothing to keep, a deleted one nothing to check.
  git cat-file -e "$base:$file" 2>/dev/null || continue
  [ -e "$file" ] || continue

  name=$(basename "$file" .yml)
  case "$name" in
    *@*)
      echo "::error file=$file::$file is an older version and must not change. Change the current file and raise its version instead."
      status=1
      continue
      ;;
  esac

  old=$(git show "$base:$file")
  [ "$old" = "$(cat "$file")" ] && continue
  before=$(printf '%s\n' "$old" | version_of)
  after=$(version_of <"$file")

  if [ "$after" -le "$before" ]; then
    echo "::error file=$file::$file changed, but its version stayed at $before. Copy the previous file to services/$name@$before.yml and raise version to $((before + 1))."
    status=1
    continue
  fi
  kept="services/$name@$before.yml"
  if [ ! -e "$kept" ] || [ "$(cat "$kept")" != "$old" ]; then
    echo "::error file=$file::$file went from version $before to $after, but $kept is missing or differs from version $before. Keep the previous file there, unchanged."
    status=1
  fi
done < <(git diff --name-only "$base"...HEAD)

exit "$status"
