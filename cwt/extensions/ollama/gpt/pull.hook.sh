#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Pull one or more models from the Ollama registry.
#
# @example
#   make gpt-pull llama3.2
#   GPT_MODEL=llama3.2 make gpt-pull
#
# @see cwt/extensions/gpt/gpt/pull.sh
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
  echo "Usage: make gpt-pull MODEL [MODEL…]  (or export GPT_MODEL)" >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

for p_model in $p_models; do
  echo "Pulling model '$p_model' ..."
  ollama pull "$p_model" || exit $?
done

echo "Over."
