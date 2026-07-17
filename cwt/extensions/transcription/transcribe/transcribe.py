#!/usr/bin/env python3

##
# @file
# Audio files transcription.
#
# TODO doc
#
# @example
#   # Defaults to auto-detect language :
#   python cwt/extensions/transcription/transcribe/transcribe.py '/path/to/audio.wav'
#
#   # Translates audio to txt in given language :
#   python cwt/extensions/transcription/transcribe/transcribe.py '/path/to/audio.wav' --output-lang pt
#

import os
import re
import argparse
import sys

from datetime import datetime
from faster_whisper import WhisperModel

VALID_LANG_CODES = {
  "af", "am", "ar", "as", "az", "ba", "be", "bg", "bn", "bo", "br", "bs", "ca", "cs",
  "cy", "da", "de", "el", "en", "es", "et", "eu", "fa", "fi", "fo", "fr", "gl", "gu",
  "he", "hi", "hr", "ht", "hu", "hy", "id", "is", "it", "ja", "jw", "ka", "kk", "km",
  "kn", "ko", "la", "lb", "ln", "lo", "lt", "lv", "mg", "mi", "mk", "ml", "mn", "mr",
  "ms", "mt", "my", "ne", "nl", "no", "oc", "pa", "pl", "ps", "pt", "ro", "ru", "sa",
  "sd", "si", "sk", "sl", "sn", "so", "sq", "sr", "su", "sv", "sw", "ta", "te", "tg",
  "th", "tk", "tl", "tr", "tt", "uk", "ur", "uz", "vi", "wa", "xh", "yi", "zh"
}

VALID_MODELS = { "tiny", "base", "small", "medium", "large-v2" }

HELP = """\
Transcribes given .wav file as txt using faster-whisper.

Examples :

  # Defaults to auto-detect language :
  python transcribe.py '/path/to/audio.wav'

  # Translates audio to txt in given language :
  python transcribe.py '/path/to/audio.wav' --output-lang en

Common --output-lang option values :

| Language            | Code |
| ------------------- | ---- |
| English             | `en` |
| French              | `fr` |
| Spanish             | `es` |
| German              | `de` |
| Italian             | `it` |
| Portuguese          | `pt` |
| Dutch               | `nl` |
| Russian             | `ru` |
| Chinese (Mandarin)  | `zh` |
| Japanese            | `ja` |
| Korean              | `ko` |
| Arabic              | `ar` |
| Hindi               | `hi` |
| Turkish             | `tr` |
"""

##
# Validates given string as 2-letter ISO language code.
#
def validate_lang(value):
  value = value.lower()
  if value not in VALID_LANG_CODES:
    raise argparse.ArgumentTypeError(f"Invalid language code '{value}'. Must be one of: {', '.join(sorted(VALID_LANG_CODES))}")
  return value

##
# Validates given string as whisper model.
#
def validate_model(value):
  value = value.lower()
  if value not in VALID_MODELS:
    raise argparse.ArgumentTypeError(f"Invalid model '{value}'. Must be one of: {', '.join(sorted(VALID_MODELS))}")
  return value

# Parse command-line arguments
parser = argparse.ArgumentParser(
  description = HELP,
  formatter_class = argparse.RawDescriptionHelpFormatter
)

parser.add_argument(
  "input_file",
  nargs="?",
  help="Path to the .wav audio input file"
)

parser.add_argument(
  "--output-lang",
  type=validate_lang,
  help="Optional. Allows to translate txt of input audio into given language. It's a 2-letter ISO 639-1 language code, e.g. : en, fr, es, de, it, pt, nl, ru, zh, ja, ko, ar, hi, tr... (default: auto-detect)"
)

parser.add_argument(
  "--model",
  # type=str,
  type=validate_model,
  default='medium',
  help="Optional. Allows to change the Whisper model, e.g. : tiny, base, small, medium, large-v2 (default: medium)"
)

args = parser.parse_args()

if args.input_file is None:
  sys.stderr.write("\n")
  sys.stderr.write("❌ Missing input file.")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.stderr.write(HELP)
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.stderr.write("-> Aborting(1)")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.exit(1)

if not args.input_file.endswith(".wav"):
  sys.stderr.write("\n")
  sys.stderr.write(f"❌ Missing '.wav' file extension in input file '{args.input_file}'.")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.stderr.write("-> Aborting(2)")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.exit(2)

if not os.path.isfile(args.input_file):
  sys.stderr.write("\n")
  sys.stderr.write(f"❌ Input file '{args.input_file}' does not exist.")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.stderr.write("-> Aborting(3)")
  sys.stderr.write("\n")
  sys.stderr.write("\n")
  sys.exit(3)

input_file = args.input_file
output_lang = args.output_lang
model_name = args.model

model = WhisperModel(model_name, compute_type="auto")

if args.output_lang is None:
  output_filename = os.path.join(os.path.dirname(input_file), os.path.splitext(input_file)[0] + ".txt")
  segments, info = model.transcribe(input_file)
else:
  output_filename = os.path.join(os.path.dirname(input_file), os.path.splitext(input_file)[0] + "." + output_lang + ".txt")
  segments, info = model.transcribe(input_file, language=output_lang)

print(f"Transcribing to '{output_filename}' using the '{model_name}' model ...")

with open(output_filename, "w", encoding="utf-8") as f:
  f.write(f"# Detected language: {info.language} (confidence: {info.language_probability:.2f})\n")
  f.write(f"[{os.path.splitext(os.path.basename(input_file))[0]}]\n\n")
  all_text = " ".join(segment.text.strip() for segment in segments)
  all_text = re.sub(r"\s+", " ", all_text).strip()
  f.write(all_text + "\n")

print("✅ Transcription complete.")
