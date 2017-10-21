# Environment variables declaration models

These files are automatically copied and their values replaced during setup. See `cwt/env/write.sh`

## Conventions

To support variants in current project's stack scripts (e.g. allow instances to be created either on a traditional LAMP stack or Docker and docker-compose), particular variables are used to match their corresponding script(s) files and/or folders to use.

## [wip] TODO

Implement a generic set of variants (covering usual local and/or remote setups) using the following variables :

```sh
# Add deploying methods :
DEPLOY_USING=git
DEPLOY_USING=ansistrano

# To implement "base" stack variants :
PROJECT_STACK=drupal7_lamp
PROJECT_STACK=drupal8_docker_compose

# To support different provisionning implementations :
PROVISION=scripts # default (alternative : make optional - assume when undefined or empty)
PROVISION=ansible

# To use other local "registry" implementations :
REG_BACKEND=file # default (alternative : make optional - assume when undefined or empty)
REG_BACKEND=ansible_vault
REG_BACKEND=hashicorp_vault

# To specify automated tests (presets ?) :
APP_TESTS_PRESET=behat
APP_TESTS_PRESET=gatling

# Visual regression testing (presets ?) :
APP_VRT_PRESET=gemini
APP_VRT_PRESET=puppeteer
```
