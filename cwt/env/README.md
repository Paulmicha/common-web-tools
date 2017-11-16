# Environment settings

The variables written and loaded using the scripts in `cwt/env` directory are used in all CWT tasks. Some are common to any type of stack, while others are specific to certain variants.

The very first step required to use CWT is writing current instance's env settings, a task referred to as **stack init** :

```sh
# This is the starting point.
# It provides options and/or terminal prompts to obtain all mandatory values,
# then calls cwt/env/write.sh.
. cwt/stack/init.sh

# Optional arguments examples.
# Details : see cwt/stack/init/get_args.sh
. cwt/stack/init.sh -p ansible # Specify provisioning tool.
. cwt/stack/init.sh -s nodejs-8 -y # Specify project stack + bypass prompts (will use defaults).
. cwt/stack/init.sh -s drupal-7--redis,varnish-4,solr -y # Add services to the stack using '--' separator.
```

This process generates a single file (`cwt/env/current/vars.sh`) by assembling 2 types of files :

1. dependency files - purpose : aggregate host-level *services* (or softwares) dependencies;
1. env files called config or env *models* - purpose : aggregate env settings (global variables) necessary for configuring the local project instance and its services.

Aggregation will include (or more precisely - *source*) the more generic files first, then gradually the more specific ones, and finally their corresponding customization (see *complements* in *autoload*).

CWT provides a few example project dependencies and env models, but its purpose remains to be useful for your specific project(s). So the reason this process is detailed here is to better understand how to provide your own custom declarations.

## Common syntax

The following rules apply to both types of files in dynamically generated lookup paths (dependencies and env models) :

- version numbers are extracted after the last `-` and may use dots to indicate minor and/or patch versions
- variants are indicated after the "name" part of any declaration (project stack, software, etc.) by using 2 dashes `--`
- multiple values are separated using a single comma `,`
- presets are special variants meant to provide a group of tools, and are declared using the prefix `p-`

Note that there can be **no space** between these characters for a single declaration.

```sh
# These are all valid examples illustrating the syntax rules described above :
PROJECT_STACK='drupal'
PROJECT_STACK='drupal-7'
PROJECT_STACK='drupal-7.56'
PROJECT_STACK='drupal-7.56--solr-5'
PROJECT_STACK='drupal-7--solr-5.5,redis'
PROJECT_STACK='drupal--solr,redis,varnish-4'
PROJECT_STACK='drupal-7.56--solr,redis,p-nodejs-8'
PROJECT_STACK='drupal-8--p-contenta-hyperhtml-2,redis,elasticsearch'
```

## Software dependencies (required host services)

Dependencies specify all services (or softwares) required to run the current project instance(s). They are used to list what will be provisioned on hosts - including the provisioning tool itself, testing, deployment or log-related tools, etc.

The list of dependencies is stored in the `$STACK_SERVICES` global variable. The syntax used to declare these dependencies allows to specify mutually exclusive alternative (uses either this OR that).

### Dependency declaration syntax

Commented sample from example file `cwt/app/drupal/dependencies.sh` :

```sh
# Separate each item with a comma.
# Use the '..' prefix to specify a list of mutually exclusive alternatives.
softwares='php-7,..db,..webserver'

# Each list of alternatives is a simple comma-separated string.
alternatives['..db']='mariadb-10,mysql-5,postgresql-10'
alternatives['..webserver']='apache-2.4,nginx'
```

### Aggregation

Here's a list of examples and their corresponding lookup paths. They represent possibilities corresponding to the project stack, provisioning method, and current host's OS and type (e.g. local, remote).

Any existing file is included (sourced) in the order indicated.

