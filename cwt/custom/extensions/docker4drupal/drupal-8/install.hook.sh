#!/usr/bin/env bash

##
# Implements hook -a 'install' -s 'app'.
#
# Write local (gitignored) Drupal settings.
# TODO [wip] refacto in progress.
#

if [ -z "$DRUPAL_LOCAL_SETTINGS" ]; then
  echo "Warning in $BASH_SOURCE line $LINENO: required global DRUPAL_LOCAL_SETTINGS is empty." >&2
  echo "Aborting (4)." >&2
  return 4
fi

# TODO [wip] avoid hardcoded DB service credentials.

cat > "$DRUPAL_LOCAL_SETTINGS" <<'EOF'
<?php

/**
 * @file
 * Drupal instance-specific configuration file.
 *
 * IMPORTANT NOTE: this file is dynamically generated during CWT instance init.
 * -> Do not edit directly (will be overwritten).
 */

$databases['default']['default'] = array (
  'database' => 'drupal',
  'username' => 'drupal',
  'password' => 'drupal',
  'host' => 'mariadb',
  'port' => '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
);

$config_directories = array();
$settings['hash_salt'] = '__replace_this_hash_salt_value__';

$settings['file_public_path'] = '__replace_this_file_public_path_value__';
$settings['file_private_path'] = '__replace_this_file_private_path_value__';
$config['system.file']['path']['temporary'] = '__replace_this_system_file_path_temporary_value__';

EOF


# Write values (replace placeholders in generated file).
if [[ -f "$DRUPAL_LOCAL_SETTINGS" ]]; then

  hash_salt=$(u_random_str)
  sed -e "s,__replace_this_hash_salt_value__,$hash_salt,g" -i "$DRUPAL_LOCAL_SETTINGS"

  sed -e "s,__replace_this_file_public_path_value__,$DRUPAL_FILES_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
  sed -e "s,__replace_this_file_private_path_value__,$DRUPAL_PRIVATE_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
  sed -e "s,__replace_this_system_file_path_temporary_value__,$DRUPAL_TMP_DIR_C,g" -i "$DRUPAL_LOCAL_SETTINGS"
fi