# Common Web Tools (CWT) documentation - Prerequisites

Once imported into your project (see [getting started](usage/getting-started.md)), this page details under which conditions CWT scripts are designed to work.

## Using CWT scripts

Unless otherwise stated, all the examples below are to be run on *local* host from `/path/to/project/` as sudo or root.

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
