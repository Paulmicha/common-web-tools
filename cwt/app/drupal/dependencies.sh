#!/bin/bash

##
# Dependencies declaration.
#
# This file is dynamically included during stack init.
# @see u_stack_resolve_deps()
# @see u_stack_get_specs()
# @see cwt/stack/init.sh
#
# Matching rules and syntax are explained in documentation :
# @see cwt/env/README.md
#

softwares+='php-7,..db,..webserver'

alternatives['..db']='mariadb-10,mysql-5,postgresql-10'
alternatives['..webserver']='apache-2.4,nginx-1'
