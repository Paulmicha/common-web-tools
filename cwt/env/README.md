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
1. env files called config or env *includes* - purpose : aggregate env settings (global variables) necessary for configuring the local project instance and its services.

Aggregation will include (or more precisely - load using bash `source` command) the more generic files first, then gradually the more specific ones, each file allowing to provide its own customization. See *complements* documentation at `cwt/custom/complements/README.md`.

CWT provides a few example project dependencies and env includes, but its purpose is to be useful for your specific project(s). So the reason this process is detailed here is to better understand how to provide your own custom declarations.

## Project stack syntax

The `$PROJECT_STACK` variable is the main source used to determine all the possibilities of file names and paths that can be loaded during stack init (the *lookup paths*). The following rules apply to both types of dynamically generated lookup paths (dependencies and env includes) :

- version numbers are extracted after the last `-` and may use dots to indicate minor and/or patch versions
- variants are indicated after the "name" part of any declaration (project stack, software, etc.) by using 2 dashes `--`
- multiple values are separated using a single comma `,`
- extensions are special variants meant to provide a group of tools, and are declared using the prefix `p-`

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

Dependencies specify all services (or softwares) required to run the current project instance(s). They are used to list what needs to be provisioned on hosts - including the provisioning tool itself, testing, deployment or log-related tools, etc.

The list of dependencies is stored in the `$STACK_SERVICES` global variable. The syntax used to declare these dependencies allows to specify mutually exclusive alternative (i.e. uses either this program *OR* that one).

### Dependency declaration syntax

Files declaring dependencies are named `*dependencies.sh`, and use the following syntax :

```sh
# Add a software dependency.
require 'php'

# Version number is optional.
require 'php-7'
require 'php-5.6'

# Use the '..' prefix to specify a list of mutually exclusive alternatives.
require '..db'
require '..webserver'

# Each list of alternatives is a simple comma-separated string.
alternatives['..db']='mariadb-10,mysql-5,postgresql-10'
alternatives['..webserver']='apache-2.4,nginx'

# Alter software version (notably useful in specific dependencies files loaded
# after generic ones).
software_version['php']='5.6'
```

### Dependencies aggregation

Here's a "stack init" example listing its corresponding dependencies lookup paths. They represent all possibilities matching the `$PROJECT_STACK`, provisioning method (`$PROVISION_USING`), current host's OS and type (e.g. `local`, `remote`), and project's `$INSTANCE_TYPE` (e.g. `dev`, `test`, `qa`, `stage`, `preprod`, `live`, `production`).

Any existing file is included (sourced) in the order indicated, each one allowing to provide its own customization. See *complements* documentation at `cwt/custom/complements/README.md`.

```sh
# Running this on "Bash on Ubuntu on Windows 10" (tested on 2017/11/16) :
. cwt/stack/init.sh -s drupal-7--varnish-4,redis -p ansible-2 -y

# ... yields these corresponding stack dependencies lookup paths :
cwt/provision/dependencies.sh
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
cwt/provision/dev.dependencies.sh
cwt/provision/dev.ubuntu.dependencies.sh
cwt/provision/dev.ubuntu-14.dependencies.sh
cwt/provision/dev.ubuntu-14.04.dependencies.sh
cwt/provision/dev.local_host.dependencies.sh
cwt/provision/dev.ubuntu.local_host.dependencies.sh
cwt/provision/dev.ubuntu-14.local_host.dependencies.sh
cwt/provision/dev.ubuntu-14.04.local_host.dependencies.sh
cwt/provision/dev.ansible.dependencies.sh
cwt/provision/dev.ansible-2.dependencies.sh
cwt/provision/dev.ansible.local_host.dependencies.sh
cwt/provision/dev.ansible-2.local_host.dependencies.sh
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
cwt/app/drupal/dev.dependencies.sh
cwt/app/drupal/dev.ubuntu.dependencies.sh
cwt/app/drupal/dev.ubuntu-14.dependencies.sh
cwt/app/drupal/dev.ubuntu-14.04.dependencies.sh
cwt/app/drupal/dev.local_host.dependencies.sh
cwt/app/drupal/dev.ubuntu.local_host.dependencies.sh
cwt/app/drupal/dev.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/dev.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/dev.ansible.dependencies.sh
cwt/app/drupal/dev.ansible-2.dependencies.sh
cwt/app/drupal/dev.ansible.local_host.dependencies.sh
cwt/app/drupal/dev.ansible-2.local_host.dependencies.sh
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
cwt/app/drupal/7/dev.dependencies.sh
cwt/app/drupal/7/dev.ubuntu.dependencies.sh
cwt/app/drupal/7/dev.ubuntu-14.dependencies.sh
cwt/app/drupal/7/dev.ubuntu-14.04.dependencies.sh
cwt/app/drupal/7/dev.local_host.dependencies.sh
cwt/app/drupal/7/dev.ubuntu.local_host.dependencies.sh
cwt/app/drupal/7/dev.ubuntu-14.local_host.dependencies.sh
cwt/app/drupal/7/dev.ubuntu-14.04.local_host.dependencies.sh
cwt/app/drupal/7/dev.ansible.dependencies.sh
cwt/app/drupal/7/dev.ansible-2.dependencies.sh
cwt/app/drupal/7/dev.ansible.local_host.dependencies.sh
cwt/app/drupal/7/dev.ansible-2.local_host.dependencies.sh
```

