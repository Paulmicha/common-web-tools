#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'stop_all' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Unload every model currently loaded in memory (`ollama ps` → `ollama stop`).
#
# @see cwt/extensions/gpt/gpt/stop_all.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make gpt-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

p_running=()
while IFS= read -r p_name; do
  [[ -n "$p_name" ]] || continue
  p_running+=("$p_name")
done < <(ollama ps 2>/dev/null | awk 'NR > 1 && $1 != "" { print $1 }')

if [[ ${#p_running[@]} -eq 0 ]]; then
  echo "No running Ollama models."
  echo "Over."
  exit 0
fi

for p_model in "${p_running[@]}"; do
  echo "Stopping model '$p_model' ..."
  ollama stop "$p_model" || exit $?
done

echo "Over."
