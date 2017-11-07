# Environment settings

The variables written and loaded using the scripts in this directory are used in all CWT tasks. Some are common to any type of stack, while others are specific to certain variants.

The very first step required to use CWT is writing current instance's env settings, a task referred to as **stack init** :

```sh
# This is the starting point.
# It provides options and/or terminal prompts to obtain all mandatory values,
# then calls cwt/env/write.sh.
. cwt/stack/init.sh
```

This process generates a single file (`cwt/env/current/vars.sh`) by assembling any number of default env files - called config or env *models* - whose role is to declare all variables necessary for the current project instance : host-level dependencies, build/test tools, service-specific configuration...

The agregation rules consist of a correspondance between a basic syntax used in the `$PROJECT_STACK` value (+ `$PROVISION_USING` value) and optional directories + filenames matching it.

The way this process works is :

- get `$PROJECT_STACK` value (see examples below) and `$PROVISION_USING` value - if not provided in `cwt/stack/init.sh` arguments
- add the common, generic `cwt/env/dist/env.vars.sh` model
- check if additional, optional rules-matching models exist
- assemble all models found
- assign values to the variables they contain by using terminal prompts - if not provided (or instructed to use default values) in `cwt/stack/init.sh` arguments
- write the result to `cwt/env/current/vars.sh`

Every time `cwt/stack/init.sh` is called, current instance's env file is (over)written. The fundamental value `$PROJECT_STACK` is used to derive the rest of conditional settings and custom overrides/complements lookup paths.

CWT provides a few models but its purpose remains to be useful for your specific project(s), so the reason this process is detailed here is to better understand how to provide your own custom env settings declarations.

To illustrate how lookups work, we use the following examples for possible `$PROJECT_STACK` values :

1. `contenta` (nothing else specified = use latest version of the corresponding "barebone" stack + project settings)
1. `drupal-7--php-5.4,redis,solr-3` (request additional services after the *variant* or *modifier* separator `--` and then separate multiple services by `,` if needed)
1. `phenomic--libp2p,p-preact` (predefined combos or custom namespaces may be provided as *presets*, freely named - uses `p-` prefix to avoid potential collisions with services)

---

(work in progress)

## Example 1 : `contenta`

TODO : rewrite below

Given the following value for the '-s' or '--stack' arg: "drupal-7", and for the '-p' or '--provision' arg: "scripts", this script will attempt to copy the contents of all the following files (if they exist), append it to the file storing settings of the current local instance, `cwt/env/current/.app.vars.sh` :

- `cwt/env/dist/drupal/app.vars.sh.dist`
- `cwt/env/dist/drupal/scripts.provision.vars.sh.dist`
- `cwt/env/dist/drupal/7/app.vars.sh.dist`
- `cwt/env/dist/drupal/7/scripts.provision.vars.sh.dist`

Then it proceeds to replace all placeholders from the dist files with values from variables populated in stack init, using the following convention :

`__replace_this_DB_NAME_value__` -> `$P_DB_NAME`

The naming convention for variables "assembled" in `cwt/stack/init.sh` is the prefix "P_" + the actual env var name, as they will be loaded by `cwt/env/load.sh`.

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
