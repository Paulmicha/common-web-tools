#!/bin/bash

##
# Write local settings.
#
# Usage from project root dir :
# $ . cwt/app/write_settings.sh
#

. cwt/env/load.sh

# Drupal settings.
cat > web/sites/default/settings.local.php <<'EOF'
<?php

/**
 * @file
 * Local (dev) settings.
 *
 * This file is auto-generated during Dev Stack Setup.
 */

$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => 'DB_NAME',
  'username' => 'DB_USERNAME',
  'password' => 'DB_PASSWORD',
  'host' => 'localhost',
  'prefix' => '',
);

// [WIP] @todo Redis config.
/*
$conf['redis_client_base'] = 0;
$conf['redis_client_interface'] = 'PhpRedis';
$conf['lock_inc'] = 'sites/all/modules/contrib/redis/redis.lock.inc';
$conf['path_inc'] = 'sites/all/modules/contrib/redis/redis.path.inc';
$conf['cache_backends'][] = 'sites/all/modules/contrib/redis/redis.autoload.inc';
$conf['cache_default_class'] = 'Redis_Cache';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';

$conf['redis_client_password'] = REDIS_PASSWORD;
$conf['redis_client_host'] = REDIS_HOST;
$conf['redis_client_port'] = REDIS_PORT;
*/

EOF

sed -e "s,DB_NAME,$DB_NAME,g" -i web/sites/default/settings.local.php
sed -e "s,DB_USERNAME,$DB_USERNAME,g" -i web/sites/default/settings.local.php
sed -e "s,DB_PASSWORD,$DB_PASSWORD,g" -i web/sites/default/settings.local.php
