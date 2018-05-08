#!/usr/bin/env bash

##
# Implements hook -a 'install' -s 'app'.
#
# Write local (gitignored) Drupal settings.
#

if [ -z "$DRUPAL_LOCAL_SETTINGS" ]; then
  echo "Warning in $BASH_SOURCE line $LINENO: required global DRUPAL_LOCAL_SETTINGS is empty." >&2
  echo "Aborting (1)." >&2
  exit 1
fi

cat > "$DRUPAL_LOCAL_SETTINGS" <<'EOF'
<?php

/**
 * @file
 * Drupal instance-specific configuration file.
 *
 * IMPORTANT NOTE: this file is dynamically generated during CWT instance init.
 * -> Do not edit directly (will be overwritten).
 */

$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => 'drupal',
  'username' => 'drupal',
  'password' => 'drupal',
  'host' => 'mariadb',
  'port' => '3306',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
);

EOF

# This hook has Drupal version-specific implementations.
if [ -f "drupal-${DRUPAL_VERSION}/install.hook.sh" ]; then
  . "drupal-${DRUPAL_VERSION}/install.hook.sh"
fi
