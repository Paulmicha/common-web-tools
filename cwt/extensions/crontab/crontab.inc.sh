#!/usr/bin/env bash

##
# Crontab extension utilities.
#
# Sourced during core CWT bootstrap via u_cwt_extensions() when the crontab
# extension is enabled (not listed in .cwt_extensions_ignore).
#
# Convention : function names are prefixed by "u".
#

##
# Whitelisted N values for every-* / Nx-per-* presets.
#
u_cron_preset_ns='1 2 3 4 5 10 15 20 30 40 45 50'

##
# Returns 0 if $1 is a whitelisted schedule preset token.
#
u_cron_preset_is_valid() {
  local p="$1"
  local n
  local unit
  local hh
  local mm

  if [[ "$p" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case " $u_cron_preset_ns " in *" $n "*) return 0;; esac
    return 1
  fi

  if [[ "$p" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    if [[ "$hh" -ge 0 && "$hh" -le 23 ]]; then
      return 0
    fi
    return 1
  fi

  if [[ "$p" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case " $u_cron_preset_ns " in *" $n "*) return 0;; esac
    return 1
  fi

  return 1
}

##
# Compiles a preset into crontab schedule expression(s).
#
# Outputs in calling scope :
#   cron_schedules — bash array of 5-field expressions (one or more)
#   cron_subminute — empty or seconds interval hint for run hook
#
# @param 1 String : preset token
# @param 2 [optional] String : make entry (for stable phase)
# @param 3 [optional] Number : index among peers sharing cadence (for spacing)
#
u_cron_preset_compile() {
  local p="$1"
  local p_entry="${2:-}"
  local p_idx="${3:-0}"
  local n
  local unit
  local hh
  local mm
  local i
  local slot
  local phase
  local span

  cron_schedules=()
  cron_subminute=''

  if [[ "$p" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    phase=$((p_idx % n))
    case "$unit" in
      m)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules+=("*/${n} * * * *")
        else
          # Stagger same-cadence peers within the every-N window when possible.
          phase=$((p_idx % n))
          cron_schedules+=("${phase}-59/${n} * * * *")
        fi
        ;;
      h)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules+=("0 */${n} * * *")
        else
          phase=$((p_idx % 60))
          cron_schedules+=("${phase} */${n} * * *")
        fi
        ;;
      d)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules+=("0 0 */${n} * *")
        else
          phase=$((p_idx % 24))
          cron_schedules+=("0 ${phase} */${n} * *")
        fi
        ;;
    esac
    return 0
  fi

  if [[ "$p" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    mm="${BASH_REMATCH[2]}"
    # Strip leading zeros for cron hour (keep numeric).
    hh=$((10#$hh))
    mm=$((10#$mm))
    cron_schedules+=("${mm} ${hh} * * *")
    return 0
  fi

  if [[ "$p" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case "$unit" in
      m)
        cron_subminute=$((60 / n))
        if [[ $cron_subminute -lt 1 ]]; then
          cron_subminute=1
        fi
        # Host ticks every minute; run hook handles second slots.
        cron_schedules+=("* * * * *")
        ;;
      h)
        span=$((60 / n))
        if [[ $span -lt 1 ]]; then
          span=1
        fi
        phase=$((p_idx % span))
        for ((i = 0; i < n; i++)); do
          slot=$((i * span + phase))
          if [[ $slot -ge 60 ]]; then
            slot=$((slot % 60))
          fi
          cron_schedules+=("${slot} * * * *")
        done
        ;;
      d)
        span=$((24 / n))
        if [[ $span -lt 1 ]]; then
          span=1
        fi
        phase=$((p_idx % span))
        for ((i = 0; i < n; i++)); do
          slot=$((i * span + phase))
          if [[ $slot -ge 24 ]]; then
            slot=$((slot % 24))
          fi
          cron_schedules+=("0 ${slot} * * *")
        done
        ;;
    esac
    return 0
  fi

  return 1
}

##
# Strip yaml scalar artifacts (quotes / trailing spaces / array form).
#
u_cron_scalar() {
  local v="$1"
  v="${v#\"}"
  v="${v%\"}"
  v="${v#\'}"
  v="${v%\'}"
  v="${v%"${v##*[![:space:]]}"}"
  v="${v#"${v%%[![:space:]]*}"}"
  printf '%s' "$v"
}

##
# Parse `{action}.{preset}` from a crontab.yml basename (no path, no suffix).
#
# Outputs : cron_action, cron_preset
#
u_cron_parse_filename() {
  local base="$1"
  local preset_cand
  local action_cand

  cron_action=''
  cron_preset=''

  # Prefer longest valid preset suffix after the last-but matching patterns.
  if [[ "$base" =~ ^(.+)\.(every-[0-9]+[mhd])$ ]] \
    || [[ "$base" =~ ^(.+)\.(at-[0-9]{2}h(00|15|30|45))$ ]] \
    || [[ "$base" =~ ^(.+)\.([0-9]+x-per-[mhd])$ ]]; then
    action_cand="${BASH_REMATCH[1]}"
    preset_cand="${BASH_REMATCH[2]}"
    if u_cron_preset_is_valid "$preset_cand"; then
      cron_action="$action_cand"
      cron_preset="$preset_cand"
      return 0
    fi
  fi

  return 1
}

##
# Load base_settings templates into calling scope as associative keys.
#
# Sets :
#   cron_tpl_<name>_<field> scalars for defaults / scheduled_job
#
u_cron_load_base_templates() {
  local base_file='cwt/extensions/crontab/base_settings.crontab.yml'
  local k

  unset cron_tpl_defaults_enabled cron_tpl_defaults_wrap cron_tpl_defaults_lock \
    cron_tpl_defaults_user cron_tpl_scheduled_job_retry_max \
    cron_tpl_scheduled_job_retry_delay

  if [[ ! -f "$base_file" ]]; then
    echo >&2 "Error: missing $base_file"
    return 1
  fi

  # shellcheck disable=SC2034
  eval "$(u_yaml_parse "$base_file" 'cronbase_')"

  cron_tpl_defaults_enabled="$(u_cron_scalar "${cronbase_includes_defaults_enabled:-true}")"
  cron_tpl_defaults_wrap="$(u_cron_scalar "${cronbase_includes_defaults_wrap:-lt}")"
  cron_tpl_defaults_lock="$(u_cron_scalar "${cronbase_includes_defaults_lock:-skip}")"
  cron_tpl_defaults_user="$(u_cron_scalar "${cronbase_includes_defaults_user:-}")"
  cron_tpl_scheduled_job_retry_max="$(u_cron_scalar "${cronbase_includes_scheduled_job_retry_max:-0}")"
  cron_tpl_scheduled_job_retry_delay="$(u_cron_scalar "${cronbase_includes_scheduled_job_retry_delay:-10s}")"
}

##
# Apply includes: crontab.defaults | crontab.scheduled_job onto dict vars.
#
u_cron_apply_includes() {
  local inc
  inc="$(u_cron_scalar "${1:-}")"

  cron_def_enabled="$cron_tpl_defaults_enabled"
  cron_def_wrap="$cron_tpl_defaults_wrap"
  cron_def_lock="$cron_tpl_defaults_lock"
  cron_def_user="$cron_tpl_defaults_user"
  cron_def_retry_max='0'
  cron_def_retry_delay='10s'

  case "$inc" in
    crontab.scheduled_job|scheduled_job)
      cron_def_retry_max="$cron_tpl_scheduled_job_retry_max"
      cron_def_retry_delay="$cron_tpl_scheduled_job_retry_delay"
      ;;
    crontab.defaults|defaults|'')
      ;;
  esac
}

##
# Purge generated cron scripts.
#
u_cron_purge_generated() {
  rm -rf scripts/cwt/local/cron
  rm -f scripts/cwt/local/cron.sh
  mkdir -p scripts/cwt/local/cron
}

##
# Discover *.crontab.yml, merge, compile presets, write generated scripts.
#
# Mirrors u_remote_instances_setup() lifecycle (files only; host sync separate).
#
u_cron_settings_setup() {
  local f
  local base
  local subject
  local entry
  local files=()
  local peer_idx
  declare -A peer_count=()
  declare -A peer_seen=()

  u_cron_load_base_templates || return 1
  u_cron_purge_generated

  shopt -s nullglob globstar
  for f in scripts/cwt/extend/**/*.crontab.yml cwt/extensions/**/*.crontab.yml; do
    case "$f" in
      */base_settings.crontab.yml) continue;;
    esac
    if [[ -f "$f" ]]; then
      files+=("$f")
    fi
  done
  shopt -u nullglob globstar

  # First pass: count peers per preset class for spacing.
  for f in "${files[@]}"; do
    base="$(basename "$f" .crontab.yml)"
    if ! u_cron_parse_filename "$base"; then
      echo >&2 "Error: invalid crontab filename (bad preset): $f"
      return 1
    fi
    peer_count["$cron_preset"]=$(( ${peer_count[$cron_preset]:-0} + 1 ))
  done

  cat > scripts/cwt/local/cron.sh <<'EOF'
#!/usr/bin/env bash

##
# Generated crontab definitions aggregate.
#
# Rewritten by u_cron_settings_setup() during instance (re)init.
# @see cwt/extensions/crontab/crontab.inc.sh
#

CWT_CRON_ENTRIES=''
EOF

  for f in "${files[@]}"; do
    base="$(basename "$f" .crontab.yml)"
    subject="$(basename "$(dirname "$f")")"
    # scripts/cwt/extend/<subject>/… — subject is directory name.
    # Skip when file lives oddly under extensions/crontab without action sibling.
    if ! u_cron_parse_filename "$base"; then
      echo >&2 "Error: cannot parse crontab filename: $f"
      return 1
    fi

    entry="${subject}-${cron_action}"
    # Sanitize like make tasks (underscores → already hyphenated subjects).
    entry="${entry//_/-}"

    peer_idx=${peer_seen[$cron_preset]:-0}
    peer_seen[$cron_preset]=$((peer_idx + 1))

    unset croncj_includes croncj_enabled croncj_args croncj_lock croncj_wrap \
      croncj_user croncj_retry_max croncj_retry_delay croncj_make croncj_run \
      croncj_monitor_mark_stale croncj_monitor_reclaim_lock \
      croncj_monitor_outer_retry
    eval "$(u_yaml_parse "$f" 'croncj_')"

    u_cron_apply_includes "${croncj_includes:-}"

    local enabled wrap lock user retry_max retry_delay args make_task run_id
    enabled="$(u_cron_scalar "${croncj_enabled:-$cron_def_enabled}")"
    wrap="$(u_cron_scalar "${croncj_wrap:-$cron_def_wrap}")"
    lock="$(u_cron_scalar "${croncj_lock:-$cron_def_lock}")"
    user="$(u_cron_scalar "${croncj_user:-$cron_def_user}")"
    retry_max="$(u_cron_scalar "${croncj_retry_max:-$cron_def_retry_max}")"
    retry_delay="$(u_cron_scalar "${croncj_retry_delay:-$cron_def_retry_delay}")"
    args="$(u_cron_scalar "${croncj_args:-}")"
    make_task="$(u_cron_scalar "${croncj_make:-}")"
    run_id="$(u_cron_scalar "${croncj_run:-}")"

    if ! u_cron_preset_compile "$cron_preset" "$entry" "$peer_idx"; then
      echo >&2 "Error: cannot compile preset '$cron_preset' for $f"
      return 1
    fi

    local schedule_joined=''
    local s
    for s in "${cron_schedules[@]}"; do
      schedule_joined+="${s};"
    done
    schedule_joined="${schedule_joined%;}"

    local cmd
    case "$wrap" in
      lt)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make lt e:${entry}"
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      thread)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make thread-wrap e:${entry}"
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      direct)
        if [[ -n "$make_task" ]]; then
          cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make ${make_task}"
        else
          cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make ${entry}"
        fi
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      *)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make lt e:${entry}"
        ;;
    esac

    local out="scripts/cwt/local/cron/${entry}.sh"
    cat > "$out" <<EOF
#!/usr/bin/env bash
# Generated from ${f} — do not edit.
export CWT_CRON_ENTRY='${entry}'
export CWT_CRON_PRESET='${cron_preset}'
export CWT_CRON_SOURCE='${f}'
export CWT_CRON_ENABLED='${enabled}'
export CWT_CRON_SCHEDULE='${schedule_joined}'
export CWT_CRON_SUBMINUTE='${cron_subminute}'
export CWT_CRON_WRAP='${wrap}'
export CWT_CRON_LOCK='${lock}'
export CWT_CRON_USER='${user}'
export CWT_CRON_RETRY_MAX='${retry_max}'
export CWT_CRON_RETRY_DELAY='${retry_delay}'
export CWT_CRON_ARGS='${args}'
export CWT_CRON_MAKE='${make_task}'
export CWT_CRON_RUN='${run_id}'
export CWT_CRON_MONITOR_MARK_STALE='$(u_cron_scalar "${croncj_monitor_mark_stale:-}")'
export CWT_CRON_MONITOR_RECLAIM_LOCK='$(u_cron_scalar "${croncj_monitor_reclaim_lock:-}")'
export CWT_CRON_MONITOR_OUTER_RETRY='$(u_cron_scalar "${croncj_monitor_outer_retry:-}")'
export CWT_CRON_CMD='${cmd}'
EOF

    echo "CWT_CRON_ENTRIES+=\"${entry} \"" >> scripts/cwt/local/cron.sh
  done

  echo "Crontab definitions written under scripts/cwt/local/cron/ (${#files[@]} entries)."
}

##
# Load one generated cron entry script into the environment.
#
u_cron_entry_load() {
  local p_entry="$1"
  local f="scripts/cwt/local/cron/${p_entry}.sh"

  if [[ ! -f "$f" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$f"
}

##
# Human duration (10s / 2m) → seconds.
#
u_cron_delay_seconds() {
  local d="$1"
  if [[ "$d" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$d" =~ ^([0-9]+)m$ ]]; then
    echo $((BASH_REMATCH[1] * 60))
  elif [[ "$d" =~ ^([0-9]+)h$ ]]; then
    echo $((BASH_REMATCH[1] * 3600))
  elif [[ "$d" =~ ^[0-9]+$ ]]; then
    echo "$d"
  else
    echo 10
  fi
}

##
# Project docstring root for crontab markers.
#
u_cron_project_marker() {
  echo "${PROJECT_DOCROOT:-$PWD}"
}

##
# Ensure crontab binary exists.
#
u_cron_require_crontab() {
  if ! command -v crontab >/dev/null 2>&1; then
    echo >&2 "Error: crontab program not found on this host."
    return 1
  fi
}

##
# Read current user crontab or empty.
#
u_cron_crontab_list() {
  crontab -l 2>/dev/null || true
}

##
# Rewrite managed CWT-CRON block for this project.
#
# @param 1 String : block body (lines without markers); empty removes block.
#
u_cron_crontab_write_block() {
  local body="$1"
  local marker
  local begin
  local end
  local tmp
  local current
  local filtered

  u_cron_require_crontab || return 1
  marker="$(u_cron_project_marker)"
  begin="# CWT-CRON-BEGIN ${marker}"
  end="# CWT-CRON-END ${marker}"
  tmp="$(mktemp)"
  current="$(u_cron_crontab_list)"

  filtered="$(printf '%s\n' "$current" | awk -v b="$begin" -v e="$end" '
    $0 == b {skip=1; next}
    $0 == e {skip=0; next}
    !skip {print}
  ')"

  {
    printf '%s\n' "$filtered"
    if [[ -n "$body" ]]; then
      printf '%s\n' "$begin"
      printf '%s\n' "$body"
      printf '%s\n' "$end"
    fi
  } | sed '/^$/N;/^\n$/D' > "$tmp"

  crontab "$tmp"
  rm -f "$tmp"
}

##
# Build crontab lines for one loaded entry (CWT_CRON_* must be set).
#
u_cron_entry_crontab_lines() {
  local sched
  local IFS=';'
  local lines=()

  if [[ "${CWT_CRON_ENABLED}" != 'true' ]]; then
    return 0
  fi

  for sched in ${CWT_CRON_SCHEDULE}; do
    [[ -z "$sched" ]] && continue
    lines+=("${sched} cd $(u_cron_project_marker) && make cron-run e:${CWT_CRON_ENTRY}")
  done

  printf '%s\n' "${lines[@]}"
}

##
# Sync host crontab for all enabled generated entries.
#
# Optional arg e:<entry> is accepted for API symmetry; always rewrites the full
# enabled set (use cron-stop / cron-start for single-entry host edits).
#
u_cron_sync() {
  local f
  local body=''
  local chunk

  u_cron_require_crontab || return 1

  if [[ ! -d scripts/cwt/local/cron ]]; then
    echo >&2 "No generated cron definitions. Run make reinit first."
    return 1
  fi

  body=''
  for f in scripts/cwt/local/cron/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${CWT_CRON_ENABLED}" == 'true' ]] || continue
    chunk="$(u_cron_entry_crontab_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'
'
  done

  u_cron_crontab_write_block "$(printf '%s' "$body")"
  echo "Host crontab synced for $(u_cron_project_marker)."
}

##
# Remove one entry's lines from managed block (keep others).
#
u_cron_stop_entry() {
  local p_entry="${1#e:}"
  local f
  local body=''
  local chunk

  u_cron_require_crontab || return 1

  for f in scripts/cwt/local/cron/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${CWT_CRON_ENABLED}" == 'true' ]] || continue
    [[ "$CWT_CRON_ENTRY" == "$p_entry" ]] && continue
    chunk="$(u_cron_entry_crontab_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'\n'
  done

  u_cron_crontab_write_block "$(printf '%s' "$body")"
  echo "Stopped cron host lines for '$p_entry'."
}

##
# Ensure one entry's lines are installed (full rewrite of enabled set including it).
#
u_cron_start_entry() {
  local p_entry="${1#e:}"

  if ! u_cron_entry_load "$p_entry"; then
    echo >&2 "Unknown cron entry: $p_entry"
    return 1
  fi

  u_cron_sync
  echo "Started/synced cron including '$p_entry'."
}
