#!/usr/bin/env bash

##
# Transcribes all ogg and wav audio files in the input directory.
#
# Converts .ogg to .wav, then transcribes .wav files to .txt using faster-whisper.
# Writes a combined transcript to transcribed.txt in the input directory.
#
# Uses the same p_* contract as abstract make transcribe.
#
# @example
#   make transcribe-all
#   # Or :
#   cwt/extensions/transcription/transcribe/all.sh
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

echo "Transcribing ogg ..."
u_hook_most_specific -a 'ogg' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
echo "Transcribing ogg : done."

echo "Transcribing wav ..."
u_hook_most_specific -a 'wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
echo "Transcribing wav : done."
