#!/usr/bin/env bash

. cwt/instance/reinit.sh

if [ -n "$(git status --porcelain)" ]; then
  echo "Git work tree is not clean -> skipped auto-commit."
else
  echo "Git work tree is clean -> auto-commit ..."

  git add cwt
  git commit -m "chore: update CWT core from upstream repo"
  git push

  echo "Git work tree is clean -> auto-commit : done."
fi
