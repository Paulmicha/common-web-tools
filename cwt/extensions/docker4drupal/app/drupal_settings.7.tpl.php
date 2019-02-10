<?php

/**
 * @file
 * Drupal 7 local settings file.
 *
 * Contains instance-specific settings.
 *
 * IMPORTANT NOTE: this file is dynamically generated during 'app install'.
 * -> Do not edit directly (will be overwritten).
 *
 * Details in dev stack :
 * @see scripts/cwt/extend/app/drupal_settings.tpl.php
 * @see cwt/extensions/docker4drupal/docker4drupal.inc.sh
 */

$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => '__replace_this_DB_NAME_value__',
  'username' => '__replace_this_DB_USERNAME_value__',
  'password' => '__replace_this_DB_PASSWORD_value__',
  'host' => '__replace_this_DB_HOST_value__',
  'prefix' => '',
);

$conf['file_public_path'] = '__replace_this_DRUPAL_FILES_DIR_C_value__';
$conf['file_temporary_path'] = '__replace_this_DRUPAL_TMP_DIR_C_value__';
$conf['file_private_path'] = '__replace_this_DRUPAL_PRIVATE_DIR_C_value__';

$conf['redis_client_interface'] = 'PhpRedis';
$conf['redis_client_host'] = '__replace_this_REDIS_CLIENT_HOST_value__';
$conf['redis_client_port'] = '__replace_this_REDIS_CLIENT_PORT_value__';
