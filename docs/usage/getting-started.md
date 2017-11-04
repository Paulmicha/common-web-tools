# Getting started

There are 2 ways to use CWT in old or new projects :

1. Use a single, "monolithic" repo for everything
1. Keep application code in a separate Git repo (default, see `.gitignore`)

## Option 1 first steps

- Download and/or copy&paste CWT files into project root dir (existing or new Git repo)
- Undo default ignored subfolders in `.gitignore` file if/as needed

## Option 2 first steps

- Download CWT in desired location (aka the project root dir)
- Clone the application into a subfolder named e.g. `web`, `public`, etc.
- Gitignore that subfolder by updating the `.gitignore` file accordingly
- [optional] Make any alterations necessary
- [optional] Maintain as a separate repo

## Next steps

When CWT files are in place alongside the rest of the project :

- Initialize "stack" (environment settings)
- Provision local and/or remote host
- Install new application instance(s) (local and/or remote)
- [optional] Implement automated tests
- [optional] Implement deployment to desired remote instance(s)

## Using CWT scripts

Unless otherwise stated, all CWT scripts are to be run on your computer (*local* host) from `/path/to/project/` as sudo or root.

**NB** : Currently, no exit codes are used in any top-level entry points listed below. These scripts (and all those sourced in the "main shell") use `return` instead of `exit`.

Regarding ways to alter the execution of existing scripts and/or its order, the pattern "Autoload" usually means :

- Use `return` when working in the main shell scope - i.e. in your custom scripts autoloaded from `cwt/custom/overrides` and `cwt/custom/complements`
- Wrap customizations in functions or subshells

## Initialize local instance env settings

*Purpose* : Specifies what kind of project we're working with - i.e its "stack" specifications, what kind of deployment / automated tests / CI workflow it uses, etc.

*When to run* : initially + on-demand to **add, remove, change** project specifications (overwrites local env settings).

```sh
. cwt/stack/init.sh
```

## Specify remote host

*Purpose* : Sets remote host address + installs SSH connexion using current user's keys. **Note** : for now, onky one remote host is supported. **TODO** : support Hashicorp Vault.

*When to run* : on-demand to **add or change** the remote host.

*Prerequisites* : SSH keys must already be set up & loaded in current user's bash session.

```sh
. cwt/remote/add_host.sh
```
