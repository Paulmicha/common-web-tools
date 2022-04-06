<?php

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '{{ DB_HOST }}';
$CFG->dbname    = '{{ DB_NAME }}';
$CFG->dbuser    = '{{ DB_USER }}';
$CFG->dbpass    = '{{ DB_PASS }}';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array(
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = '{{ INSTANCE_URL }}';
$CFG->dataroot  = '{{ MOODLE_DATA_DIR_C }}';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

// Specific settings by instance type.
$instance_type = getenv('INSTANCE_TYPE');
if ($instance_type == 'dev') {
  $CFG->debug = (E_ALL | E_STRICT);
  $CFG->debugdisplay = 1;
}
if ($instance_type == 'dev' || $instance_type == 'stage') {
  // TODO [wip] This does not seem to have any effect.
  // See https://github.com/moodlehq/moodle-docker/blob/master/config.docker-template.php
  $CFG->smtphosts = 'mailhog:1025';
}

// Specific settings by host type.
$host_type = getenv('HOST_TYPE');
if ($host_type == 'remote') {
  // See https://serverfault.com/questions/978853/moodle-3-7-apache-reverse-proxy-results-err-too-many-redirects
  // Assuming all remotes are behind a reverse proxy already handling https,
  // do NOT use $CFG->reverseproxy = true; but instead :
  $CFG->sslproxy = true;
}

require_once(__DIR__ . '/lib/setup.php');
