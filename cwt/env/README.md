# Environment settings

The variables written and loaded using the scripts in this directory are used in all CWT tasks. Some are common to any type of stack, while others are specific to certain variants.

## Operation

The very first step required to use CWT is writing current instance's env settings, a task referred to as **stack init** :

```sh
# This is the starting point.
# It provides options and/or terminal prompts to obtain all mandatory values,
# then calls cwt/env/write.sh.
. cwt/stack/init.sh
```

This process generates a single file (`cwt/env/current/vars.sh`) by assembling any number of default env files - called config or env *models* - whose role is to declare all variables necessary for the current project instance : host-level dependencies, build/test tools, service-specific configuration...

The aggregation rules consist of a correspondance between a basic syntax used in the `$PROJECT_STACK` value (+ `$PROVISION_USING` value) and optional directories + filenames matching it.

The way this process works is :

- get `$PROJECT_STACK` value (see examples below) and `$PROVISION_USING` value - if not provided in `cwt/stack/init.sh` arguments
- add the common, generic `cwt/env/vars.sh` model
- check if additional, optional rules-matching models exist
- assemble all models found
- assign values to the variables they contain by using terminal prompts - if not provided (or instructed to use default values) in `cwt/stack/init.sh` arguments
- write the result to `cwt/env/current/vars.sh`

Every time `cwt/stack/init.sh` is called, current instance's env file is (over)written.

`$PROJECT_STACK` and `$PROVISION_USING` values are used to derive the rest of conditional settings and custom overrides/complements lookup paths. Aggregation will include generic models first, then more specific ones, and finally their corresponding customization (overrides or complements)

CWT provides a few models but its purpose remains to be useful for your specific project(s), so the reason this process is detailed here is to better understand how to provide your own custom env settings declarations.

To illustrate how lookups work, we use the following examples for possible `$PROJECT_STACK` values :

1. `contenta` (nothing else specified = use latest version of the corresponding "barebone" stack + project settings)
1. `drupal-7--php-5.4,redis,solr-3` (request additional services after the *variant* or *modifier* separator `--` and then separate multiple services by `,` if needed)
1. `phenomic--libp2p,p-preact` (predefined combos or custom namespaces may be provided as *presets*, freely named - uses `p-` prefix to avoid potential collisions with services)

The config models paths looked up for each example are listed below, in order. Each "candidate" may be overridden or complemented using the normal customization pattern (see `cwt/custom/README.md`).

### Example 1 : `PROJECT_STACK=contenta`

- `provision/${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations
- `app/contenta/env.vars.sh`
- `app/contenta/env.${PROVISION_USING}.vars.sh`
- corresponding `app` customizations (same order)

### Example 2 : `PROJECT_STACK=drupal-7--php-5.4,redis,solr-3`

- `provision/${PROVISION_USING}.vars.sh`
- `provision/php/${PROVISION_USING}.vars.sh`
- `provision/php/5/${PROVISION_USING}.vars.sh`
- `provision/php/5.4/${PROVISION_USING}.vars.sh`
- `provision/redis/${PROVISION_USING}.vars.sh`
- `provision/solr/${PROVISION_USING}.vars.sh`
- `provision/solr/3/${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations (same order)
- `app/drupal/env.vars.sh`
- `app/drupal/env.${PROVISION_USING}.vars.sh`
- `app/drupal/7/env.vars.sh`
- `app/drupal/7/env.${PROVISION_USING}.vars.sh`
- corresponding `app` customizations (same order)

### Example 3 : `PROJECT_STACK=phenomic--libp2p,p-preact`

- `provision/${PROVISION_USING}.vars.sh`
- `provision/phenomic/${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations (same order)
- `app/phenomic/env.vars.sh`
- `app/phenomic/env.${PROVISION_USING}.vars.sh`
- corresponding `app` customizations (same order)

## Roadmap

```sh
# Differenciate secrets store from registry, which would then only store things
# like non-secret host-level flags. Ex:
SECRETS_BACKEND=ansible_vault
SECRETS_BACKEND=hashicorp_vault

# Implement automated tests / Visual Regression Testing (as presets ?) - ex:
APP_TESTS_PRESET=behat
APP_TESTS_PRESET=gatling

APP_VRT_PRESET=gemini
APP_VRT_PRESET=puppeteer
```

See if the following rule is desirable :

Version numbers might be provided in `$PROVISION_USING` and would trigger additional lookups (ex: if `PROVISION_USING=docker-compose-3.4` then models looked up would be, in this order: `provision/docker-compose.vars.sh` + `provision/docker-compose-3.vars.sh` + `provision/docker-compose-3.4.vars.sh`, etc)
