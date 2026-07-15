#!/usr/bin/env bash

##
# YAML-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

# Load vendor dependency for YAML files parsing.
# See https://github.com/jasperes/bash-yaml
# See also https://github.com/mrbaseman/parse_yaml (discarded for now)
. cwt/vendor/bash-yaml/script/yaml.sh

##
# Transforms a YAML file into a series of shell variables declarations.
#
# Supported YAML syntax :
# @see cwt/vendor/bash-yaml/test/file.yml
#
# @param 1 String : path to YAML file.
# @param 2 [optional] String : the resulting variables prefix. Defaults to 'y_'.
#
# @example
#   # Given this input file contents (path/to/file.yml) :
#   site:
#     all: default-sites.txt
#     new: new-sites.txt
#   urls:
#     - preprod.example.com
#     - example.com
#   items:
#     - title: My first item
#       content: First item content
#     - title: My item 2
#       content: Item 2 content
#     - title: My item 3
#       content: Item 3 content
#
#   # Calling this :
#   u_yaml_parse path/to/file.yml 'conf_'
#
#   # -> outputs :
#   conf_site_all=("default-sites.txt")
#   conf_site_new=("new-sites.txt")
#   conf_urls+=("preprod.example.com")
#   conf_urls+=("example.com")
#   conf_items__title+=("My first item")
#   conf_items__content+=("First item content")
#   conf_items__title+=("My item 2")
#   conf_items__content+=("Item 2 content")
#   conf_items__title+=("My item 3")
#   conf_items__content+=("Item 3 content")
#
#   # Usage example :
#   eval "$(u_yaml_parse path/to/file.yml 'conf_')"
#   echo "$conf_site_all"             # -> default-sites.txt
#   echo "$conf_site_new"             # -> new-sites.txt
#   echo "${conf_urls[0]}"            # -> preprod.example.com
#   echo "${conf_urls[1]}"            # -> example.com
#   echo "${conf_items__title[0]}"    # -> My first item
#   echo "${conf_items__content[0]}"  # -> First item content
#   echo "${conf_items__title[1]}"    # -> My item 2
#   echo "${conf_items__content[1]}"  # -> Item 2 content
#   echo "${conf_items__title[2]}"    # -> My item 3
#   echo "${conf_items__content[2]}"  # -> Item 3 content
#
#   # Simple lists iteration example :
#   for url in "${conf_urls[@]}"; do
#     echo "$url"
#   done
#
#   # Keyed lists iteration example :
#   for ((i = 0 ; i < ${#conf_items__title[@]} ; i++)); do
#     echo "item $i title = '${conf_items__title[$i]}'"
#     echo "item $i content = '${conf_items__content[$i]}'"
#   done
#
#   # "Real-world" usage examples :
#   # @see u_instance_yaml_config_parse() in cwt/instance/instance.inc.sh
#   # @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#
u_yaml_parse() {
  local p_yml_file="$1"
  local p_prefix="$2"

  if [[ -z "$p_prefix" ]]; then
    p_prefix='y_'
  else
    u_str_sanitize_var_name "$p_prefix" p_prefix
  fi

  parse_yaml "$p_yml_file" "$p_prefix"
}

##
# Gets root "keys" for given YAML file.
#
# For now, only works with "non-list" entries.
# @see u_yaml_parse()
#
# Outputs result in a variable subject to collision in calling scope :
# @var yaml_keys
#
# @param 1 String : YAML file path.
#
# @example
#   # Level 0 (root) keys :
#   u_yaml_get_root_keys 'path/to/file.yml'
#   echo "Level 0 keys = ${yaml_keys[@]}"
#   echo "Number of level 0 keys = ${#yaml_keys[@]}"
#   # Iteration :
#   for key in "${yaml_keys[@]}"; do
#     echo "$key"
#   done
#
u_yaml_get_root_keys() {
  local p_yaml_file="$1"
  local parsed_line
  local parsed_var
  local parsed_var_leaf
  local parsed_var_split

  yaml_keys=()

  while IFS= read -r parsed_line _; do
    case "$parsed_line" in
      # Match any line beginning with something else than space, line break,
      # tab, etc. or '#' (commented out) and ending with ':'.
      [![:space:]'#']*:)
        parsed_var="${parsed_line//':'/}"
        if [[ -n "$parsed_var" ]]; then
          u_array_add_once "$parsed_var" yaml_keys
        fi
        ;;
      *)
        continue
        ;;
    esac
  done < "$p_yaml_file"
}

