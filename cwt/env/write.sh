#!/usr/bin/env bash

##
# Writes current local instance env settings.
#
# This script is meant to be called during stack init. Unless we know what we're
# doing, we shouldn't have to call it directly.
# @see cwt/stack/init.sh
#
# Usage :
# . cwt/env/write.sh
#

# First make sure we have something to write.
if [[ -z "$GLOBALS_COUNT" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: nothing to write."
  echo "Aborting (1)."
  echo
  return 1
elif [[ $P_VERBOSE == 1 ]]; then
  u_global_debug
fi

# And make sure that we have a file path to write to.
if [[ -z "$CURRENT_ENV_SETTINGS_FILE" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: \$CURRENT_ENV_SETTINGS_FILE is empty."
  echo "Aborting (2)."
  echo
  return 2
else
  echo
  echo "Writing settings in $CURRENT_ENV_SETTINGS_FILE ..."
fi

# Confirm overwriting existing settings if the file already exists.
if [[ ($P_YES == 0) && (-f "$CURRENT_ENV_SETTINGS_FILE") ]]; then
  echo
  while true; do
    read -p "Override existing settings ? (y/n) : " yn
    case $yn in
      [Yy]* ) echo "Ok, proceeding to override existing settings."; break;;
      [Nn]* ) echo "Aborting (3)."; return 3;;
      * ) echo "Please answer yes (enter 'y') or no (enter 'n').";;
    esac
  done
fi

# (Re)init destination file (make empty).
cat > "$CURRENT_ENV_SETTINGS_FILE" <<'EOF'
#!/usr/bin/env bash

##
# Current instance env settings file.
#
# This file is automatically generated during stack init, and it will be
# entirely overwritten every time stack init is executed.
#
# @see cwt/stack/init.sh
# @see cwt/stack/init/aggregate_env_vars.sh
# @see cwt/utilities/env.sh
#
# Documentation :
# @see cwt/env/README.md
#

EOF

# Write every aggregated globals.
# @see cwt/stack/init/aggregate_env_vars.sh
for global_name in ${GLOBALS['.sorting']}; do
  u_str_split1 evn_arr $global_name '|'
  global_name="${evn_arr[1]}"

  # [wip] TODO evaluate not requiring readonly globals.
  # eval "[[ -z \"\$$global_name\" ]] && echo \"readonly $global_name\"=\'\' >> \"$CURRENT_ENV_SETTINGS_FILE\""
  # eval "[[ -n \"\$$global_name\" ]] && echo \"readonly $global_name=\\\"\$$global_name\\\"\" >> \"$CURRENT_ENV_SETTINGS_FILE\""
  eval "[[ -z \"\$$global_name\" ]] && echo \"export $global_name\"=\'\' >> \"$CURRENT_ENV_SETTINGS_FILE\""
  eval "[[ -n \"\$$global_name\" ]] && echo \"export $global_name=\\\"\$$global_name\\\"\" >> \"$CURRENT_ENV_SETTINGS_FILE\""
done

echo "Writing settings in $CURRENT_ENV_SETTINGS_FILE : done."
echo
