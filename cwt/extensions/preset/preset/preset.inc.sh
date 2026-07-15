#!/usr/bin/env bash

##
# @file
# Preset-related Bash utilities.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Absolute path to the CWT preset root (cwt/extensions/preset/preset).
#
# Writes to preset_root in calling scope.
#
u_preset_root() {
  if [[ -n "${PROJECT_DOCROOT:-}" && -d "$PROJECT_DOCROOT/cwt/extensions/preset/preset" ]]; then
    preset_root="$PROJECT_DOCROOT/cwt/extensions/preset/preset"
  elif [[ -d "cwt/extensions/preset/preset" ]]; then
    preset_root="$(cd cwt/extensions/preset/preset && pwd)"
  else
    preset_root=''
    echo "Error in u_preset_root() - $BASH_SOURCE line $LINENO: cwt/extensions/preset/preset not found." >&2
    return 1
  fi
}

##
# Classify a pack directory name under cwt/extensions/preset/preset/.
#
# Writes to preset_pack_layer in calling scope: cwt-meta|subject|project|skip
#
u_preset_pack_layer() {
  local p_pack="$1"

  case "$p_pack" in
    cwt) preset_pack_layer='cwt-meta' ;;
    11ty) preset_pack_layer='project' ;;
    app|db|cache|front|index|vcs|thread|loop|log|crontab|chain|parallel) preset_pack_layer='subject' ;;
    *) preset_pack_layer='skip' ;;
  esac
}

##
# Extract {{ TOKEN }} names from a file (space-separated unique list).
#
# Writes to preset_file_tokens in calling scope.
#
u_preset_file_tokens() {
  local p_file="$1"
  local hay=''
  local token=''
  local seen=' '

  preset_file_tokens=''

  [[ -f "$p_file" ]] || return 0

  u_fs_get_file_contents "$p_file" 'hay'

  while [[ "$hay" =~ \{\{[[:space:]]*([A-Za-z0-9_/<>-]+)[[:space:]]*\}\} ]]; do
    token="${BASH_REMATCH[1]}"
    case "$token" in
      \<*|*/*\> ) ;;
      *)
        case "$seen" in *" $token "*) ;;
          *)
            seen+="$token "
            preset_file_tokens+="$token "
            ;;
        esac
        ;;
    esac
    hay="${hay#*"${BASH_REMATCH[0]}"}"
  done

  preset_file_tokens="${preset_file_tokens% }"
}

##
# Detect provision/host variant segments in a preset filename.
#
# Writes to preset_file_variants in calling scope (space-separated).
#
u_preset_file_variants() {
  local p_base="$1"
  local stem="${p_base%%.tpl*}"
  local part
  local known
  local variants=''

  known=" ${HOST_OS:-} ${HOST_TYPE:-} ${PROVISION_USING:-} ${INSTANCE_TYPE:-} compose docker-compose "

  IFS='.' read -r -a _preset_parts <<< "$stem"
  for part in "${_preset_parts[@]}"; do
    case "$part" in
      ''|hook) continue ;;
    esac
    case "$known" in *" $part "*)
      variants+="$part "
      ;;
    esac
  done

  case ".$stem." in
    *.compose.*)
      case " $variants " in *" compose "*) ;; *) variants+="compose " ;; esac
      ;;
  esac
  case ".$stem." in
    *.docker-compose.*)
      case " $variants " in *" docker-compose "*) ;; *) variants+="docker-compose " ;; esac
      ;;
  esac

  preset_file_variants="${variants% }"
}

##
# Whether a preset file applies on the current host (variant filter).
#
# Return 0 = applies, 1 = skip.
#
u_preset_file_applies_now() {
  local p_variants="$1"
  local v
  local ok=1
  local provision="${PROVISION_USING:-}"

  if [[ -z "$p_variants" ]]; then
    return 0
  fi

  for v in $p_variants; do
    ok=1
    case "$v" in
      compose)
        case "$provision" in compose|docker-compose) ok=0 ;; esac
        ;;
      docker-compose)
        case "$provision" in docker-compose) ok=0 ;; esac
        ;;
      "${HOST_OS:-}") ok=0 ;;
      "${HOST_TYPE:-}") ok=0 ;;
      "${INSTANCE_TYPE:-}") ok=0 ;;
      "${PROVISION_USING:-}") ok=0 ;;
      *) ok=1 ;;
    esac
    if [[ $ok -ne 0 ]]; then
      return 1
    fi
  done

  return 0
}

##
# Builds the discover catalog into preset_catalog_lines (newline-separated).
#
# Each line:
#   path=... layer=... pack=... variants=... applies=yes|no tokens=...
#
u_preset_catalog() {
  local pack
  local layer
  local f
  local rel
  local base
  local variants
  local applies
  local tokens
  local file_list

  u_preset_root || return 1

  preset_catalog_lines=''

  for pack in "$preset_root"/*; do
    [[ -d "$pack" ]] || continue
    pack="${pack##*/}"
    u_preset_pack_layer "$pack"
    layer="$preset_pack_layer"
    [[ "$layer" == 'skip' ]] && continue

    case "$layer" in
      project)
        preset_catalog_lines+="path=cwt/extensions/preset/preset/$pack layer=$layer pack=$pack variants= applies=yes tokens=PROJECT_PATH,PROJECT_NAME,SHORT_NAME,HOSTNAME"$'\n'
        ;;
      cwt-meta|subject)
        file_list=''
        u_fs_file_list "$preset_root/$pack" '*' 4
        for f in $file_list; do
          case "$f" in
            *.tpl*) ;;
            *)
              # cwt-meta drafts may use {{ }} without a .tpl suffix
              # (e.g. cwt/cwt/action.test.sh).
              if [[ "$layer" == 'cwt-meta' && -f "$preset_root/$pack/$f" ]] \
                && grep -q '{{ ' "$preset_root/$pack/$f" 2>/dev/null; then
                :
              else
                continue
              fi
              ;;
          esac

          rel="cwt/extensions/preset/preset/$pack/$f"
          base="${f##*/}"
          u_preset_file_variants "$base"
          variants="$preset_file_variants"
          if u_preset_file_applies_now "$variants"; then
            applies='yes'
          else
            applies='no'
          fi
          u_preset_file_tokens "$preset_root/$pack/$f"
          tokens="${preset_file_tokens// /,}"
          preset_catalog_lines+="path=$rel layer=$layer pack=$pack variants=${variants// /,} applies=$applies tokens=$tokens"$'\n'
        done
        ;;
    esac
  done
}

