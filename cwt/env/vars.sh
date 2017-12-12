#!/usr/bin/env bash

##
# Global env settings declaration.
#
# This file is dynamically included during stack init. Matching rules and syntax
# are explained in documentation.
# @see cwt/env/README.md
#
# TODO provide tests / CI examples.
#

global PROJECT_STACK
global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"
global INSTANCE_TYPE "[default]=dev"
global INSTANCE_DOMAIN "[default]='$(u_get_instance_domain)'"
global INSTANCE_ALIAS

global CWT_MODE "[default]=separate"
global APP_GIT_ORIGIN "[if-CWT_MODE]=separate"
global APP_GIT_WORK_TREE "[if-CWT_MODE]=separate [default]=$APP_DOCROOT"

global HOST_TYPE "[default]=local"
global HOST_OS "[default]='$(u_host_get_os)'"
global PROVISION_USING "[default]=docker-compose"
global DEPLOY_USING "[default]=git"

# TODO evaluate removal of "registry" feature.
global REG_BACKEND "[default]=file"
# TODO else consider using a separate store for secrets, see cwt/env/README.md.
# global SECRETS_BACKEND

global CWT_CUSTOM_DIR "[default]=cwt/custom"

# Declaring additional hosts. Example :
# remote_domain='remote.instance.cwt.com'
# global REMOTE_INSTANCES "[append]=$remote_domain [to]=domains"
# global REMOTE_INSTANCES "[append]=dev [to]=$remote_domain|type"
# global REMOTE_INSTANCES "[append]='ssh -p123 username@cwt.com' [to]=$remote_domain|connect"
# global REMOTE_INSTANCES "[append]='/path/to/remote/instance/docroot' [to]=$remote_domain|PROJECT_DOCROOT"
# global REMOTE_INSTANCES "[append]='/path/to/remote/instance/docroot/web' [to]=$remote_domain|APP_DOCROOT"
