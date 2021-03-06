#!/usr/bin/env bash

##
# Implements hook -a 'init' -p 'pre'.
#
# After globals aggregation during instance init, we immediately trigger the DB
# crendentials initialization so that the values can be written once then
# always read (cf. registry), if applicable.
#
# @see u_db_set() in cwt/extensions/db/db.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

u_db_set_all
