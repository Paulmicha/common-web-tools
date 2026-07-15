#!/usr/bin/env bash

##
# Lists nested CWT project instances (layout maps only).
#
# Default (no args): find nested CWT PROJECT_DOCROOTs under $HOME/Documents
# (depth 1–2) and print a layout map for each.
#
# With one ref arg: print that instance only. Ref may be a short id (directory
# basename), a parent-qualified id on collision (e.g. client/my-project), or
# a filesystem path.
#
# Layout reflects multi-app instances via CWT_APPS (each app has
# {APP}_DOCROOT / {APP}_SERVER_DOCROOT). Falls back to legacy single-app
# APP_DOCROOT / SERVER_DOCROOT when CWT_APPS is empty.
#
# Print/layout helpers stay in this file. Find/resolve come from subject-wide
# nested_cwt.opt-inc.sh via bootstrap phase 90 (caller opt-inc auto-load).
# Optional list.opt-inc.sh would load after that if present.
#
# For virgin-env command execution in a nested instance, see:
#   cwt/extensions/nested_cwt/nested_cwt/exec.sh
#
# @param 1 [optional] String : nested instance ref (short id, qualified id, or path).
#
# @example
#   make nested-cwt-list
#   # Or :
#   cwt/extensions/nested_cwt/nested_cwt/list.sh
#
#   make nested-cwt-list my-project
#   # Or :
#   cwt/extensions/nested_cwt/nested_cwt/list.sh my-project
#
#   # Collision : qualify with a parent folder name.
#   make nested-cwt-list client/my-project
#

. cwt/bootstrap.sh

##
# Strip surrounding quotes from a .env / yaml scalar (local helper).
#
_u_nested_cwt_unquote() {
  local v="$1"
  v="${v#\'}"
  v="${v%\'}"
  v="${v#\"}"
  v="${v%\"}"
  printf '%s' "$v"
}

