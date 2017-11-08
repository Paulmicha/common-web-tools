# Common Web Tools (CWT)

WIP / not ready for use yet (re-organization + evaluation stage, documentation-driven).

**Documentation** : [paulmicha.github.io/common-web-tools](https://paulmicha.github.io/common-web-tools/)

## WHAT

Scripts bash for usual devops tasks aimed at relatively small web projects.

CWT is not a program; it's a generic, customizable "glue" between programs. Simple, loosely articulated wrapper scripts.

## PURPOSE

Provide a common set of commands to execute variable implementations of the following tasks :

- install host-level dependencies (provision required packets/apps/services) - locally and/or remotely
- instanciate project locally and/or remotely, with variants per env. type - dev, test, live... (e.g. get or generate services credentials, write local app settings, create database, build...)
- implement deployment and/or automated tests
- remote 2-way sync

CWT targets individual developers or relatively small teams attempting to streamline or implement a common workflow across older *and* newer projects.

## HOW

Abstracting differences to streamline recurrent devops needs. There already are free existing tools addressing some tasks, such as :

- Ansible roles (e.g. GeerlingGuy/DrupalVM)
- docker-compose (e.g. wodby/docker4drupal)
- Ansistrano, Portainer, Swarm, Helm, draft.sh, Dokku, Jenkins, Drone, Rancher, Mesos...

The approach here is to provide a minimal base for abstracting usual tasks while allowing to complement, combine, replace or add specific operations **with or without** existing tools.

## WHY

To be more productive. To [standardize](https://imgs.xkcd.com/comics/standards.png) the use of common solutions for targeted use cases - see *purpose*.

Over the years, the maintenance of older projects can become tedious. For instance, when old VMs are deleted, it can be difficult to recreate a compatible local dev environment supporting all dependencies from that project "technological era".

While tools like Ansible, `docker-compose` or `nvm` already address these concerns, adapting or integrating such projects to use these tools for common tasks requires some amount of work (or "glue").

## Preprequisites

- Local & remote hosts or VMs with bash support
- Git
- Existing project (new or old)

CWT is currently only tested on Debian and/or Ubuntu Linux hosts.

## Usage

There are 2 ways to use CWT in existing or new projects :

1. Use a single, "monolothic" repo for everything
1. Keep application code in a separate Git repo (default, see `.gitignore`)

### Option 1 first steps

- Download and/or copy&paste CWT files into project root dir (existing or new Git repo)
- Undo default ignored subfolders in `.gitignore` file if/as needed

### Option 2 first steps

- Download CWT in desired location (aka the project root dir)
- Clone the application into a subfolder named e.g. `web`, `public`, etc.
- Gitignore that subfolder by updating the `.gitignore` file accordingly
- [optional] Make any alterations necessary
- [optional] Maintain as a separate repo

### Next steps

When CWT files are in place alongside the rest of the project :

- Initialize "stack" (environment settings)
- Provision local and/or remote host
- Install new application instance(s) (local and/or remote)
- [optional] Implement automated tests
- [optional] Implement deployment to desired remote instance(s)

See section *Frequent tasks (howtos / FAQ)* for details.

## File structure

```txt
/path/to/project/           ← Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              ← App setup / watch / (re)build scripts.
  │   ├── custom/
  │   │   ├── complements/  ← [optional] Add your custom script complements here (see "Autoload").
  │   │   └── overrides/    ← [optional] Add your custom script overrides here (see "Autoload").
  │   ├── db/               ← Database-related scripts.
  │   ├── env/              ← Environment settings write / load scripts.
  │   │   └── current/      ← Generated settings specific to local instance (git-ignored).
  │   ├── git/
  │   │   └── hooks/        ← Entry points for auto-exec tests, code linting, etc.
  │   ├── provision/        ← Host-level dependencies setup scripts.
  │   ├── remote/           ← Remote operations scripts (add, provision, etc.)
  │   │   └── deploy/       ← Deployment-related scripts.
  │   ├── stack/            ← Services and/or workers management scripts.
  │   ├── test/             ← Automated tests related scripts.
  │   └── utilities/        ← Bash functions includes (see "Autoload").
  ├── dumps/                ← Database dump files (git-ignored).
  ├── web/                  ← [optional] The app dir - can be outside project dir ($APP_DOCROOT).
  └── .gitignore            ← Replace with your own and/or edit.
```

## Frequent tasks (howtos / FAQ)

Unless otherwise stated, all the examples below are to be run on *local* host from `/path/to/project/` as sudo or root.

**NB** : Currently, no exit codes are used in any top-level entry points listed below. These scripts (and all those sourced in the "main shell") use `return` instead of `exit`.

Regarding ways to alter the execution of existing scripts and/or its order, the pattern "Autoload" usually means :

- Use `return` when working in the main shell scope - i.e. in your custom scripts autoloaded from `cwt/custom/overrides` and `cwt/custom/complements`
- Wrap customizations in functions or subshells

### Initialize local instance env settings

*Purpose* : Specifies what kind of project we're working with - i.e its "stack" specifications, what kind of deployment / automated tests / CI workflow it uses, etc.

*When to run* : initially + on-demand to **add, remove, change** project specifications (overwrites local env settings).

```sh
. cwt/stack/init.sh
```

### Install host-level dependencies

*Purpose* : Makes sure everything needed to run the app, the tests, the compilation tasks, etc. is installed.

*When to run* : initially + on-demand to **add** host-level dependencies (local and/or remote).

*Prerequisites* : `cwt/stack/init.sh`

```sh
# To provision local host :
. cwt/stack/setup.sh

# To provision a remote host :
. cwt/remote/setup.sh
```

### Specify remote host

*Purpose* : Sets remote host address + installs SSH connexion using current user's keys. **Note** : for now, onky one remote host is supported. **TODO** : support Hashicorp Vault.

*When to run* : on-demand to **add or change** the remote host.

*Prerequisites* : SSH keys must already be set up & loaded in current user's bash session.

```sh
. cwt/remote/add_host.sh
```

### Manage host services

*Purpose* : Starts, stops, restarts the necessary host services.

*When to run* : on-demand.

*Prerequisites* :

- Local : `cwt/stack/setup.sh
- Remote : `cwt/remote/add_host.sh` + `cwt/remote/setup.sh`

```sh
. cwt/stack/start.sh
. cwt/stack/restart.sh
. cwt/stack/stop.sh
. cwt/stack/rebuild.sh # For docker-compose, e.g. when modifying images.

# On remote (1st arg = instance domain) :
. cwt/remote/start.sh test.example.com
. cwt/remote/restart.sh test.example.com
. cwt/remote/stop.sh test.example.com
. cwt/remote/rebuild.sh test.example.com # For docker-compose, e.g. when modifying images.
```

### Initialize application instance

*Purpose* : Includes all steps necessary to produce a working instance of the project, ready to be started. For example, this would include tasks like local database creation, writing specific settings files, etc.

*When to run* : initially + on-demand to **add, remove, change** specific instance settings or features.

*Prerequisites* :

- Local : `cwt/stack/start.sh`
- Remote : `cwt/remote/start.sh`

```sh
# To initialize local project instance :
. cwt/app/init.sh

# To initialize a remote project instance (1st arg = instance domain) :
. cwt/remote/init.sh test.example.com
```

### Reset application instance

*Purpose* : Restores an instance to its "factory" / default state. Typically wipes the database and relaunches `cwt/app/init.sh`.

*When to run* : on-demand.

*Prerequisites* :

- Local : `cwt/app/init.sh`
- Remote : `cwt/remote/init.sh`

```sh
# To reset local project instance :
. cwt/app/reset.sh

# To reset a remote project instance (1st arg = instance domain) :
. cwt/remote/reset.sh test.example.com
```

### Manage specific application tasks

*Purpose* : Builds, watches app sources (for auto-compilation on save), runs tests.

*When to run* : on-demand.

*Prerequisites* :

- Local : `cwt/stack/init.sh`
- Remote : `cwt/remote/init.sh`

```sh
. cwt/app/watch.sh
. cwt/app/build.sh
. cwt/app/rebuild.sh
. cwt/app/test.sh

# On remote (1st arg = instance domain) :
. cwt/remote/build.sh test.example.com
. cwt/remote/rebuild.sh test.example.com
. cwt/remote/test.sh test.example.com
```

### Deploy to remote

*Purpose* : Depending on specified instance parameters, deployment typically executes tests and/or custom scripts. It should result in an updated remote instance.

*When to run* : on-demand.

*Prerequisites* : `cwt/remote/init.sh`

```sh
# Target remote using 1st arg (instance domain) :
. cwt/remote/deploy.sh test.example.com
```

### 2-way Sync

*Purpose* : Some projects use a database and/or require files (e.g. media) to be synchronized between remote and local instances. This makes sure these can easily be fetched and/or sent.

*When to run* : on-demand.

*Prerequisites* :

- Local : `cwt/stack/init.sh`
- Remote : `cwt/remote/add_host.sh` + `cwt/remote/init.sh`

```sh
# TODO
```