##
# Host-filtered catalog (applies=yes only) → preset_list_lines.
#
u_preset_list() {
  local line

  u_preset_catalog || return 1
  preset_list_lines=''

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    case "$line" in
      *'applies=yes'*)
        preset_list_lines+="$line"$'\n'
        ;;
    esac
  done <<< "$preset_catalog_lines"
}

##
# Select files from a preset pack dir that apply now.
#
# Writes space-separated relative paths to preset_selected_files.
#
# @param 1 String : pack name or absolute/relative pack dir.
#
u_preset_select_files() {
  local p_pack="$1"
  local pack_dir
  local f
  local base
  local file_list

  u_preset_root || return 1

  if [[ -d "$p_pack" ]]; then
    pack_dir="$p_pack"
  else
    pack_dir="$preset_root/$p_pack"
  fi

  if [[ ! -d "$pack_dir" ]]; then
    echo "Error in u_preset_select_files() - $BASH_SOURCE line $LINENO: pack dir '$pack_dir' not found." >&2
    return 1
  fi

  preset_selected_files=''
  file_list=''
  u_fs_file_list "$pack_dir" '*' 99

  for f in $file_list; do
    case "$f" in *.tpl*)
      base="${f##*/}"
      u_preset_file_variants "$base"
      if u_preset_file_applies_now "$preset_file_variants"; then
        preset_selected_files+="$f "
      fi
      ;;
    *)
      if [[ -f "$pack_dir/$f" ]]; then
        preset_selected_files+="$f "
      fi
      ;;
    esac
  done

  preset_selected_files="${preset_selected_files% }"
}

