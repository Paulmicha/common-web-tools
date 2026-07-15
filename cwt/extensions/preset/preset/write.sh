#!/usr/bin/env bash

##
# (Re)write CWT code from canonical presets under cwt/extensions/preset/preset/.
#
# Layers:
#   defaults                         — host-matching subject packs
#   action <subject> <action> [ns]   — from cwt/extensions/preset/preset/cwt/action.tpl.sh
#   subject <pack> [COMPONENT] [SERVICE]
#   project <pack> <dest> [name] [short] [hostname]
#
# Optional leading:
#   --nested <ref> …                 — run write inside child via nested_cwt-exec
#
# @example
#   make preset-write
#   # Or :
#   cwt/extensions/preset/preset/write.sh
#
#   make preset-write action my_subject my_action extend
#   make preset-write subject index site search
#   make preset-write project 11ty "$HOME/Documents/my-11ty"
#   make preset-write --nested my-project defaults
#
. cwt/bootstrap.sh

# Nested delegation via nested_cwt exec (short id or path).
# Extension must not be ignored (or invoke exec.sh by path).
if [[ "$1" == '--nested' ]]; then
  shift
  nested_ref="$1"
  shift
  if [[ -z "$nested_ref" ]]; then
    echo "Usage: cwt/extensions/preset/preset/write.sh --nested <ref> <layer...> " >&2
    echo "Ref = nested instance short id (folder name), parent/id on collision, or path." >&2
    exit 1
  fi
  cwt/extensions/nested_cwt/nested_cwt/exec.sh "$nested_ref" cwt/extensions/preset/preset/write.sh "$@"
  exit $?
fi

layer="${1:-defaults}"
shift || true

case "$layer" in
  defaults|'')
    u_preset_write_defaults
    ;;
  action)
    u_preset_write_action "$@"
    ;;
  subject)
    u_preset_write_subject "$@"
    ;;
  project)
    u_preset_write_project "$@"
    ;;
  *)
    echo "Usage:" >&2
    echo "  cwt/extensions/preset/preset/write.sh [defaults]" >&2
    echo "  cwt/extensions/preset/preset/write.sh action <subject> <action> [namespace]" >&2
    echo "  cwt/extensions/preset/preset/write.sh subject <pack> [COMPONENT] [SERVICE]" >&2
    echo "  cwt/extensions/preset/preset/write.sh project <pack> <dest> [name] [short] [hostname]" >&2
    echo "  cwt/extensions/preset/preset/write.sh --nested <ref> <layer...>" >&2
    echo "  Ref = short id (folder name), parent/id on collision, or path." >&2
    exit 1
    ;;
esac
