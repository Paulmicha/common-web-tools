# Frequent tasks (howtos / FAQ)

Prerequisites : see [getting started](getting-started.md).

## Install host-level dependencies

*Purpose* : Makes sure everything needed to run the app, the tests, the compilation tasks, etc. is installed.

*When to run* : initially + on-demand to **add** host-level dependencies (local and/or remote).

*Prerequisites* : `cwt/stack/init.sh`

```sh
# To provision local host :
. cwt/stack/setup.sh

# To provision a remote host :
. cwt/remote/setup.sh
```

## Manage host services

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

## Initialize application instance

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

## Reset application instance

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

## Manage specific application tasks

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

## Deploy to remote

*Purpose* : Depending on specified instance parameters, deployment typically executes tests and/or custom scripts. It should result in an updated remote instance.

*When to run* : on-demand.

*Prerequisites* : `cwt/remote/init.sh`

```sh
# Target remote using 1st arg (instance domain) :
. cwt/remote/deploy.sh test.example.com
```

## 2-way Sync

*Purpose* : Some projects use a database and/or require files (e.g. media) to be synchronized between remote and local instances. This makes sure these can easily be fetched and/or sent.

*When to run* : on-demand.

*Prerequisites* :

- Local : `cwt/stack/init.sh`
- Remote : `cwt/remote/add_host.sh` + `cwt/remote/init.sh`

```sh
# TODO
```
