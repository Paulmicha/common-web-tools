#!/bin/bash

##
# App instance dependencies declaration.
#
# This file is dynamically included during stack init.
# @see u_stack_get_specs()
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

softwares='php,..db,..webserver'

alternatives['..db']='mariadb,mysql,postgresql'
alternatives['..webserver']='apache,nginx'
