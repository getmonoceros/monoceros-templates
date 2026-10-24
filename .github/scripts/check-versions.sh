#!/usr/bin/env bash
#
# A service a workbench was built from must not change under it. A change
# raises `version` and keeps the previous file as services/<id>@<n>.yml,
# unchanged, and an older version never changes again. The argument is what
# to compare with: the state before a push, or the base of a pull request.
set -euo pipefail

base=$1
status=0

# Whether the file is back at the content its version had when it was
# introduced, in the history up to the base. That is a revert of a change
# that should not have been made (a push straight to main without a new
# version, say), not a change of its own. Any other content under the same
# version is a change, even one the file had at some point in between.
is_original() {
  local version blob commit
  version=$(version_of <"$1")
  blob=$(git hash-object "$1")
  while IFS= read -r commit; do
    if [ "$(git show "$commit:$1" 2>/dev/null | version_of)" = "$version" ]; then
      [ "$(git rev-parse "$commit:$1")" = "$blob" ]
      return
    fi
  done < <(git log --reverse --format=%H "$base" -- "$1")
  return 1
}

# The `version:` of a descriptor on stdin; 1 when it has none.
version_of() {
  awk '/^version:/ { print $2; found = 1; exit } END { if (!found) print 1 }'
}

while IFS= read -r file; do
  case "$file" in services/*.yml) ;; *) continue ;; esac
  # A new file has nothing to keep, a deleted one nothing to check.
  git cat-file -e "$base:$file" 2>/dev/null || continue
  [ -e "$file" ] || continue

  [ "$(git show "$base:$file")" = "$(cat "$file")" ] && continue
  is_original "$file" && continue

  name=$(basename "$file" .yml)
  case "$name" in
    *@*)
      echo "::error file=$file::$file is an older version and must not change. Change the current file and raise its version instead."
      status=1
      continue
      ;;
  esac

  old=$(git show "$base:$file")
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