## Configuration (env settings)

Env settings are global variables used to configure the local project instance and its services. Every time `cwt/stack/init.sh` is called, current instance's env file is (over)written.

### Env includes syntax

Files declaring env includes are named `*vars.sh`, and use the following syntax :

```sh
# Basic usage.
# 1. Will prompt for input during stack init (unless the -y argument is used).
# 2. Same thing, but entering an empty value will use the default value. Also,
#   when the -y argument is used, it will automatically use the default.
global PROJECT_STACK # 1.
global MY_VAR_NAME "Simple string declaration (non-configurable / no prompt to customize during init)"
global MY_VAR_NAME2 "[default]=test" # 2.

# Immediate variable substitution (uses current shell scope variables).
global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"

# Subshell can be used (callback must echo result).
global HOST_OS "[default]='$(u_host_get_os)'"

# Custom keys may be used, provided they don't clash with the following keys
# already used internally by CWT :
# - 'default'
# - 'value'
# - 'values'
# - 'no_prompt'
# - 'append'
# - 'if-VAR_NAME'
global MY_VAR_NAME3 "[key]=value [key2]='value 2'"

# The global declaration syntax also supports 'append' : it allows globals to be
# declared multiple times to add values (space-separated string).
# Notice there cannot be any space inside each value.
global MY_MULTI_VALUE_VAR "[append]=multiple"
global MY_MULTI_VALUE_VAR "[append]=declarations"
global MY_MULTI_VALUE_VAR "[append]=will-be"
global MY_MULTI_VALUE_VAR "[append]=appended/to"
global MY_MULTI_VALUE_VAR "[append]=a_SPACE_separated_string"
# Example read :
for val in $MY_MULTI_VALUE_VAR; do
  echo "MY_MULTI_VALUE_VAR value : $val"
done

# Finally, it supports conditional declaration.
global MY_VAR "hello value"
global MY_COND_VAR_NOMATCH "[if-MY_VAR]=test [default]=foo"
global MY_COND_VAR_MATCH "[if-MY_VAR]='hello value' [default]=bar"
# To verify (should only output MY_COND_VAR_MATCH) :
u_global_debug

# Deferred variable substitution (advanced usage : when the 3rd param is used,
# the global is not immediately exported in current shell).
global MY_DEFERRED_VAR "[default]=/example/absolute/path" true
global MY_DEPENDANT_VAR "[default]=\$MY_DEFERRED_VAR/test" true
u_global_foreach u_global_assign_value
# To verify (MY_DEPENDANT_VAR should output '/example/absolute/path/test') :
u_global_debug
```

### Env includes aggregation

The way this process works is :

