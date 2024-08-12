#!/usr/bin/env bash

##
# Combines commonly required actions to start a new project.
#
# Executes in this order the following actions :
#   - instance init
#   - start services (if any are implemented)
#   - app install (if any operations are implemented)
#
# NB : each step is idempotent (can be run several times without incidence, even
# if current instance was already initialized or services are already running).
#
# @see cwt/instance/init.sh
# @see cwt/instance/start.sh
# @see cwt/app/install.sh
#
# @param 1 [optional] String : instance type (INSTANCE_TYPE global value).
#   Defaults to 'dev'.
# @param 2 [optional] String : HOST_TYPE global value (flags instance as remote).
#   Defaults to 'local'.
# @param 3 [optional] String : INSTANCE_DOMAIN global value. Defaults to a
#   fictional local domain generated using PROJECT_DOCROOT's folder name.
#   @see u_instance_domain() in cwt/instance/instance.inc.sh
# @param 4 [optional] String : PROVISION_USING global value. Defaults to
#   'docker-compose'.
#
# @example
#
#   # Init instance locally using defaults.
#   cwt/instance/setup.sh
#   # Or :
#   make setup
#
#   # Init instance locally using production config.
#   cwt/instance/setup.sh prod
#   # Or :
#   make setup prod
#
#   # Init remote instance using production config provisionned manually (LAMP).
#   cwt/instance/setup.sh prod remote test.my-cwt-project.com lamp
#   # Or :
#   make setup prod remote test.my-cwt-project.com lamp
#

# Prerequisites check : can't guarantee idempotence if CWT globals were already
# loaded in current shell scope - because they are "readonly", which would be
# incompatible with the globals aggregation and assignment process.
# @see u_instance_init() in cwt/instance/instance.inc.sh
# @see global() + u_global_assign_value() in cwt/utilities/global.sh
if [[ -n "$CWT_MAKE_INC" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the 'instance init' step requires that no CWT globals be loaded in current shell scope, otherwise idempotence of step 1 (instance init) can't be guaranteed." >&2
  echo "Try running this script in a new terminal session or isolated (using 'env -i ...')." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# TODO [wip] check no longer required + remove.
# Also, calling cwt/instance/init.sh the way it is done below requires the YAML
# file to be present in $PROJECT_DOCROOT.
# if [[ ! -f 'cwt.yml' ]]; then
#   echo >&2
#   echo "Error in $BASH_SOURCE line $LINENO: the 'cwt.yml' file is required." >&2
#   echo "Please copy/paste 'sample.cwt.yml' to 'cwt.yml' & edit accordingly, then retry." >&2
#   echo "-> Aborting (2)." >&2
#   echo >&2
#   exit 2
# fi

# Defaults (overridable using parameters to this script).
instance_type='dev'
host_type='local'
provision_using='docker-compose'

if [[ -n "$1" ]]; then
  instance_type="$1"
fi

if [[ -n "$2" ]]; then
  host_type="$2"
fi

if [[ -n "$3" ]]; then
  instance_domain="$3"
else
  # Generates a default domain name based on current dir name and local host IP.
  . cwt/host/host.inc.sh
  . cwt/utilities/string.sh
  . cwt/instance/instance.inc.sh
  instance_domain=$(u_instance_domain)
fi

if [[ -n "$4" ]]; then
  provision_using="$4"
fi

# If previously initialized local instance, we need to make sure we don't run
# the setup script before uninit.
purge_list=()
purge_list+=('.env')
purge_list+=('scripts/cwt/local/global.vars.sh')
purge_list+=('scripts/cwt/local/default.mk')
purge_list+=('scripts/cwt/local/make_args_check.sh')

for entry in "${purge_list[@]}"; do
  if [[ -f "$entry" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: First, uninit." >&2
    echo >&2
    echo "If we setup an instance previously initialized, it needs to be cleaned up first :" >&2
    echo '$ make stop' >&2
    echo '$ make uninit' >&2
    echo "Or :" >&2
    echo '$ cwt/instance/stop.sh' >&2
    echo '$ cwt/instance/uninit.sh' >&2
    echo >&2
    echo "For a full reinstall, first run :" >&2
    echo '$ make destroy' >&2
    echo '$ make uninit' >&2
    echo "Or :" >&2
    echo '$ cwt/instance/destroy.sh' >&2
    echo '$ cwt/instance/uninit.sh' >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
done

echo
echo "Setup $host_type instance '$instance_domain' (type : $instance_type) using $provision_using ..."

# Step 1 : init.
cwt/instance/init.sh \
  -t "$instance_type" \
  -d "$instance_domain" \
  -h "$host_type" \
  -p "$provision_using" \
  -y

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: 'instance init' failed." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# Step 2 : start services.
cwt/instance/start.sh

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: 'instance start' failed." >&2
  echo "-> Aborting (4)." >&2
  echo >&2
  exit 4
fi

# Step 3 : app install.
cwt/app/install.sh

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: 'app install' failed." >&2
  echo "-> Aborting (5)." >&2
  echo >&2
  exit 5
fi

echo "Setup $host_type instance '$instance_domain' (type : $instance_type) using $provision_using : done."
echo
