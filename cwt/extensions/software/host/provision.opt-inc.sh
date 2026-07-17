#!/usr/bin/env bash

##
# Software provision helpers (manifest → status diff → apply).
#
# Lazy include: seeded into hook.${key}.sh before host/provision.hook.sh (1a),
# and/or loaded via software/software/software.opt-inc.sh for software-* actions.
#
# @see cwt/extensions/software/host/provision.hook.sh
# @see cwt/utilities/hook.sh (u_hook_opt_inc_append_candidates)
# @see changelog/2026/07/16-cwt-include-splitting-hook-mapped-deps.md
#
# Convention : function names are prefixed by "u".
#

##
# Strip surrounding quotes left by bash-yaml scalars.
#
u_software_scalar() {
  local p_val="$1"
  local out="$p_val"

  out="${out#\"}"
  out="${out%\"}"
  out="${out#\'}"
  out="${out%\'}"

  echo "$out"
}

##
# Expand leading ~/ to $HOME.
#
u_software_expand_path() {
  local p_path="$1"
  local out

  out="$(u_software_scalar "$p_path")"

  case "$out" in
    '~'|'~/'*)
      out="${HOME}${out:1}"
      ;;
  esac

  echo "$out"
}

##
# Resolve prune flag from env and optional CLI args in calling scope.
#
# Sets SOFTWARE_PRUNE=1 when --prune is present in "$@".
#
u_software_parse_args() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      --prune)
        export SOFTWARE_PRUNE=1
        ;;
    esac
  done
}

##
# Paths to YAML manifests (default + optional local overlay).
#
# @var software_manifest_files
#
u_software_manifest_paths() {
  software_manifest_files=()

  if [[ -f scripts/cwt/extend/software/apps.manifest.yml ]]; then
    software_manifest_files+=('scripts/cwt/extend/software/apps.manifest.yml')
  fi

  if [[ -f cwt/extensions/software/apps.manifest.yml ]]; then
    software_manifest_files+=('cwt/extensions/software/apps.manifest.yml')
  fi

  if [[ -f data/cwt/software/apps.manifest.local.yml ]]; then
    software_manifest_files+=('data/cwt/software/apps.manifest.local.yml')
  fi
}