- get `$PROJECT_STACK` value (see examples below) and `$PROVISION_USING` value - if not provided in `cwt/stack/init.sh` arguments
- add the common, generic `cwt/env/vars.sh` model
- assemble all includes found (*lookup paths*)
- assign values to the variables they contain by using terminal prompts - if not provided (or instructed to always use default values) in `cwt/stack/init.sh` arguments
- write the result to `cwt/env/current/vars.sh`

Here's a "stack init" example listing its corresponding env includes lookup paths. They represent all possibilities matching the `$PROJECT_STACK` and provisioning method (`$PROVISION_USING`).

Any existing file is included (sourced) in the order indicated, each one allowing to provide its own customization. See *complements* documentation at `cwt/custom/complements/README.md`.

```sh
# Calling stack init with these parameters :
. cwt/stack/init.sh -s drupal--p-contenta-1,redis,varnish-4,solr-5.5 -y

# ... yields these corresponding env includes lookup paths :
cwt/provision/docker-compose/vars.sh
cwt/provision/redis/vars.sh
cwt/provision/redis/docker-compose.vars.sh
cwt/provision/varnish/vars.sh
cwt/provision/varnish/docker-compose.vars.sh
cwt/provision/varnish/4/vars.sh
cwt/provision/varnish/4/docker-compose.vars.sh
cwt/provision/solr/vars.sh
cwt/provision/solr/docker-compose.vars.sh
cwt/provision/solr/5/vars.sh
cwt/provision/solr/5/docker-compose.vars.sh
cwt/provision/solr/5/5/vars.sh
cwt/provision/solr/5/5/docker-compose.vars.sh
cwt/provision/mailhog/vars.sh
cwt/provision/mailhog/docker-compose.vars.sh
cwt/provision/samba/vars.sh
cwt/provision/samba/docker-compose.vars.sh
cwt/provision/php/vars.sh
cwt/provision/php/docker-compose.vars.sh
cwt/provision/php/7/vars.sh
cwt/provision/php/7/docker-compose.vars.sh
cwt/provision/apache/vars.sh
cwt/provision/apache/docker-compose.vars.sh
cwt/provision/apache/2/vars.sh
cwt/provision/apache/2/docker-compose.vars.sh
cwt/provision/apache/2/4/vars.sh
cwt/provision/apache/2/4/docker-compose.vars.sh
cwt/provision/mariadb/vars.sh
cwt/provision/mariadb/docker-compose.vars.sh
cwt/provision/mariadb/10/vars.sh
cwt/provision/mariadb/10/docker-compose.vars.sh
cwt/provision/extensions/contenta/vars.sh
cwt/provision/extensions/contenta/docker-compose.vars.sh
cwt/provision/extensions/contenta/1/vars.sh
cwt/provision/extensions/contenta/1/docker-compose.vars.sh
cwt/app/extensions/contenta/vars.sh
cwt/app/extensions/contenta/docker-compose.vars.sh
cwt/app/extensions/contenta/1/vars.sh
cwt/app/extensions/contenta/1/docker-compose.vars.sh
cwt/custom/extensions/contenta/vars.sh
cwt/custom/extensions/contenta/docker-compose.vars.sh
cwt/custom/extensions/contenta/1/vars.sh
cwt/custom/extensions/contenta/1/docker-compose.vars.sh
cwt/app/drupal/env.vars.sh
cwt/app/drupal/env.docker-compose.vars.sh
```

## Lookup paths correspondance

Both examples listed above exhibit some common patterns in the correspondance rules used to match host, stack, or project instance related values.

### Lookup paths related to version numbers

TODO

### Lookup paths related to host's OS and type

TODO

### Lookup paths related to provisioning method

TODO

### Lookup paths related to instance type

TODO

### Lookup paths related to "extension" variants

TODO

## Roadmap

```sh
# Differenciate secrets store from registry, which would then only store things
# like non-secret host-level flags. Ex:
SECRETS_BACKEND=ansible_vault
SECRETS_BACKEND=hashicorp_vault

# Implement automated tests / Visual Regression Testing (as extensions ?) - ex:
APP_TESTS_PRESET=behat
APP_TESTS_PRESET=gatling

APP_VRT_PRESET=gemini
APP_VRT_PRESET=puppeteer
```
