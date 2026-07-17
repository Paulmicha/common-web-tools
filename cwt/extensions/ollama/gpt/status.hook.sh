#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'status' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Report Ollama binary, service/API reachability, and running models.
#
# @see cwt/extensions/gpt/gpt/status.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

echo "binary    : $(command -v ollama)"

p_service='unknown'
if systemctl is-active --quiet ollama 2>/dev/null \
  || systemctl is-active --quiet ollama.service 2>/dev/null; then
  p_service='active'
elif systemctl is-enabled --quiet ollama 2>/dev/null \
  || systemctl is-enabled --quiet ollama.service 2>/dev/null; then
  p_service='inactive (enabled)'
elif command -v systemctl >/dev/null 2>&1; then
  p_service='inactive'
fi
echo "service   : $p_service"

p_api='down'
if curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  p_api='up (http://127.0.0.1:11434)'
fi
echo "api       : $p_api"

echo
echo "Running models (ollama ps):"
ollama ps

echo
echo "Local models (ollama list):"
ollama list

echo "Over."
