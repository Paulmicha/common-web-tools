#!/usr/bin/env bash

##
# Abstract transcription entry: parse CLI → export p_* → most-specific hook.
#
# Generic core default (tested on debian-13 only for now):
#   cwt/extensions/transcription/transcribe/transcribe.hook.sh
#
# Dispatch is subject-free so any subject may implement transcribe.<variants>.hook.sh.
#
# Host software (manual for now): pipx + faster-whisper — see future software-deps plan.
#
# @example
#   make transcribe
#   make transcribe -i data/media/2026/07 -l fr
#   cwt/extensions/transcription/transcribe/transcribe.sh -i data/media/2026/07
#

. cwt/bootstrap.sh

p_input_dir=""
p_output_lang=""
p_skip_vscodium=0
p_targets=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input-dir) p_input_dir="$2"; shift 2;;
    -l|--output-lang) p_output_lang="$2"; shift 2;;
    -s|--skip-vsc) p_skip_vscodium=1; shift 1;;
    -*)
      echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2
      exit 1
      ;;
    *)
      p_targets+="${p_targets:+ }$1"
      shift 1
      ;;
  esac
done

if [[ ! -d "$p_input_dir" ]]; then
  p_input_dir="data/media/$(date +"%Y")/$(date +"%m")"
fi

if [[ ! -d "$p_input_dir" ]]; then
  mkdir -p "$p_input_dir"
fi

if [[ ! -d "$p_input_dir" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - folder '$p_input_dir' does not exist." >&2
  echo "Aborting (2)." >&2
  echo >&2
  exit 2
fi

if [[ "$p_skip_vscodium" != "1" ]]; then
  nohup \
    /usr/bin/codium data/media > /dev/null 2>&1 &
  disown
fi

agregated_txt="$p_input_dir/transcribed.txt"

if [[ -f "$agregated_txt" ]]; then
  echo '' > "$agregated_txt"
else
  touch "$agregated_txt"
fi

export p_input_dir p_output_lang p_skip_vscodium p_targets agregated_txt

u_hook_most_specific -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
