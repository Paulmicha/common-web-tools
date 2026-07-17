#!/usr/bin/env bash

##
# Smoke tests for transcribe / convert hook resolution.
#
# @requires cwt/vendor/shunit2
#
# @example
#   cwt/extensions/transcription/transcribe/cwt/transcribe.test.sh
#

. cwt/bootstrap.sh

test_transcribe_ogg_hook_resolves() {
  u_hook_most_specific 'dry-run' -a 'ogg' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'ogg hook must resolve on this host' "[[ -f '$hook_most_specific_dry_run_match' ]]"
}

test_transcribe_wav_hook_resolves() {
  u_hook_most_specific 'dry-run' -a 'wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'wav hook must resolve on this host' "[[ -f '$hook_most_specific_dry_run_match' ]]"
}

test_transcribe_action_hook_resolves() {
  u_hook_most_specific 'dry-run' -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'transcribe hook must resolve on this host' "[[ -f '$hook_most_specific_dry_run_match' ]]"
}

test_convert_to_wav_hook_resolves() {
  u_hook_most_specific 'dry-run' -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'to_wav hook must resolve on this host' "[[ -f '$hook_most_specific_dry_run_match' ]]"
}

test_transcribe_py_hook_resolves() {
  u_hook_most_specific 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'transcribe.py hook must resolve on this host' "[[ -f '$hook_most_specific_dry_run_match' ]]"
}

. cwt/vendor/shunit2/shunit2
