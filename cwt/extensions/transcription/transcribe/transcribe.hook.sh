#!/usr/bin/env bash

##
# Implements u_hook_most_specific -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default for abstract make transcribe (tested on debian-13 only for now).
# Easy to override: scripts/cwt/extend/<subject>/transcribe.hook.sh or
# transcribe.<HOST_OS>.hook.sh.
#
# Reads exported p_* contract from the abstract entry (no re-parse of $@).
# Resolves transcribe.py via subject-free dry-run; requires pipx + faster-whisper
# on the host (software-deps installer is a future plan).
#
# @see cwt/extensions/transcription/transcribe/transcribe.sh
# @see cwt/extensions/transcription/transcribe/transcribe.py
#

# Prefer explicit targets when the abstract entry provided them.
if [[ -n "${p_targets:-}" ]]; then
  # shellcheck disable=SC2086
  set -- $p_targets
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    case "$file" in
      *.wav) ;;
      *) continue ;;
    esac

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
else
# Default: scan p_input_dir for *.wav
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
fi
