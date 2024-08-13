#!/usr/bin/env bash

##
# Escape args for make shortcuts.
#
# (this script intentionally out of bootstrapped CWT includes)
#
# @see u_make_unescape() in cwt/make/make.inc.sh
#
# @example
#   cwt/escape.sh 'arg1 with space' arg2
#   cwt/escape.sh '$test = "Printed from Drupal php"; print $test;'
#   cwt/escape.sh '$purgers = \Drupal::config("purge.plugins")->get()["purgers"] ?? []; foreach ($purgers as $purger) { $hostName = \Drupal::config("varnish_purger.settings." . $purger["instance_id"])->get("hostname"); $port = \Drupal::config("varnish_purger.settings." . $purger["instance_id"])->get("port"); if (!$hostName || !$port) continue; $param = [CURLOPT_PORT => $port, CURLOPT_URL => $hostName, CURLOPT_RETURNTRANSFER => TRUE, CURLOPT_ENCODING => "", CURLOPT_MAXREDIRS => 10, CURLOPT_TIMEOUT => 30, CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1, CURLOPT_CUSTOMREQUEST => "BAN", CURLOPT_HTTPHEADER => ["x-url: /test/path-to.pdf"]]; $curl = curl_init(); curl_setopt_array($curl, $param); curl_exec($curl); curl_close($curl); }'
#

escaped_args=''

while [ $# -gt 0 ]; do
  arg="$1"

  case "$arg" in
    # Quoting is done in the make call wrapper :
    # @see cwt/make/call_wrap.make.sh
    # But make cannot handle the '=' sign (by design).
    # TODO [evol] find better workaround.
    *' '*|*'$'*|*'#'*|*'['*|*']'*|*'*|*'*|*'&'*|*'*'*|*'"'*|*"'"*|*'='*)
      arg="${arg//\$/'\$'}"
      arg="${arg//'='/'∓'}"
      escaped_args+="'${arg}' "
      ;;

    *)
      escaped_args+="$arg "
      ;;
  esac

  shift
done

echo "$escaped_args"