##
# Load nested instance app map from child .env or env.yml (local only).
#
_u_nested_cwt_load_apps() {
  local p_docroot="$1"
  local line
  local key
  local val
  local app_u

  nested_cwt_apps=''
  nested_cwt_legacy_app=''
  nested_cwt_legacy_server=''

  if [[ -f "$p_docroot/.env" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        'CWT_APPS='*)
          val="$(_u_nested_cwt_unquote "${line#CWT_APPS=}")"
          nested_cwt_apps="$val"
          ;;
        'APP_DOCROOT='*)
          nested_cwt_legacy_app="$(_u_nested_cwt_unquote "${line#APP_DOCROOT=}")"
          ;;
        'SERVER_DOCROOT='*)
          nested_cwt_legacy_server="$(_u_nested_cwt_unquote "${line#SERVER_DOCROOT=}")"
          ;;
        *_DOCROOT=*|*_SERVER_DOCROOT=*)
          key="${line%%=*}"
          val="$(_u_nested_cwt_unquote "${line#*=}")"
          case "$key" in
            *_SERVER_DOCROOT)
              app_u="${key%_SERVER_DOCROOT}"
              printf -v "nested_cwt_app_server_${app_u}" '%s' "$val"
              ;;
            *_DOCROOT)
              app_u="${key%_DOCROOT}"
              case "$app_u" in PROJECT|APP) continue ;; esac
              printf -v "nested_cwt_app_docroot_${app_u}" '%s' "$val"
              ;;
          esac
          ;;
      esac
    done < "$p_docroot/.env"
  elif [[ -f "$p_docroot/env.yml" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        cwt_apps:*|'cwt_apps:'*)
          val="${line#*:}"
          val="${val#"${val%%[![:space:]]*}"}"
          val="${val%"${val##*[![:space:]]}"}"
          nested_cwt_apps="$(_u_nested_cwt_unquote "$val")"
          ;;
        app_docroot:*|'app_docroot:'*)
          val="${line#*:}"
          val="${val#"${val%%[![:space:]]*}"}"
          val="${val%"${val##*[![:space:]]}"}"
          nested_cwt_legacy_app="$(_u_nested_cwt_unquote "$val")"
          ;;
        server_docroot:*|'server_docroot:'*)
          val="${line#*:}"
          val="${val#"${val%%[![:space:]]*}"}"
          val="${val%"${val##*[![:space:]]}"}"
          nested_cwt_legacy_server="$(_u_nested_cwt_unquote "$val")"
          ;;
      esac
    done < "$p_docroot/env.yml"
  fi
}

##
# Print one app branch under the project tree.
#
_u_nested_cwt_print_app() {
  local p_docroot="$1"
  local p_app="$2"
  local p_is_last="$3"
  local app_u
  local doc_var
  local srv_var
  local doc_rel
  local srv_rel
  local srv_under
  local branch
  local nest

  u_str_uppercase "$p_app" 'app_u'
  doc_var="nested_cwt_app_docroot_${app_u}"
  srv_var="nested_cwt_app_server_${app_u}"
  doc_rel="${!doc_var:-$p_app}"
  srv_rel="${!srv_var:-}"

  doc_rel="${doc_rel#$p_docroot/}"
  srv_rel="${srv_rel#$p_docroot/}"

  if [[ "$p_is_last" == '1' ]]; then
    branch='└──'
    nest='    '
  else
    branch='├──'
    nest='│   '
  fi

  if [[ -d "$p_docroot/$doc_rel" ]]; then
    echo "  ${branch} ${doc_rel}/              ← App \"${p_app}\" (\$${app_u}_DOCROOT)"
    if [[ -n "$srv_rel" ]]; then
      case "$srv_rel" in
        "${doc_rel}/"*)
          srv_under="${srv_rel#${doc_rel}/}"
          if [[ -d "$p_docroot/$srv_rel" ]]; then
            echo "  ${nest}└── ${srv_under}/          ← Public web (\$${app_u}_SERVER_DOCROOT)"
          else
            echo "  ${nest}└── ${srv_under}/          ← [optional] \$${app_u}_SERVER_DOCROOT — missing"
          fi
          ;;
        *)
          if [[ -d "$p_docroot/$srv_rel" ]]; then
            echo "  ${nest}└── ${srv_rel}/          ← Public web (\$${app_u}_SERVER_DOCROOT)"
          else
            echo "  ${nest}└── ${srv_rel}/          ← [optional] \$${app_u}_SERVER_DOCROOT — missing"
          fi
          ;;
      esac
    else
      echo "  ${nest}└── (no \$${app_u}_SERVER_DOCROOT) ← [optional]"
    fi
  else
    echo "  ${branch} ${doc_rel}/              ← App \"${p_app}\" (\$${app_u}_DOCROOT) — missing"
  fi
}

