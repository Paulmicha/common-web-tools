<?php

/**
 * @file
 * Drupal 9 local settings file.
 *
 * Contains instance-specific settings.
 *
 * IMPORTANT NOTE: this file is dynamically generated during 'app install'.
 * -> Do not edit directly (will be overwritten).
 *
 * Details in dev stack :
 * @see cwt/extensions/drupalwt/app/drupal_settings.9.tpl.php
 * @see cwt/extensions/drupalwt/drupalwt.inc.sh
 */

$databases['default']['default'] = [
  'driver' => '{{ DB_DRIVER }}',
  'database' => '{{ DB_NAME }}',
  'username' => '{{ DB_USER }}',
  'password' => '{{ DB_PASS }}',
  'host' => '{{ DB_HOST }}',
  'port' => '{{ DB_PORT }}',
  'prefix' => '',
];

if ($databases['default']['default']['driver'] == 'mysql') {
  $databases['default']['default']['collation'] = '{{ SQL_COLLATION }}';
}
elseif ($databases['default']['default']['driver'] == 'pgsql') {
  $databases['default']['default']['namespace'] = 'Drupal\\Core\\Database\\Driver\\pgsql';
}

$settings['config_sync_directory'] = '{{ DRUPAL_CONFIG_SYNC_DIR }}';

$settings['hash_salt'] = '{{ DRUPAL_HASH_SALT }}';

$settings['file_public_path'] = '{{ DRUPAL_FILES_DIR }}';
$settings['file_private_path'] = '{{ DRUPAL_PRIVATE_DIR }}';
$config['system.file']['path']['temporary'] = '{{ DRUPAL_TMP_DIR }}';

$settings['trusted_host_patterns'] = [
  '^' . str_replace('.', '\.', '{{ INSTANCE_DOMAIN }}'),
];

// Redis cache backend (contrib) requiring the PhpRedis extension.
// $settings['redis.connection']['interface'] = 'PhpRedis';
// $settings['redis.connection']['host'] = 'redis';
// $settings['cache']['default'] = 'cache.backend.redis';
// $settings['redis.connection']['base'] = 1;

// Conditionnally apply local development services and settings.
// @see web/sites/example.settings.local.php
$host_type = getenv('HOST_TYPE');
$instance_type = getenv('INSTANCE_TYPE');

if ($host_type == 'local' && $instance_type == 'dev') {
  // TODO [wip] workaround Error: Class 'DrupalComponentAssertionHandle' not found.
  // assert_options(ASSERT_ACTIVE, TRUE);
  // \Drupal\Component\Assertion\Handle::register();
  $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
  $config['system.logging']['error_level'] = 'verbose';
  $config['system.performance']['css']['preprocess'] = FALSE;
  $config['system.performance']['js']['preprocess'] = FALSE;
  $settings['cache']['bins']['render'] = 'cache.backend.null';
  $settings['cache']['bins']['discovery_migration'] = 'cache.backend.memory';
}
