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