##
# Load and merge manifests into sw_* arrays (bash-yaml).
#
u_software_load_manifests() {
  local f
  local parsed

  unset sw_apt sw_pipx \
    sw_tarball__id sw_tarball__version sw_tarball__url \
    sw_tarball__install_dir sw_tarball__binary \
    sw_appimage__id sw_appimage__url sw_appimage__sha256 sw_appimage__path \
    sw_ensure__id sw_ensure__command sw_ensure__method \
    sw_units__id sw_units__kind sw_units__template sw_units__enable \
    sw_units__requires 2>/dev/null || true

  sw_apt=()
  sw_pipx=()
  sw_tarball__id=()
  sw_tarball__version=()
  sw_tarball__url=()
  sw_tarball__install_dir=()
  sw_tarball__binary=()
  sw_appimage__id=()
  sw_appimage__url=()
  sw_appimage__sha256=()
  sw_appimage__path=()
  sw_ensure__id=()
  sw_ensure__command=()
  sw_ensure__method=()
  sw_units__id=()
  sw_units__kind=()
  sw_units__template=()
  sw_units__enable=()
  sw_units__requires=()

  u_software_manifest_paths

  if [[ ${#software_manifest_files[@]} -eq 0 ]]; then
    echo >&2
    echo "Error: no software manifests found." >&2
    echo "Expected scripts/cwt/extend/software/apps.manifest.yml" >&2
    echo >&2

    return 1
  fi

  for f in "${software_manifest_files[@]}"; do
    parsed="$(u_yaml_parse "$f" 'sw_')"
    eval "$parsed"
  done

  return 0
}

##
# Managed-state file path (gitignored under data/cwt).
#
u_software_managed_path() {
  echo 'data/cwt/software/managed.list'
}

##
# Ensure local software state dir exists.
#
u_software_ensure_state_dir() {
  mkdir -p data/cwt/software
}

##
# Record a managed install id (kind:name).
#
u_software_managed_add() {
  local p_id="$1"
  local path
  local line

  u_software_ensure_state_dir
  path="$(u_software_managed_path)"

  if [[ -f "$path" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "$p_id" ]]; then
        return 0
      fi
    done < "$path"
  fi

  echo "$p_id" >> "$path"
}

##
# Load managed ids into software_managed_ids array.
#
# @var software_managed_ids
#
u_software_managed_load() {
  local path
  local line

  software_managed_ids=()
  path="$(u_software_managed_path)"

  if [[ ! -f "$path" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    software_managed_ids+=("$line")
  done < "$path"
}

##
# Rewrite managed.list from software_managed_ids.
#
u_software_managed_save() {
  local path
  local id

  u_software_ensure_state_dir
  path="$(u_software_managed_path)"

  : > "$path"

  for id in "${software_managed_ids[@]}"; do
    echo "$id" >> "$path"
  done
}

##
# Remove one id from the managed list.
#
u_software_managed_remove() {
  local p_id="$1"
  local kept=()
  local id

  u_software_managed_load

  for id in "${software_managed_ids[@]}"; do
    if [[ "$id" != "$p_id" ]]; then
      kept+=("$id")
    fi
  done

  software_managed_ids=("${kept[@]}")
  u_software_managed_save
}

##
# Desired-state ids currently declared in loaded manifests.
#
# @var software_desired_ids
#
u_software_desired_ids() {
  local i
  local pkg
  local name

  software_desired_ids=()

  for pkg in "${sw_apt[@]}"; do
    pkg="$(u_software_scalar "$pkg")"
    [[ -n "$pkg" ]] && software_desired_ids+=("apt:$pkg")
  done

  for pkg in "${sw_pipx[@]}"; do
    pkg="$(u_software_scalar "$pkg")"
    name="${pkg%%==*}"
    [[ -n "$name" ]] && software_desired_ids+=("pipx:$name")
  done

  for ((i = 0; i < ${#sw_tarball__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_tarball__id[$i]}")"
    [[ -n "$name" ]] && software_desired_ids+=("tarball:$name")
  done

  for ((i = 0; i < ${#sw_appimage__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_appimage__id[$i]}")"
    [[ -n "$name" ]] && software_desired_ids+=("appimage:$name")
  done

  for ((i = 0; i < ${#sw_ensure__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_ensure__id[$i]}")"
    [[ -n "$name" ]] && software_desired_ids+=("ensure:$name")
  done

  for ((i = 0; i < ${#sw_units__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_units__id[$i]}")"
    [[ -n "$name" ]] && software_desired_ids+=("unit:$name")
  done
}

##
# Return 0 if id is in the desired set.
#
u_software_is_desired() {
  local p_id="$1"
  local id

  for id in "${software_desired_ids[@]}"; do
    if [[ "$id" == "$p_id" ]]; then
      return 0
    fi
  done

  return 1
}

##
# Apt package status: missing | ok
#
u_software_apt_status() {
  local p_pkg="$1"

  if dpkg-query -W -f='${Status}' "$p_pkg" 2>/dev/null | grep -q 'install ok installed'; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# pipx package status: missing | outdated | ok
#
# Spec is name or name==version.
#
u_software_pipx_status() {
  local p_spec="$1"
  local name
  local want_ver
  local have
  local have_ver

  name="${p_spec%%==*}"
  want_ver=''

  if [[ "$p_spec" == *==* ]]; then
    want_ver="${p_spec#*==}"
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    echo 'missing'
    return 0
  fi

  have="$(pipx list --short 2>/dev/null | awk -v n="$name" '$1 == n { print $2; exit }')"

  if [[ -z "$have" ]]; then
    echo 'missing'
    return 0
  fi

  have_ver="${have# }"

  if [[ -n "$want_ver" && "$have_ver" != "$want_ver" ]]; then
    echo 'outdated'
    return 0
  fi

  echo 'ok'
}

##
# Tarball app status via install_dir/.cwt-software-version
#
u_software_tarball_status() {
  local p_dir="$1"
  local p_version="$2"
  local p_binary="$3"
  local marker
  local have
  local bin_path

  marker="${p_dir}/.cwt-software-version"
  bin_path="${p_dir}/${p_binary}"

  if [[ ! -x "$bin_path" && ! -f "$bin_path" ]]; then
    echo 'missing'
    return 0
  fi

  if [[ -f "$marker" ]]; then
    have="$(tr -d '[:space:]' < "$marker")"

    if [[ "$have" == "$p_version" ]]; then
      echo 'ok'
      return 0
    fi

    echo 'outdated'
    return 0
  fi

  # Present without marker: treat as ok if binary exists (adopt on next apply).
  echo 'ok'
}

##
# AppImage status: missing | outdated | ok
#
u_software_appimage_status() {
  local p_path="$1"
  local p_sha="$2"
  local have

  if [[ ! -f "$p_path" ]]; then
    echo 'missing'
    return 0
  fi

  if [[ -n "$p_sha" ]]; then
    have="$(sha256sum "$p_path" | awk '{ print $1 }')"

    if [[ "$have" != "$p_sha" ]]; then
      echo 'outdated'
      return 0
    fi
  fi

  echo 'ok'
}

##
# Ensure-command status: missing | ok
#
u_software_ensure_status() {
  local p_cmd="$1"

  if command -v "$p_cmd" >/dev/null 2>&1; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# systemd --user unit status: missing | ok
#
u_software_unit_status() {
  local p_id="$1"

  if [[ -f "${HOME}/.config/systemd/user/${p_id}.service" ]]; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# Diff result arrays (parallel: software_diff_ids / software_diff_status).
#
# @var software_diff_ids
# @var software_diff_status
# @var software_diff_extra
#
u_software_build_diff() {
  local i
  local pkg
  local name
  local st
  local path
  local ver
  local url
  local sha
  local bin
  local dir
  local method
  local cmd
  local id

  software_diff_ids=()
  software_diff_status=()
  software_diff_extra=()

  u_software_desired_ids
  u_software_managed_load

  for pkg in "${sw_apt[@]}"; do
    pkg="$(u_software_scalar "$pkg")"
    [[ -z "$pkg" ]] && continue
    st="$(u_software_apt_status "$pkg")"
    software_diff_ids+=("apt:$pkg")
    software_diff_status+=("$st")
  done

  for pkg in "${sw_pipx[@]}"; do
    pkg="$(u_software_scalar "$pkg")"
    [[ -z "$pkg" ]] && continue
    name="${pkg%%==*}"
    st="$(u_software_pipx_status "$pkg")"
    software_diff_ids+=("pipx:$name")
    software_diff_status+=("$st")
  done

  for ((i = 0; i < ${#sw_tarball__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_tarball__id[$i]}")"
    ver="$(u_software_scalar "${sw_tarball__version[$i]}")"
    dir="$(u_software_expand_path "${sw_tarball__install_dir[$i]}")"
    bin="$(u_software_scalar "${sw_tarball__binary[$i]}")"
    [[ -z "$name" ]] && continue
    st="$(u_software_tarball_status "$dir" "$ver" "$bin")"
    software_diff_ids+=("tarball:$name")
    software_diff_status+=("$st")
  done

  for ((i = 0; i < ${#sw_appimage__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_appimage__id[$i]}")"
    path="$(u_software_expand_path "${sw_appimage__path[$i]}")"
    sha="$(u_software_scalar "${sw_appimage__sha256[$i]:-}")"
    [[ -z "$name" ]] && continue
    st="$(u_software_appimage_status "$path" "$sha")"
    software_diff_ids+=("appimage:$name")
    software_diff_status+=("$st")
  done

  for ((i = 0; i < ${#sw_ensure__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_ensure__id[$i]}")"
    cmd="$(u_software_scalar "${sw_ensure__command[$i]}")"
    [[ -z "$name" ]] && continue
    st="$(u_software_ensure_status "$cmd")"
    software_diff_ids+=("ensure:$name")
    software_diff_status+=("$st")
  done

  for ((i = 0; i < ${#sw_units__id[@]}; i++)); do
    name="$(u_software_scalar "${sw_units__id[$i]}")"
    [[ -z "$name" ]] && continue
    st="$(u_software_unit_status "$name")"
    software_diff_ids+=("unit:$name")
    software_diff_status+=("$st")
  done

  for id in "${software_managed_ids[@]}"; do
    if ! u_software_is_desired "$id"; then
      software_diff_extra+=("$id")
    fi
  done
}

##
# Print status diff summary.
#
u_software_print_diff() {
  local i
  local id
  local st
  local n_ok=0
  local n_missing=0
  local n_outdated=0

  echo
  echo "Software status (desired vs actual)"
  echo "------------------------------------"

  for ((i = 0; i < ${#software_diff_ids[@]}; i++)); do
    id="${software_diff_ids[$i]}"
    st="${software_diff_status[$i]}"
    printf '  %-28s %s\n' "$id" "$st"

    case "$st" in
      ok) n_ok=$((n_ok + 1)) ;;
      missing) n_missing=$((n_missing + 1)) ;;
      outdated) n_outdated=$((n_outdated + 1)) ;;
    esac
  done

  if [[ ${#software_diff_extra[@]} -gt 0 ]]; then
    echo
    echo "Extras (managed, not in manifest) — uninstall only with --prune:"

    for id in "${software_diff_extra[@]}"; do
      echo "  $id"
    done
  fi

  echo
  echo "Summary: ok=$n_ok missing=$n_missing outdated=$n_outdated extras=${#software_diff_extra[@]}"
  echo
}

##
# Run apt-get install for one package (sudo if needed).
#
u_software_apt_install() {
  local p_pkg="$1"

  if [[ "$(id -u)" -eq 0 ]]; then
    apt-get install -y "$p_pkg"
  else
    sudo apt-get install -y "$p_pkg"
  fi
}

##
# Install or upgrade a pipx package from name==version or name.
#
u_software_pipx_install() {
  local p_spec="$1"
  local name
  local st

  if ! command -v pipx >/dev/null 2>&1; then
    echo >&2 "Error: pipx not in PATH (install apt:pipx first)."
    return 1
  fi

  name="${p_spec%%==*}"
  st="$(u_software_pipx_status "$p_spec")"

  case "$st" in
    missing)
      pipx install "$p_spec"
      ;;
    outdated)
      pipx install --force "$p_spec"
      ;;
    *)
      return 0
      ;;
  esac
}

##
# Download + unpack a versioned tarball into install_dir.
#
u_software_tarball_install() {
  local p_id="$1"
  local p_version="$2"
  local p_url="$3"
  local p_dir="$4"
  local p_binary="$5"
  local url
  local tmp
  local archive
  local extracted

  url="${p_url//\{version\}/$p_version}"
  tmp="$(mktemp -d)"
  archive="${tmp}/${p_id}.tar.gz"

  echo "Downloading $p_id v$p_version ..."

  if ! curl -fsSL "$url" -o "$archive"; then
    rm -rf "$tmp"
    echo >&2 "Error: download failed for $url"
    return 1
  fi

  mkdir -p "$p_dir"
  tar -xzf "$archive" -C "$tmp"

  extracted="$(find "$tmp" -type f -name "$p_binary" | head -1)"

  if [[ -z "$extracted" || ! -f "$extracted" ]]; then
    rm -rf "$tmp"
    echo >&2 "Error: binary '$p_binary' not found in archive."
    return 1
  fi

  cp -a "$extracted" "${p_dir}/${p_binary}"
  chmod +x "${p_dir}/${p_binary}"
  echo "$p_version" > "${p_dir}/.cwt-software-version"
  rm -rf "$tmp"
}

##
# Download AppImage when URL is set.
#
u_software_appimage_install() {
  local p_id="$1"
  local p_url="$2"
  local p_sha="$3"
  local p_path="$4"
  local have
  local dir

  if [[ -z "$p_url" ]]; then
    echo >&2 "Skip appimage:$p_id — no url in manifest (file missing at $p_path)."
    return 1
  fi

  dir="$(dirname "$p_path")"
  mkdir -p "$dir"

  echo "Downloading appimage:$p_id ..."

  if ! curl -fsSL "$p_url" -o "$p_path"; then
    echo >&2 "Error: download failed for $p_url"
    return 1
  fi

  chmod +x "$p_path"

  if [[ -n "$p_sha" ]]; then
    have="$(sha256sum "$p_path" | awk '{ print $1 }')"

    if [[ "$have" != "$p_sha" ]]; then
      echo >&2 "Error: sha256 mismatch for $p_path"
      echo >&2 "  expected: $p_sha"
      echo >&2 "  got:      $have"
      return 1
    fi
  fi
}

##
# Ensure a command via a known install method.
#
u_software_ensure_install() {
  local p_id="$1"
  local p_cmd="$2"
  local p_method="$3"

  if command -v "$p_cmd" >/dev/null 2>&1; then
    return 0
  fi

  case "$p_method" in
    ollama_install_sh)
      echo "Installing ollama via official install script ..."
      curl -fsSL https://ollama.com/install.sh | sh
      ;;
    *)
      echo >&2 "Error: unknown ensure method '$p_method' for $p_id"
      return 1
      ;;
  esac

  if ! command -v "$p_cmd" >/dev/null 2>&1; then
    echo >&2 "Error: $p_cmd still missing after install."
    return 1
  fi
}

##
# Install a systemd --user unit from a template path.
#
u_software_unit_install() {
  local p_id="$1"
  local p_template="$2"
  local p_enable="$3"
  local dest
  local src

  src="$p_template"

  if [[ ! -f "$src" ]]; then
    if [[ -f "scripts/cwt/extend/software/${p_template}" ]]; then
      src="scripts/cwt/extend/software/${p_template}"
    elif [[ -f "cwt/extensions/software/${p_template}" ]]; then
      src="cwt/extensions/software/${p_template}"
    fi
  fi

  if [[ ! -f "$src" ]]; then
    echo >&2 "Error: unit template not found: $p_template"
    return 1
  fi

  dest="${HOME}/.config/systemd/user/${p_id}.service"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  systemctl --user daemon-reload

  case "$(u_software_scalar "$p_enable")" in
    true|yes|1)
      systemctl --user enable --now "${p_id}.service" || \
        systemctl --user enable "${p_id}.service"
      ;;
  esac
}

##
# Apply install/upgrade for missing and outdated items.
#
u_software_apply_installs() {
  local i
  local id
  local st
  local kind
  local name
  local pkg
  local ver
  local url
  local dir
  local bin
  local path
  local sha
  local cmd
  local method
  local tpl
  local en
  local idx
  local j
  local rc=0

  for ((i = 0; i < ${#software_diff_ids[@]}; i++)); do
    id="${software_diff_ids[$i]}"
    st="${software_diff_status[$i]}"

    case "$st" in
      missing|outdated) ;;
      *) continue ;;
    esac

    kind="${id%%:*}"
    name="${id#*:}"

    echo "Apply $st → $id"

    case "$kind" in
      apt)
        if ! u_software_apt_install "$name"; then
          rc=1
          continue
        fi
        ;;
      pipx)
        pkg=''
        for pkg in "${sw_pipx[@]}"; do
          pkg="$(u_software_scalar "$pkg")"
          if [[ "${pkg%%==*}" == "$name" ]]; then
            break
          fi
          pkg=''
        done
        if [[ -z "$pkg" ]]; then
          rc=1
          continue
        fi
        if ! u_software_pipx_install "$pkg"; then
          rc=1
          continue
        fi
        ;;
      tarball)
        idx=-1
        for ((j = 0; j < ${#sw_tarball__id[@]}; j++)); do
          if [[ "$(u_software_scalar "${sw_tarball__id[$j]}")" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        ver="$(u_software_scalar "${sw_tarball__version[$idx]}")"
        url="$(u_software_scalar "${sw_tarball__url[$idx]}")"
        dir="$(u_software_expand_path "${sw_tarball__install_dir[$idx]}")"
        bin="$(u_software_scalar "${sw_tarball__binary[$idx]}")"
        if ! u_software_tarball_install "$name" "$ver" "$url" "$dir" "$bin"; then
          rc=1
          continue
        fi
        ;;
      appimage)
        idx=-1
        for ((j = 0; j < ${#sw_appimage__id[@]}; j++)); do
          if [[ "$(u_software_scalar "${sw_appimage__id[$j]}")" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        url="$(u_software_scalar "${sw_appimage__url[$idx]:-}")"
        sha="$(u_software_scalar "${sw_appimage__sha256[$idx]:-}")"
        path="$(u_software_expand_path "${sw_appimage__path[$idx]}")"
        if ! u_software_appimage_install "$name" "$url" "$sha" "$path"; then
          rc=1
          continue
        fi
        ;;
      ensure)
        idx=-1
        for ((j = 0; j < ${#sw_ensure__id[@]}; j++)); do
          if [[ "$(u_software_scalar "${sw_ensure__id[$j]}")" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        cmd="$(u_software_scalar "${sw_ensure__command[$idx]}")"
        method="$(u_software_scalar "${sw_ensure__method[$idx]}")"
        if ! u_software_ensure_install "$name" "$cmd" "$method"; then
          rc=1
          continue
        fi
        ;;
      unit)
        idx=-1
        for ((j = 0; j < ${#sw_units__id[@]}; j++)); do
          if [[ "$(u_software_scalar "${sw_units__id[$j]}")" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        tpl="$(u_software_scalar "${sw_units__template[$idx]}")"
        en="$(u_software_scalar "${sw_units__enable[$idx]:-false}")"
        if ! u_software_unit_install "$name" "$tpl" "$en"; then
          rc=1
          continue
        fi
        ;;
      *)
        echo >&2 "Unknown kind: $kind"
        rc=1
        continue
        ;;
    esac

    u_software_managed_add "$id"
  done

  # Adopt already-satisfied desired items so prune can track them later.
  for ((i = 0; i < ${#software_diff_ids[@]}; i++)); do
    if [[ "${software_diff_status[$i]}" == 'ok' ]]; then
      u_software_managed_add "${software_diff_ids[$i]}"
    fi
  done

  return $rc
}

##
# Opt-in uninstall of managed extras not in the manifest.
#
u_software_apply_prune() {
  local id
  local kind
  local name
  local i
  local dir
  local path
  local bin

  if [[ "${SOFTWARE_PRUNE:-}" != '1' ]]; then
    if [[ ${#software_diff_extra[@]} -gt 0 ]]; then
      echo "Extras left in place (set SOFTWARE_PRUNE=1 or pass --prune to uninstall)."
    fi

    return 0
  fi

  for id in "${software_diff_extra[@]}"; do
    kind="${id%%:*}"
    name="${id#*:}"
    echo "Prune $id"

    case "$kind" in
      apt)
        if [[ "$(id -u)" -eq 0 ]]; then
          apt-get remove -y "$name" || true
        else
          sudo apt-get remove -y "$name" || true
        fi
        ;;
      pipx)
        pipx uninstall "$name" || true
        ;;
      tarball)
        # Extra not in current manifest — conventional install dir only.
        dir="${HOME}/Software/${name}"
        if [[ -d "$dir" ]]; then
          rm -rf "$dir"
        fi
        ;;
      appimage)
        path="${HOME}/Software/${name}-x86_64.AppImage"
        [[ -f "$path" ]] && rm -f "$path"
        ;;
      unit)
        systemctl --user disable --now "${name}.service" 2>/dev/null || true
        rm -f "${HOME}/.config/systemd/user/${name}.service"
        systemctl --user daemon-reload 2>/dev/null || true
        ;;
      ensure)
        echo >&2 "Skip prune ensure:$name (no safe uninstall)."
        continue
        ;;
      *)
        echo >&2 "Skip prune of unknown kind: $id"
        continue
        ;;
    esac

    u_software_managed_remove "$id"
  done
}

##
# Main entry: status | apply
#
# @param 1 String : status | apply
#
u_software_provision() {
  local p_mode="${1:-apply}"
  local rc=0

  if ! u_software_load_manifests; then
    return 1
  fi

  u_software_build_diff
  u_software_print_diff

  case "$p_mode" in
    status)
      return 0
      ;;
    apply)
      u_software_apply_installs || rc=$?
      u_software_build_diff
      u_software_apply_prune || rc=$?
      echo "Software provision finished (exit=$rc)."
      return $rc
      ;;
    *)
      echo >&2 "Error: unknown mode '$p_mode' (use status|apply)."
      return 2
      ;;
  esac
}
