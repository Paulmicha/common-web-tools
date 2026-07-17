#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# List locally available Ollama models (`ollama list`).
#
# @see cwt/extensions/gpt/gpt/list.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make gpt-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

ollama list
