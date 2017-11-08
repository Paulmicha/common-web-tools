#!/bin/bash

# Stack (host-level) settings.
readonly PROJECT_STACK
readonly PROJECT_DOCROOT
readonly PROVISION_USING
readonly REG_BACKEND
# TODO consider using a separate store for secrets, see cwt/env/README.md.
# readonly SECRETS_BACKEND

# App instance settings.
readonly APP_DOCROOT
readonly INSTANCE_TYPE
readonly INSTANCE_DOMAIN
readonly INSTANCE_ALIAS

# Deployment settings.
readonly DEPLOY_USING

# TODO test settings, see cwt/env/README.md.
