#!/usr/bin/env bash

##
# @file
# Nested CWT extension shared helpers (find + short-name resolve).
#
# Lazy subject-wide include — not on CWT_INC. Eager subject includes use
# $subject/$subject.inc.sh and load every bootstrap (phase 60). This file uses
# the *.opt-inc.sh convention and is loaded by bootstrap phase 90 when any
# action in this subject dir sources cwt/bootstrap.sh:
#   1) nested_cwt.opt-inc.sh   — shared (this file)
#   2) <action>.opt-inc.sh     — action-only, if present and distinct
#
# Re-sourcing is safe (function redefine). Do not rename to nested_cwt.inc.sh.
#
# @see cwt/bootstrap/90-caller-opt-inc.bootstrap-inc.sh
#
# Short refs (like Compose project names) use the nested instance directory
# basename. On collision, qualify by walking up ancestor folder names, e.g. :
#   my-project
#   client/my-project
#   Documents/client/my-project
#

##
# Finds nested CWT project instances under scan roots.
#
# Writes space-separated absolute paths to nested_cwt_instances in calling scope.
#
# Heuristic: directory containing cwt/bootstrap.sh. Default scan root is
# $HOME/Documents (depth 1–2). Skips the current PROJECT_DOCROOT when set.
#
# @param 1 [optional] String : space-separated scan roots.
#   Defaults to "$HOME/Documents".
#
# @example
#   u_nested_cwt_find
#   for d in $nested_cwt_instances; do echo "$d"; done
#
u_nested_cwt_find() {
  local p_roots="${1:-$HOME/Documents}"
  local root
  local cand
  local abs
  local skip="${PROJECT_DOCROOT:-}"

  nested_cwt_instances=''

  for root in $p_roots; do
    [[ -d "$root" ]] || continue
    # Depth 1.
    for cand in "$root"/*/cwt/bootstrap.sh; do
      [[ -f "$cand" ]] || continue
      abs="$(cd "$(dirname "$cand")/.." && pwd)"
      if [[ -n "$skip" && "$abs" == "$skip" ]]; then
        continue
      fi
      nested_cwt_instances+=" $abs"
    done
    # Depth 2.
    for cand in "$root"/*/*/cwt/bootstrap.sh; do
      [[ -f "$cand" ]] || continue
      abs="$(cd "$(dirname "$cand")/.." && pwd)"
      if [[ -n "$skip" && "$abs" == "$skip" ]]; then
        continue
      fi
      case " $nested_cwt_instances " in *" $abs "*) continue;; esac
      nested_cwt_instances+=" $abs"
    done
  done

  nested_cwt_instances="${nested_cwt_instances# }"
}

##
# Shortest unique path suffix for one abs path among a set of abs paths.
#
# Writes to nested_cwt_short_id in calling scope (e.g. my-project or
# client/my-project).
#
# @param 1 String : absolute instance path.
# @param 2 String : space-separated absolute paths (peer set).
#
u_nested_cwt_short_id() {
  local p_abs="$1"
  local p_peers="$2"
  local suffix="${p_abs##*/}"
  local parent="${p_abs%/*}"
  local peer
  local count

  nested_cwt_short_id="$suffix"

  while [[ -n "$parent" && "$parent" != '/' ]]; do
    count=0
    for peer in $p_peers; do
      case "$peer" in
        */"$suffix"|"$suffix")
          count=$((count + 1))
          ;;
      esac
    done

    if [[ $count -le 1 ]]; then
      nested_cwt_short_id="$suffix"
      return 0
    fi

    suffix="${parent##*/}/$suffix"
    parent="${parent%/*}"
  done

  nested_cwt_short_id="$suffix"
}

##
# Resolve a nested instance ref to an absolute PROJECT_DOCROOT.
#
# Accepts :
#   - absolute or relative filesystem path to a CWT instance
#   - short id = directory basename (unique among discovered nesteds)
#   - qualified id = ancestor/…/basename when basenames collide
#
# Writes absolute path to nested_cwt_resolved. Return non-zero on failure.
#
# @param 1 String : ref (short id, qualified id, or path).
#
# @example
#   u_nested_cwt_resolve 'my-project'
#   echo "$nested_cwt_resolved"
#
#   u_nested_cwt_resolve 'client/my-project'
#
u_nested_cwt_resolve() {
  local p_ref="$1"
  local abs
  local matches=''
  local m
  local suggestions=''
  local sid

  nested_cwt_resolved=''

  if [[ -z "$p_ref" ]]; then
    echo "Error in u_nested_cwt_resolve() - $BASH_SOURCE line $LINENO: empty ref." >&2
    return 1
  fi

  # Absolute / relative path to an existing CWT instance.
  if [[ -d "$p_ref" && -f "$p_ref/cwt/bootstrap.sh" ]]; then
    nested_cwt_resolved="$(cd "$p_ref" && pwd)"
    return 0
  fi

  u_nested_cwt_find

  if [[ -z "$nested_cwt_instances" ]]; then
    echo "Error in u_nested_cwt_resolve() - $BASH_SOURCE line $LINENO: no nested CWT instances found under $HOME/Documents." >&2
    return 2
  fi

  # Match by path suffix (basename or ancestor-qualified).
  for abs in $nested_cwt_instances; do
    case "$abs" in
      */"$p_ref"|"$p_ref")
        matches+=" $abs"
        ;;
    esac
  done
  matches="${matches# }"

  case "$matches" in
    '')
      echo "Error in u_nested_cwt_resolve() - $BASH_SOURCE line $LINENO: no nested CWT instance matches '$p_ref'." >&2
      echo "Known short ids :" >&2
      for abs in $nested_cwt_instances; do
        u_nested_cwt_short_id "$abs" "$nested_cwt_instances"
        echo "  $nested_cwt_short_id  →  $abs" >&2
      done
      return 3
      ;;
    *' '*)
      echo "Error in u_nested_cwt_resolve() - $BASH_SOURCE line $LINENO: ambiguous ref '$p_ref'." >&2
      echo "Qualify with a parent folder (shortest unique id) :" >&2
      for m in $matches; do
        u_nested_cwt_short_id "$m" "$nested_cwt_instances"
        echo "  $nested_cwt_short_id  →  $m" >&2
      done
      return 4
      ;;
    *)
      nested_cwt_resolved="$matches"
      return 0
      ;;
  esac
}
