#!/usr/bin/env bash

##
# Implements u_hook_most_specific -a 'ogg' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now).
# Converts .ogg files in p_input_dir to .wav via convert/to_wav.
#
# @see cwt/extensions/transcription/transcribe/all.sh
#

find "$p_input_dir" -maxdepth 1 -type f -name "*.ogg" -printf "%T@ %p\n" \
  | sort -n \
  | cut -d' ' -f2- \
  | while read -r file
do
  echo "Processing: '$file' ..."

  wav_file="${file%.ogg}.wav"
  existing_txt="${file%.ogg}.txt"

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
    continue
  fi

  if [[ ! -f "$wav_file" ]]; then
    scripts/cwt/extend/convert/to_wav.sh "$file"
  fi

  if [[ ! -f "$wav_file" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - failed to convert '$file' to '$wav_file'." >&2
    echo "Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  echo "Processing: '$file' : done."
done