##
# Apply {{ TOKEN }} replacements in a file using keys from preset_tokens assoc.
#
u_preset_expand_tokens_in_file() {
  local p_file="$1"
  local key
  local val
  local token_prefix='{{ '
  local token_suffix=' }}'

  [[ -f "$p_file" ]] || return 1

  if declare -p preset_tokens &>/dev/null; then
    for key in "${!preset_tokens[@]}"; do
      val="${preset_tokens[$key]}"
      if grep -Fq "${token_prefix}${key}${token_suffix}" "$p_file"; then
        val="${val//\\/\\\\}"
        val="${val//&/\\&}"
        sed -e "s,${token_prefix}${key}${token_suffix},${val},g" -i "$p_file"
      fi
    done
  fi

  u_global_list 2>/dev/null || true
  if [[ ${#cwt_globals_var_names[@]} -gt 0 ]]; then
    for key in "${cwt_globals_var_names[@]}"; do
      if grep -Fq "${token_prefix}${key}${token_suffix}" "$p_file"; then
        val="${!key}"
        val="${val//\\/\\\\}"
        val="${val//&/\\&}"
        sed -e "s,${token_prefix}${key}${token_suffix},${val},g" -i "$p_file"
      fi
    done
  fi
}

##
# Strip optional example blocks from action.tpl style files when unused.
#
u_preset_strip_blocks() {
  local p_file="$1"
  local p_blocks="$2"
  local b
  local start
  local end
  local tmp

  [[ -f "$p_file" ]] || return 1

  for b in $p_blocks; do
    start="{{ <$b> }}"
    end="{{ </$b> }}"
    if grep -Fq "$start" "$p_file" && grep -Fq "$end" "$p_file"; then
      tmp="$(mktemp)"
      awk -v s="$start" -v e="$end" '
        index($0, s) {skip=1; next}
        index($0, e) {skip=0; next}
        !skip {print}
      ' "$p_file" > "$tmp"
      mv "$tmp" "$p_file"
    fi
  done
}

##
# Derive destination path for a subject template relative to PROJECT_DOCROOT.
#
# Uses COMPONENT / SERVICE from preset_tokens. Writes preset_dest_rel.
#
u_preset_default_dest() {
  local p_src="$1"
  local base="${p_src##*/}"
  local stem
  local component="${preset_tokens[COMPONENT]:-component}"
  local service="${preset_tokens[SERVICE]:-default}"
  local out=''

  stem="$base"
  stem="${stem%.tpl.sh}"
  stem="${stem%.tpl}"

  case "$stem" in
    *.compose.hook)
      stem="${stem%.compose.hook}.hook"
      ;;
    *.compose.hook)
      stem="${stem%.compose.hook}.hook"
      ;;
    *.compose)
      stem="${stem%.compose}"
      ;;
    *.docker-compose)
      stem="${stem%.docker-compose}"
      ;;
  esac

  case "$stem" in
    clear)
      out="scripts/cwt/extend/${component}/${service}_clear.sh"
      ;;
    index)
      out="scripts/cwt/extend/${component}/${service}_index.sh"
      ;;
    list_mandatory_globals.hook)
      out="scripts/cwt/extend/${component}/list_mandatory_globals.hook.sh"
      ;;
    *.crontab.yml)
      # Observability reserved jobs → crontab extension discovery tree.
      out="cwt/extensions/crontab/${component}/${stem}"
      ;;
    wrap)
      case "$component" in
        # No cwt/chain/ — chain is instance/chain.sh → thread/sequence.sh only.
        thread|loop|parallel) out="cwt/${component}/wrap.sh" ;;
        *) out="scripts/cwt/extend/${component}/wrap.sh" ;;
      esac
      ;;
    logged_loop|logged_chain|logged_sequence|logged_batch|logged_pipe|logged_parallel)
      # logged_parallel kept for legacy ideal stems; prefer logged_batch.
      out="cwt/instance/${stem}.sh"
      ;;
    *.hook)
      case "$component" in
        thread|loop) out="cwt/${component}/${stem}.sh" ;;
        *) out="scripts/cwt/extend/${component}/${stem}.sh" ;;
      esac
      ;;
    *)
      case "$component" in
        batch|pipe|sequence)
          # Operators live on the thread subject (sequence/batch/pipe scripts).
          out="cwt/thread/${stem}.sh"
          ;;
        thread|loop|parallel)
          out="cwt/${component}/${stem}.sh"
          ;;
        *)
          out="scripts/cwt/extend/${component}/${stem}.sh"
          ;;
      esac
      ;;
  esac

  preset_dest_rel="$out"
}

##
# Copy one preset file to dest and expand tokens.
#
# @param 1 String : source file path
# @param 2 String : destination file path (final)
#
u_preset_apply_file() {
  local p_src="$1"
  local p_dest="$2"
  local dest_dir

  if [[ ! -f "$p_src" ]]; then
    echo "Error in u_preset_apply_file() - $BASH_SOURCE line $LINENO: source '$p_src' not found." >&2
    return 1
  fi

  if [[ -z "$p_dest" ]]; then
    echo "Error in u_preset_apply_file() - $BASH_SOURCE line $LINENO: destination required." >&2
    return 2
  fi

  dest_dir="$(dirname "$p_dest")"
  mkdir -p "$dest_dir"

  cp "$p_src" "$p_dest" || return 3

  if declare -p preset_tokens &>/dev/null; then
    preset_tokens[TEMPLATE]="$p_src"
  fi

  u_preset_expand_tokens_in_file "$p_dest"
  echo "Wrote $p_dest (from $p_src)"
}

