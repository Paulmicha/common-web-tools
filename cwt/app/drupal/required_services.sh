#!/bin/bash

required_services='php,mysql,apache'

declare -A alternatives

alternatives['mysql']='mariadb,postgresql'
alternatives['apache']='nginx'
