#!/usr/bin/env bash

##
# {{ DOCBLOCK }}
#
# @example
#   {{ <DEFAULT> }}
#   {{ COMMENT_DEFAULT }}
#   make {{ SUBJECT_ACTION }}
#   # Or :
#   {{ ACTION_PATH }}
#   {{ </DEFAULT> }}
#   {{ <WITH_ARGS> }}
#   {{ COMMENT_WITH_ARGS }}
#   make {{ SUBJECT_ACTION }}{{ ARGS_MAKE }}
#   # Or :
#   {{ ACTION_PATH }}{{ ARGS }}
#   {{ </WITH_ARGS> }}
#

. cwt/bootstrap.sh

{{ ACTION }}
