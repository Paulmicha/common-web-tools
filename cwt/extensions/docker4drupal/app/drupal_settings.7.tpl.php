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
 * @see cwt/extensions/docker4drupal/app/drupal_settings.7.tpl.php
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
$conf['lock_inc'] = 'sites/all/modules/contrib/redis/redis.lock.inc';
$conf['path_inc'] = 'sites/all/modules/contrib/redis/redis.path.inc';
$conf['cache_backends'][] = 'sites/all/modules/contrib/redis/redis.autoload.inc';
$conf['cache_default_class'] = 'Redis_Cache';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
$conf['redis_client_host'] = '__replace_this_REDIS_CLIENT_HOST_value__';
$conf['redis_client_port'] = '__replace_this_REDIS_CLIENT_PORT_value__';
// $conf['redis_client_base'] = __replace_this_REDIS_CLIENT_BASE_value__;
// $conf['redis_client_password'] = '__replace_this_REDIS_CLIENT_PASSWORD_value__';
