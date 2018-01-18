# CWT Autoload

Explicitly depends on *folders & files naming* convention (see [patterns](https://paulmicha.github.io/common-web-tools/about/patterns.html)).

## Configuration (env settings)

Env settings are global variables used to configure the local project instance and its services. Every time `cwt/stack/init.sh` is called, current instance's env file is (over)written.

### Syntax

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

# Subshell can be used (callback must echo result).
global HOST_OS "[default]='$(u_host_get_os)'"

# Variable substitution (requires that the other var be already declared).
global APP_DOCROOT "[default]=\$PROJECT_DOCROOT/web"

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
u_exec_foreach_env_vars u_assign_env_value
u_print_env
```

### Globals aggregation (autoload)

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