##
# Prints a layout map for one nested CWT PROJECT_DOCROOT.
#
# @param 1 String : absolute path to the nested project root.
# @param 2 [optional] String : short id to display (default: basename).
#
u_nested_cwt_print() {
  local p_docroot="$1"
  local p_short_id="${2:-}"
  local app
  local leg_app
  local leg_srv

  if [[ -z "$p_docroot" || ! -d "$p_docroot" ]]; then
    echo "Error in u_nested_cwt_print() - $BASH_SOURCE line $LINENO: invalid docroot '$p_docroot'." >&2
    return 1
  fi

  if [[ ! -f "$p_docroot/cwt/bootstrap.sh" ]]; then
    echo "Error in u_nested_cwt_print() - $BASH_SOURCE line $LINENO: not a CWT instance ('$p_docroot/cwt/bootstrap.sh' missing)." >&2
    return 2
  fi

  if [[ -z "$p_short_id" ]]; then
    p_short_id="${p_docroot##*/}"
  fi

  _u_nested_cwt_load_apps "$p_docroot"

  echo "${p_short_id}  ${p_docroot}/     ← Project root (\$PROJECT_DOCROOT)"

  if [[ -n "$nested_cwt_apps" ]]; then
    for app in $nested_cwt_apps; do
      _u_nested_cwt_print_app "$p_docroot" "$app" 0
    done
  elif [[ -n "$nested_cwt_legacy_app" ]]; then
    leg_app="$nested_cwt_legacy_app"
    leg_srv="${nested_cwt_legacy_server:-}"
    leg_app="${leg_app#$p_docroot/}"
    leg_srv="${leg_srv#$p_docroot/}"
    if [[ -d "$p_docroot/$leg_app" ]]; then
      echo "  ├── ${leg_app}/              ← Application dir (\$APP_DOCROOT)"
      if [[ -n "$leg_srv" && -d "$p_docroot/$leg_srv" ]]; then
        case "$leg_srv" in
          "${leg_app}/"*)
            echo "  │   └── ${leg_srv#${leg_app}/}/          ← Public web (\$SERVER_DOCROOT)"
            ;;
          *)
            echo "  │   └── ${leg_srv}/          ← Public web (\$SERVER_DOCROOT)"
            ;;
        esac
      else
        echo "  │   └── (no \$SERVER_DOCROOT) ← [optional+configurable]"
      fi
    else
      echo "  ├── ${leg_app}/              ← Application dir (\$APP_DOCROOT) — missing"
    fi
  else
    echo "  ├── (no CWT_APPS / APP_DOCROOT) ← [optional] declare apps in .env"
  fi

  echo "  ├── cwt/              ← CWT \"core\" source files. Update = delete + replace entire folder"

  if [[ -d "$p_docroot/scripts" ]]; then
    echo "  ├── scripts/          ← Current project specific scripts"
    if [[ -d "$p_docroot/scripts/cwt" ]]; then
      echo "  │   └── cwt/          ← CWT-related project-specific extension, local files and overrides"
      if [[ -d "$p_docroot/scripts/cwt/extend" ]]; then
        echo "  │       ├── extend/   ← Custom project-specific CWT extension"
      else
        echo "  │       ├── extend/   ← [optional] missing"
      fi
      if [[ -d "$p_docroot/scripts/cwt/local" ]]; then
        echo "  │       ├── local/    ← [git-ignored] Generated files specific to this local instance"
      else
        echo "  │       ├── local/    ← [git-ignored] missing"
      fi
      if [[ -d "$p_docroot/scripts/cwt/override" ]]; then
        echo "  │       └── override/ ← Allows to replace virtually any file sourced in CWT scripts"
      else
        echo "  │       └── override/ ← [optional] missing"
      fi
    else
      echo "  │   └── cwt/          ← [optional] missing"
    fi
  else
    echo "  ├── scripts/          ← [optional] missing"
  fi

  if [[ -f "$p_docroot/.gitignore" ]]; then
    echo "  ├── .gitignore        ← Present"
  else
    echo "  ├── .gitignore        ← missing"
  fi

  if [[ -f "$p_docroot/Makefile" ]]; then
    echo "  ├── Makefile          ← The \"make\" entry point"
  else
    echo "  ├── Makefile          ← missing"
  fi

  echo "  └── ..."
  echo
}

# Map one or many.
case "$1" in
  '')
    u_nested_cwt_find
    if [[ -z "$nested_cwt_instances" ]]; then
      echo "No nested CWT instances found under $HOME/Documents."
      exit 0
    fi
    echo "Nested CWT instances (ref → path):"
    echo
    for _nested_docroot in $nested_cwt_instances; do
      u_nested_cwt_short_id "$_nested_docroot" "$nested_cwt_instances"
      u_nested_cwt_print "$_nested_docroot" "$nested_cwt_short_id"
    done
    ;;

  *)
    if ! u_nested_cwt_resolve "$1"; then
      exit $?
    fi
    u_nested_cwt_short_id "$nested_cwt_resolved" "$nested_cwt_instances"
    u_nested_cwt_print "$nested_cwt_resolved" "$nested_cwt_short_id"
    exit $?
    ;;
esac