##
# Sync a preset directory into a destination directory (custom rsync).
#
# Keeps source. Overwrites dest by default. Expands tokens in files with {{ }}.
#
# @param 1 String : source dir
# @param 2 String : destination dir
# @param 3 [optional] String : 'no' to skip overwriting existing files.
#
u_preset_sync_dir() {
  local p_src="$1"
  local p_dest="$2"
  local p_overwrite="${3:-yes}"
  local f
  local file_list=''
  local dest_file
  local leaf

  if [[ -z "$p_src" || ! -d "$p_src" || -z "$p_dest" ]]; then
    echo "Error in u_preset_sync_dir() - $BASH_SOURCE line $LINENO: invalid arguments." >&2
    return 1
  fi

  mkdir -p "$p_dest"

  u_fs_file_list "$p_src" '*' 99

  for f in $file_list; do
    dest_file="$p_dest/$f"
    leaf="${f##*/}"
    case "$leaf" in
      .bash_aliases.tpl)
        dest_file="$(dirname "$dest_file")/.bash_aliases"
        ;;
      *.tpl)
        dest_file="${dest_file%.tpl}"
        ;;
      *.tpl.sh)
        dest_file="${dest_file%.tpl.sh}.sh"
        ;;
    esac

    if [[ -f "$dest_file" ]]; then
      case "$p_overwrite" in n*|N*) continue ;; esac
    fi

    mkdir -p "$(dirname "$dest_file")"
    cp "$p_src/$f" "$dest_file" || return 2

    if grep -q '{{ ' "$dest_file" 2>/dev/null; then
      u_preset_expand_tokens_in_file "$dest_file"
    fi
    echo "Wrote $dest_file"
  done
}

##
# Write a CWT action from cwt/extensions/preset/preset/cwt/action.tpl.sh.
#
# @param 1 String : subject
# @param 2 String : action
# @param 3 [optional] String : namespace — cwt|extend (default heuristic)
# @param 4 [optional] String : docblock one-liner
# @param 5 [optional] String : action body
#
u_preset_write_action() {
  local p_subject="$1"
  local p_action="$2"
  local p_ns="${3:-}"
  local p_doc="${4:-$p_subject/$p_action entry point.}"
  local p_body="${5:-echo \"TODO: implement $p_subject/$p_action\"}"
  local tpl
  local dest
  local make_name
  local inc_tpl
  local inc_dest

  u_preset_root || return 1

  if [[ -z "$p_subject" || -z "$p_action" ]]; then
    echo "Usage: u_preset_write_action <subject> <action> [namespace] [docblock] [body]" >&2
    return 1
  fi

  if [[ -z "$p_ns" ]]; then
    if [[ -d "cwt/$p_subject" ]]; then
      p_ns='cwt'
    else
      p_ns='extend'
    fi
  fi

  case "$p_ns" in
    cwt) dest="cwt/$p_subject/$p_action.sh" ;;
    extend) dest="scripts/cwt/extend/$p_subject/$p_action.sh" ;;
    *) dest="scripts/cwt/extend/$p_subject/$p_action.sh" ;;
  esac

  tpl="$preset_root/cwt/action.tpl.sh"
  if [[ ! -f "$tpl" ]]; then
    echo "Error: missing template $tpl" >&2
    return 2
  fi

  make_name="${p_subject}-${p_action}"
  make_name="${make_name//_/-}"

  declare -A preset_tokens=()
  preset_tokens[DOCBLOCK]="$p_doc"
  preset_tokens[SUBJECT_ACTION]="$make_name"
  preset_tokens[ACTION_PATH]="$dest"
  preset_tokens[ACTION]="$p_body"
  preset_tokens[COMMENT_DEFAULT]=''
  preset_tokens[COMMENT_WITH_ARGS]=''
  preset_tokens[ARGS_MAKE]=''
  preset_tokens[ARGS]=''
  preset_tokens[TEMPLATE]="$tpl"

  mkdir -p "$(dirname "$dest")"
  cp "$tpl" "$dest" || return 3

  u_preset_strip_blocks "$dest" 'WITH_ARGS'
  u_preset_expand_tokens_in_file "$dest"
  sed -i \
    -e '/{{ <DEFAULT> }}/d' \
    -e '/{{ <\/DEFAULT> }}/d' \
    -e '/{{ <WITH_ARGS> }}/d' \
    -e '/{{ <\/WITH_ARGS> }}/d' \
    "$dest"

  echo "Wrote $dest"

  case "$p_ns" in
    cwt) inc_dest="cwt/$p_subject/$p_subject.inc.sh" ;;
    extend) inc_dest="scripts/cwt/extend/$p_subject/$p_subject.inc.sh" ;;
    *) inc_dest='' ;;
  esac

  inc_tpl="$preset_root/cwt/subject.inc.tpl.sh"
  if [[ -n "$inc_dest" && ! -f "$inc_dest" && -f "$inc_tpl" ]]; then
    declare -A preset_tokens=()
    preset_tokens[DOCBLOCK]="$p_subject utility functions."
    preset_tokens[SUBJECT]="# TODO u_${p_subject}_* helpers"
    preset_tokens[TEMPLATE]="$inc_tpl"
    mkdir -p "$(dirname "$inc_dest")"
    cp "$inc_tpl" "$inc_dest"
    u_preset_expand_tokens_in_file "$inc_dest"
    echo "Wrote $inc_dest"
  fi

  echo
  echo "Notice: run 'make reinit' so make targets / CWT cache pick up new actions."
}

