#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'bootstrap' -v 'PROVISION_USING'.
#
# TODO [evol] Find better workaround for warnings due to undefined env. var. in
# docker-compose.yml when unsign the 'db' extension and generating DB_PASS vars
# i.e. in order to avoid leaving sensitive values in .env file.
#

if u_cwt_extension_exists 'db'; then
  u_db_set
fi