```sh
# Running this on "Bash on Ubuntu on Windows 10" (tested on 2017/11/16) :
. cwt/stack/init.sh -s drupal-7--solr-5,redis -p ansible-2 -y

# ... yields these corresponding stack dependencies lookup paths :
cwt/provision/local_host.dependencies.sh
cwt/provision/ubuntu.dependencies.sh
cwt/provision/ubuntu-14.dependencies.sh
cwt/provision/ubuntu-14.04.dependencies.sh
cwt/provision/ubuntu.local_host.dependencies.sh
cwt/provision/ubuntu-14.local_host.dependencies.sh
cwt/provision/ubuntu-14.04.local_host.dependencies.sh
cwt/provision/ansible.dependencies.sh
cwt/provision/ansible.ubuntu.dependencies.sh
cwt/provision/ansible.ubuntu-14.dependencies.sh
cwt/provision/ansible.ubuntu-14.04.dependencies.sh
cwt/provision/ansible-2.dependencies.sh
cwt/provision/ansible-2.ubuntu.dependencies.sh
cwt/provision/ansible-2.ubuntu-14.dependencies.sh
cwt/provision/ansible-2.ubuntu-14.04.dependencies.sh
cwt/provision/ansible.local_host.dependencies.sh
cwt/provision/ansible.ubuntu.local_host.dependencies.sh
cwt/provision/ansible.ubuntu-14.local_host.dependencies.sh
cwt/provision/ansible.ubuntu-14.04.local_host.dependencies.sh
cwt/provision/ansible-2.local_host.dependencies.sh
cwt/provision/ansible-2.ubuntu.local_host.dependencies.sh
cwt/provision/ansible-2.ubuntu-14.local_host.dependencies.sh
cwt/provision/ansible-2.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/dependencies.sh
cwt/app/drupal/local_host.dependencies.sh
cwt/app/drupal/ubuntu.dependencies.sh
cwt/app/drupal/ubuntu-14.dependencies.sh
cwt/app/drupal/ubuntu-14.04.dependencies.sh
cwt/app/drupal/ubuntu.local_host.dependencies.sh
cwt/app/drupal/ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/ansible.dependencies.sh
cwt/app/drupal/ansible.ubuntu.dependencies.sh
cwt/app/drupal/ansible.ubuntu-14.dependencies.sh
cwt/app/drupal/ansible.ubuntu-14.04.dependencies.sh
cwt/app/drupal/ansible-2.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu-14.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu-14.04.dependencies.sh
cwt/app/drupal/ansible.local_host.dependencies.sh
cwt/app/drupal/ansible.ubuntu.local_host.dependencies.sh
cwt/app/drupal/ansible.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/ansible.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/ansible-2.local_host.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu.local_host.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/ansible-2.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/7/dependencies.sh
cwt/app/drupal/7/local_host.dependencies.sh
cwt/app/drupal/7/ubuntu.dependencies.sh
cwt/app/drupal/7/ubuntu-14.dependencies.sh
cwt/app/drupal/7/ubuntu-14.04.dependencies.sh
cwt/app/drupal/7/ubuntu.local_host.dependencies.sh
cwt/app/drupal/7/ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/7/ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/7/ansible.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu-14.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu-14.04.dependencies.sh
cwt/app/drupal/7/ansible-2.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu-14.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu-14.04.dependencies.sh
cwt/app/drupal/7/ansible.local_host.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu.local_host.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/7/ansible.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/7/ansible-2.local_host.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu.local_host.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/7/ansible-2.ubuntu-14.04.local_host.dependencies.sh
```

## Configuration aggregation (env settings)

```sh
# Env models syntax examples - see cwt/env/vars.sh

# 1. No default value provided.
define PROJECT_STACK

# 2. Immediate variable substitution (uses current shell scope variables).
define PROJECT_DOCROOT "[default]=$PWD"

# 3. Subshell demo (callback must echo result).
define HOST_OS "[default]=$(u_host_get_os)"

# 4. Variable substitution during env vars aggregation - see :
# cwt/stack/init/aggregate_env_vars.sh
define APP_DOCROOT "[default]=\$PROJECT_DOCROOT/web"
```

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

- `cwt/provision/${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations
- `cwt/app/contenta/env.vars.sh`
- `cwt/app/contenta/env.${PROVISION_USING}.vars.sh`
- corresponding `app` customizations (same order)

### Example 2 : `PROJECT_STACK=drupal-7--php-5.4,redis,solr-3`

- `cwt/provision/${PROVISION_USING}.vars.sh`
- `cwt/provision/php/${PROVISION_USING}.vars.sh`
- `cwt/provision/php/5.4/${PROVISION_USING}.vars.sh`
- `cwt/provision/redis/${PROVISION_USING}.vars.sh`
- `cwt/provision/solr/${PROVISION_USING}.vars.sh`
- `cwt/provision/solr/3/${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations (same order)
- `cwt/app/drupal/env.vars.sh`
- `cwt/app/drupal/env.${PROVISION_USING}.vars.sh`
- `cwt/app/drupal/7/env.vars.sh`
- `cwt/app/drupal/7/env.${PROVISION_USING}.vars.sh`
- corresponding `app` customizations (same order)

### Example 3 : `PROJECT_STACK=phenomic--libp2p,p-preact`

- `cwt/provision/${PROVISION_USING}.vars.sh`
- `cwt/provision/libp2p/${PROVISION_USING}.vars.sh`
- `cwt/provision/presets/phenomic/preact.vars.sh`
- `cwt/provision/presets/phenomic/preact.${PROVISION_USING}.vars.sh`
- corresponding `provision` customizations (same order)
- `cwt/app/phenomic/env.vars.sh`
- `cwt/app/phenomic/env.${PROVISION_USING}.vars.sh`
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