##
# Gets "keys" from given parsed YAML string filtered by prefix.
#
# Warning : for rrot (level 0) keys, use u_yaml_get_root_keys().
#
# For now, only works with "non-list" entries.
# @see u_yaml_parse()
#
# Outputs result in a variable subject to collision in calling scope :
# @var yaml_keys
#
# @param 1 String : parsed YAML string.
# @param 2 [optional] String : a prefix. Allows to get "deeper" keys if needed.
#   Should match parsed YAML string prefix, if any was used.
#
# @example
#   # Level 1 keys of 'site' from the u_yaml_parse() example file contents :
#   parsed_yaml_str="$(u_yaml_parse path/to/file.yml 'conf_')"
#   u_yaml_get_keys "$parsed_yaml_str" 'conf_site_'
#   echo "Level 1 'site' keys = ${yaml_keys[@]}"
#   echo "Number of level 1 'site' keys = ${#yaml_keys[@]}"
#   # Iteration :
#   for key in "${yaml_keys[@]}"; do
#     echo "$key"
#   done
#
u_yaml_get_keys() {
  local p_yaml_str="$1"
  local p_prefix="$2"
  local parsed_line
  local parsed_var
  local parsed_var_leaf
  local parsed_var_split

  yaml_keys=()

  while IFS= read -r parsed_line _; do
    parsed_var_leaf="=${parsed_line##*=}"
    parsed_var="${parsed_line%$parsed_var_leaf}"
    if [[ -n "$p_prefix" ]]; then
      # Skip any line not matching prefix.
      case "$parsed_line" in
        "$p_prefix"*)
          parsed_var="${parsed_var#$p_prefix}"
          ;;
        *)
          continue
          ;;
      esac
    fi
    parsed_var_split="$(echo "$parsed_var" | cut -d '_' -f 1)"
    u_array_add_once "$parsed_var_split" yaml_keys
  done <<< "$p_yaml_str"
}

##
# Escapes a string for use inside double-quoted YAML scalars.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
# The default variable name is overridable : see arg 2.
#
# @param 1 String : raw value.
# @param 2 [optional] String : variable name in calling scope for the result.
#   Defaults to : 'yaml_escaped'.
#
# @example
#   u_yaml_escape_double 'say "hi"'
#   echo "$yaml_escaped"
#   # -> say \"hi\"
#
#   u_yaml_escape_double 'a\b' 'my_esc'
#   echo "$my_esc"
#
u_yaml_escape_double() {
  local p_val="$1"
  local p_var_name="$2"

  if [[ -z "$p_var_name" ]]; then
    p_var_name='yaml_escaped'
  fi

  p_val="${p_val//'\'/'\\'}"
  p_val="${p_val//\"/\\\"}"
  printf -v "$p_var_name" '%s' "$p_val"
}

##
# Writes a bash-yaml-compatible flat YAML file (scalars + simple lists).
#
# Limits : no nested maps / keyed list objects — only root scalars and root
# simple string lists (what u_yaml_parse / bash-yaml can reload cleanly).
#
# @param 1 String : output file path.
# @param 2 String : name of associative array of scalar key -> value.
# @param 3 String : name of normal array listing scalar keys in write order.
# @param … [optional] Pairs : list_key list_array_name (simple lists).
#
# @example
#   declare -A y_sc=([entry]="foo" [status]="running")
#   y_keys=(entry status)
#   y_tree=("123:bash" "1:systemd")
#   u_yaml_write 'data/threads/foo.yml' y_sc y_keys tree y_tree
#
u_yaml_write() {
  local p_yml_file="$1"
  local p_scalars_name="$2"
  local p_keys_name="$3"
  local yaml_dir
  local k
  local list_key
  local list_arr_name
  local item
  local yaml_escaped
  local yaml_buf=''

  shift 3

  declare -n __yaml_scalars="$p_scalars_name"
  declare -n __yaml_keys="$p_keys_name"

  yaml_dir="${p_yml_file%/*}"

  if [[ "$yaml_dir" != "$p_yml_file" && ! -d "$yaml_dir" ]]; then
    mkdir -p "$yaml_dir"
  fi

  for k in "${__yaml_keys[@]}"; do
    u_yaml_escape_double "${__yaml_scalars[$k]}" 'yaml_escaped'
    yaml_buf+="${k}: \"${yaml_escaped}\""$'\n'
  done

  while [[ $# -ge 2 ]]; do
    list_key="$1"
    list_arr_name="$2"
    shift 2
    declare -n __yaml_list="$list_arr_name"
    yaml_buf+="${list_key}:"$'\n'

    for item in "${__yaml_list[@]}"; do
      u_yaml_escape_double "$item" 'yaml_escaped'
      yaml_buf+="  - \"${yaml_escaped}\""$'\n'
    done
  done

  printf '%s' "$yaml_buf" > "$p_yml_file"
}
