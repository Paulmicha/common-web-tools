#!/usr/bin/env bash

##
# Combines commonly required actions to instanciate a fully functional project.
#
# Executes in this order the following actions :
#   - instance init (.env + makefiles generation)
#   - build + start services (if any are implemented)
#   - run stage2 & post-setup hooks (if any are implemented), which are :
#     - "stage2" to create databases, import initial DB dumps, then :
#     - "post_setup" to run vendor install, config import, cache clear, etc.
#
# To check post-setup hooks :
# make hook-debug s:instance p:stage2 a:setup v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# make hook-debug s:instance p:post a:setup v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
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
# @param 3 [optional] String : STACK_VERSION global value. Defaults to an empty
#   string.
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
#   cwt/instance/setup.sh prod remote myproject-2024 lamp
#   # Or :
#   make setup prod remote myproject-2024 lamp
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

# Defaults (overridable using parameters to this script).
instance_type='dev'
host_type='local'
stack_version=''
provision_using='docker-compose'

if [[ -n "$1" ]]; then
  instance_type="$1"
fi

if [[ -n "$2" ]]; then
  host_type="$2"
fi

if [[ -n "$3" ]]; then
  stack_version="$3"
fi

if [[ -n "$4" ]]; then
  provision_using="$4"
fi

# If previously initialized local instance, we need to make sure we don't run
# the setup script before uninit.
purge_list=()
purge_list+=('.env')
purge_list+=('scripts/cwt/local/global.vars.sh')
purge_list+=('scripts/cwt/local/generated.mk')
purge_list+=('scripts/cwt/local/cache/make.sh')

for entry in "${purge_list[@]}"; do
  if [[ -f "$entry" ]]; then
    echo >&2
    echo "Setup cannot run, because first, uninit is required." >&2
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

feedback="Setup $host_type $instance_type $provision_using instance"

if [[ -n "$stack_version" ]]; then
  feedback="Setup $host_type $instance_type $provision_using instance version $stack_version"
fi

echo
echo "$feedback ..."

# Step 1 : init.
if [[ -n "$stack_version" ]]; then
  cwt/instance/init.sh \
    -t "$instance_type" \
    -s "$stack_version" \
    -h "$host_type" \
    -p "$provision_using" \
    -y
else
  cwt/instance/init.sh \
    -t "$instance_type" \
    -h "$host_type" \
    -p "$provision_using" \
    -y
fi

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

# Step 3 : post-setup hooks - i.e. "stage2" to create databases, import initial
# DB dumps, then "post_setup" to run vendor install, cache clear, etc. (*after*
# the optional DB dumps initial import)...
# @see cwt/extensions/db/instance/post_setup.hook.sh
. cwt/bootstrap.sh
hook -s 'instance' -p 'stage2' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'post' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

echo "$feedback : done."
echo
