#!/usr/bin/env bash

##
# Global (env) vars for the 'moodle_d4php' CWT extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see cwt/utilities/global.sh
# @see cwt/bootstrap.sh
#

global INSTANCE_URL "[default]=http://localhost"
global APP_DOCROOT_C "[default]=/var/www/html"

global MOODLE_VERSION "[default]=3 [help]='Used to match config.php templates in this extension, e.g. cwt/extensions/moodle_d4php/app/config.3.tpl.php (currently defaults to 3)'"

global MOODLE_CRON_FREQ "[default]='*/1 * * * *'"

global MOODLE_BASIC_AUTH_USERS "[default]='$(u_str_basic_auth_credentials moodle_basic_auth_creds)' [help]='Http Basic Auth credentials for pubicly accessible services of remote instance whose type is “dev” or “stage”. Defauts to login : “admin”, and a randomly generated password that can be retrieved locally from a remote instance with the command : make remote-moodle-basic-auth (see cwt/extensions/moodle_d4php/remote/moodle_basic_auth.sh)'"

global MOODLE_DATA_DIR "[default]=app/moodledata"
global MOODLE_DATA_DIR_C "[default]=/var/moodledata"
global WRITEABLE_DIRS "[append]=$MOODLE_DATA_DIR"

global MOODLE_PHPUNITDATA_DIR "[default]=data/files/phpunitdata"
global MOODLE_PHPUNITDATA_DIR_C "[default]=/var/www/phpunitdata"
global WRITEABLE_DIRS "[append]=$MOODLE_PHPUNITDATA_DIR"

global MOODLE_BEHATDATA_DIR "[default]=data/files/behatdata"
global MOODLE_BEHATDATA_DIR_C "[default]=/var/www/behatdata"
global WRITEABLE_DIRS "[append]=$MOODLE_BEHATDATA_DIR"

global MOODLE_BEHATFAILDUMPS_DIR "[default]=data/files/behatfaildumps"
global MOODLE_BEHATFAILDUMPS_DIR_C "[default]=/var/www/behatfaildumps"
global WRITEABLE_DIRS "[append]=$MOODLE_BEHATFAILDUMPS_DIR"

global MOODLE_CONFIG_FILE "[default]=$APP_DOCROOT/config.php"
global PROTECTED_FILES "[append]=$MOODLE_CONFIG_FILE"
