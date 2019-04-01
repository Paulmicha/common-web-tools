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
 * @see cwt/extensions/drupalwt/app/drupal_settings.7.tpl.php
 * @see cwt/extensions/drupalwt/drupalwt.inc.sh
 */

$databases['default']['default'] = [
  'driver' => 'mysql',
  'database' => '{{ DB_NAME }}',
  'username' => '{{ DB_USERNAME }}',
  'password' => '{{ DB_PASSWORD }}',
  'host' => '{{ DB_HOST }}',
  'prefix' => '',
];

$conf['file_public_path'] = '{{ DRUPAL_FILES_DIR }}';
$conf['file_temporary_path'] = '{{ DRUPAL_TMP_DIR }}';
$conf['file_private_path'] = '{{ DRUPAL_PRIVATE_DIR }}';

$conf['redis_client_host'] = '{{ REDIS_CLIENT_HOST }}';
$conf['redis_client_port'] = '{{ REDIS_CLIENT_PORT }}';
// $conf['redis_client_base'] = {{ REDIS_CLIENT_BASE }};
// $conf['redis_client_password'] = '{{ REDIS_CLIENT_PASSWORD }}';

$conf['redis_client_interface'] = 'PhpRedis';
$conf['lock_inc'] = 'sites/all/modules/contrib/redis/redis.lock.inc';
$conf['path_inc'] = 'sites/all/modules/contrib/redis/redis.path.inc';
$conf['cache_backends'][] = 'sites/all/modules/contrib/redis/redis.autoload.inc';
$conf['cache_default_class'] = 'Redis_Cache';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
