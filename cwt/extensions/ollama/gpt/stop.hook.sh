#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'stop' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Unload one or more running models from memory (`ollama stop`).
#
# @example
#   make gpt-stop llama3.2
#   GPT_MODEL=llama3.2 make gpt-stop
#
# @see cwt/extensions/gpt/gpt/stop.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make gpt-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

p_models="${p_models:-${GPT_MODEL:-${GPT_OLLAMA_MODEL:-}}}"

if [[ -z "$p_models" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - no model specified." >&2
  echo "Usage: make gpt-stop MODEL [MODEL…]  (or export GPT_MODEL)" >&2
  echo "Use make gpt-stop-all to unload every running model." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

for p_model in $p_models; do
  echo "Stopping model '$p_model' ..."
  ollama stop "$p_model" || exit $?
done

echo "Over."
