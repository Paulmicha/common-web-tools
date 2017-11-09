#!/bin/bash

required_services='php,..db,..webserver'

declare -A alternatives
alternatives['..db']='mariadb,mysql,postgresql'
alternatives['..webserver']='apache,nginx'