##
# Write a subject pack into scripts/cwt/extend.
#
# @param 1 String : pack name
# @param 2 [optional] String : COMPONENT (default = pack)
# @param 3 [optional] String : SERVICE (default = default)
#
u_preset_write_subject() {
  local p_pack="$1"
  local p_component="${2:-$1}"
  local p_service="${3:-default}"
  local f
  local src
  local dest

  u_preset_root || return 1

  if [[ ! -d "$preset_root/$p_pack" ]]; then
    echo "Error: unknown subject pack '$p_pack'." >&2
    return 1
  fi

  declare -A preset_tokens=()
  preset_tokens[COMPONENT]="$p_component"
  preset_tokens[SERVICE]="$p_service"
  preset_tokens[TEMPLATE]=''

  u_preset_select_files "$p_pack"

  for f in $preset_selected_files; do
    case "$f" in *.tpl*) ;; *) continue ;; esac
    src="$preset_root/$p_pack/$f"
    u_preset_default_dest "$f"
    dest="$preset_dest_rel"
    preset_tokens[TEMPLATE]="$src"
    u_preset_apply_file "$src" "$dest"
  done

  echo
  echo "Notice: run 'make reinit' if new actions were added under scripts/cwt/extend."
}

##
# Write a project scaffold pack into a destination docroot.
#
# Replaces the old u_preset_template() API ($sl_dir removed).
#
# @param 1 String : pack name under cwt/extensions/preset/preset/
# @param 2 String : destination project path
# @param 3–5 [optional] project name, short name, hostname
#
u_preset_write_project() {
  local p_pack="$1"
  local p_dest="$2"
  local p_name="${3:-}"
  local p_short="${4:-}"
  local p_host="${5:-}"

  u_preset_root || return 1

  if [[ -z "$p_pack" || -z "$p_dest" ]]; then
    echo "Usage: u_preset_write_project <pack> <dest_dir> [name] [short] [hostname]" >&2
    return 1
  fi

  if [[ ! -d "$preset_root/$p_pack" ]]; then
    echo "Error: unknown project pack '$p_pack'." >&2
    return 2
  fi

  if [[ -z "$p_name" ]]; then
    p_name="${p_dest##*/}"
  fi
  if [[ -z "$p_short" ]]; then
    p_short="$p_name"
    u_str_sanitize_var_name "$p_short" 'p_short'
    u_str_lowercase "$p_short" 'p_short'
  fi
  if [[ -z "$p_host" ]]; then
    p_host="$p_name"
    u_str_sanitize "$p_host" '-' 'p_host'
    u_str_lowercase "$p_host" 'p_host'
  fi

  mkdir -p "$p_dest"

  declare -A preset_tokens=()
  preset_tokens[PROJECT_PATH]="$p_dest"
  preset_tokens[PROJECT_NAME]="$p_name"
  preset_tokens[SHORT_NAME]="$p_short"
  preset_tokens[HOSTNAME]="$p_host"
  preset_tokens[TEMPLATE]="cwt/extensions/preset/preset/$p_pack"

  u_preset_sync_dir "$preset_root/$p_pack" "$p_dest"
}

##
# Write host-matching defaults for subject packs (COMPONENT=pack name).
#
u_preset_write_defaults() {
  local pack

  u_preset_root || return 1

  for pack in app db cache front index vcs; do
    [[ -d "$preset_root/$pack" ]] || continue
    echo "=== defaults: subject pack $pack ==="
    u_preset_write_subject "$pack" "$pack" 'default'
  done
}

##
# Back-compat wrapper around u_preset_write_project (old name).
#
u_preset_template() {
  local p_template="$1"
  local p_project_path="$2"
  shift 2 2>/dev/null || true
  u_preset_write_project "$p_template" "$p_project_path" "$@"
}
