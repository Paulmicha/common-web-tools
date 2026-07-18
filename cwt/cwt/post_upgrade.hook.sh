#!/usr/bin/env bash

. cwt/instance/reinit.sh

# Skip auto-commit only when paths outside cwt/ are unclean. Dirty cwt/ files
# are expected after an upgrade and should still be committed.
non_cwt_unclean="$(
  git status --porcelain \
    | while IFS= read -r line; do
        path="${line:3}"
        if [[ "$path" == *' -> '* ]]; then
          path="${path##* -> }"
        fi
        path="${path#\"}"
        path="${path%\"}"
        case "$path" in
          cwt|cwt/*) ;;
          *) echo "$path" ;;
        esac
      done
)"

if [[ -n "$non_cwt_unclean" ]]; then
  echo "Git work tree has unclean files outside cwt/ -> skipped auto-commit."
elif [ -z "$(git status --porcelain)" ]; then
  echo "Git work tree is clean -> nothing to auto-commit."
else
  echo "Only cwt/ files are unclean -> auto-commit ..."

  git add cwt
  git commit -m "chore: update CWT core from upstream repo"
  git push

  echo "Only cwt/ files are unclean -> auto-commit : done."
fi
