#!/usr/bin/env bash

##
# Drupal 8 specific implementations for hook -a 'install' -s 'app'.
#
# @see cwt/custom/extensions/docker4drupal/app/install.hook.sh
#

cat >> "$DRUPAL_LOCAL_SETTINGS" <<'EOF'

$config_directories = array();
$settings['hash_salt'] = '__replace_this_hash_salt_value__';

$settings['file_public_path'] = '__replace_this_file_public_path_value__';
$settings['file_private_path'] = '__replace_this_file_private_path_value__';
$config['system.file']['path']['temporary'] = '__replace_this_system_file_path_temporary_value__';

EOF

# Replace placeholders in generated file.
if [[ -f "$DRUPAL_LOCAL_SETTINGS" ]]; then
  hash_salt=$(u_random_str)
  sed -e "s,__replace_this_hash_salt_value__,$hash_salt,g" -i "$DRUPAL_LOCAL_SETTINGS"
  sed -e "s,__replace_this_file_public_path_value__,$DRUPAL_FILES_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
  sed -e "s,__replace_this_file_private_path_value__,$DRUPAL_PRIVATE_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
  sed -e "s,__replace_this_system_file_path_temporary_value__,$DRUPAL_TMP_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
fi
