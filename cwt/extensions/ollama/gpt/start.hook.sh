#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'gpt' -a 'start' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Ensure `ollama` is in PATH and ollama.service / API are up. Model pull is
# separate (`make gpt-pull`). Override with start.<variants>.hook.sh if needed.
#
# On hybrid Intel+NVIDIA hosts, CUDA GPU access is via the system service (see
# changelog GPU doc). PRIME render-offload fallback after suspend:
#   __NV_PRIME_RENDER_OFFLOAD=1
#   __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
#   __GLX_VENDOR_LIBRARY_NAME=nvidia
#   __VK_LAYER_NV_optimus=NVIDIA_only
#
# @see cwt/extensions/gpt/gpt/start.sh
# @see changelog/2026/06/29-gpu-nvidia-legacy-driver.md
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

p_service_active='unknown'
p_api_ok=0

if curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  p_api_ok=1
fi

if [[ $p_api_ok -eq 0 ]]; then
  if systemctl is-active --quiet ollama 2>/dev/null; then
    p_service_active='active'
  elif systemctl is-active --quiet ollama.service 2>/dev/null; then
    p_service_active='active'
  else
    p_service_active='inactive'
  fi

  if [[ "$p_service_active" != 'active' ]]; then
    echo "Starting ollama.service ..."

    if systemctl start ollama 2>/dev/null; then
      :
    elif sudo systemctl start ollama 2>/dev/null; then
      :
    else
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO - failed to start ollama.service." >&2
      echo "Try manually : sudo systemctl start ollama" >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi

    sleep 2
  fi

  if ! curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - Ollama API not reachable at 127.0.0.1:11434." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi
fi

echo "Ollama is running (http://127.0.0.1:11434)."
echo "Over."
