#!/usr/bin/env bash

##
# Implements u_hook_most_specific -a 'wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now).
# Transcribes .wav files in p_input_dir to .txt using faster-whisper.
#
# TODO setup (prereqs) doc — pipx + faster-whisper (software-deps future plan).
# TODO [evol] automatically copy files from the $HOME/Downloads dir if the input
# dir is empty.
#
# @see cwt/extensions/transcription/transcribe/transcribe.py
# @see cwt/extensions/transcription/transcribe/all.sh
#
# @example
#   # Defaults to :
#   #   -l|--output-lang : auto-detect
#   #   -i|--input-dir : "data/media/$(date +"%Y")/$(date +"%m")"
#   make transcribe-all
#

find "$p_input_dir" -maxdepth 1 -type f -name "*.wav" -printf "%T@ %p\n" \
  | sort -n \
  | cut -d' ' -f2- \
  | while read -r file
do
  echo "Processing: '$file' ..."

  existing_txt="${file%.wav}.txt"

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
    continue
  fi

  hook_most_specific_dry_run_match=''
  u_hook_most_specific 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  if [[ ! -f "$hook_most_specific_dry_run_match" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - no implementation match :" >&2
    echo >&2
    echo "  u_hook_most_specific 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t" >&2
    echo >&2
    echo "    HOST_OS = '$HOST_OS'" >&2
    echo "    HOST_TYPE = '$HOST_TYPE'" >&2
    echo "    INSTANCE_TYPE = '$INSTANCE_TYPE'" >&2
    echo >&2
    echo "Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  if [[ -z "$p_output_lang" ]]; then
    python "$hook_most_specific_dry_run_match" "$file"
  else
    python "$hook_most_specific_dry_run_match" "$file" --output-lang "$p_output_lang"
  fi

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - non-zero status returned by :" >&2
    echo "  python '$hook_most_specific_dry_run_match' '$file'" >&2
    echo "Aborting (5)." >&2
    echo >&2
    exit 5
  fi

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
  fi

  echo "Processing: '$file' : done."
done
