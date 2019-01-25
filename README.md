# Common Web Tools (CWT)

## TL;DR

Clone or download / copy / paste the files from this repo, open terminal in chosen dir and :

```sh
make
```

## WHAT

CWT is a scaffolding bash shell CLI to usual web project tasks. It's a generic, customizable and extensible toolbox for local (internal) development tasks.

CWT is not a program; it's the "glue" between programs. Third-party tools integration is provided by extensions which could have their own respective Git repositories. CWT includes by default (for now) a predefined list of extensions - like in the [DrupalVM](https://www.drupalvm.com/) project.

CWT "core" - this repo - contains common utilities related to managing global environment variables, some minimal local and remote host operations, optional git hooks intergration, and project instance self-tests.

CWT is *not* meant to be used in production. It was designed to assist the production of diverse projects for individual developers or teams.

## PURPOSE

CWT helps individual developers or teams to streamline a similar workflow across older and newer projects. It allows to **maintain a common CLI** and to easily swap out implementations in case we change our minds about technical choices.

CWT organizes (mostly bash shell) scripts around a set of conventions to implement in a **modular** way e.g. :

- host-level dependencies installation / setup (provisioning required packets/apps/services)
- get / generate services credentials
- building / running / stopping / destroying project instances with variants per env. type - e.g. dev, test, live... (i.e. allowing each to have different services or settings)
- generate / (re)write local app settings
- continuous (or on-demand) linting / watching / compiling of some project sources
- host-level setup / removal of periodic task(s) execution (cron jobs)
- automated tests
- deployment
- create / import / backup database
- remote 2-way sync
- etc.

## HOW

By providing some abstractions to complement, combine, replace or add any operations developers might need to work on diverse projects.

CWT relies on **file structure**, **naming conventions**, and a few concepts :

- **Globals** are the environment variables related to current project instance. They may be declared using the `global` function in files named `env.vars.sh` aggregated during initialization.
- **Bootstrap** deals with the inclusion of all the relevant source files and loads global variables (e.g. host type, instance type, etc) and functions. Any script that includes the file `cwt/bootstrap.sh` can use these. This depends on sourcing shell scripts using relative paths, which is made possible by the fact that *all* scripts (or `make` "shortcut" commands) must be run from the folder `$PROJECT_DOCROOT`.
- **Instance init** is a preliminary step that will setup current project instance. Among other things, it will aggregate and write local values for globals, optionally write application git hooks (opt-in by using the corresponding GIT-related globals - see `cwt/git/init.hook.sh`), and trigger some hooks in order to let extensions implement their own additional setup tasks. See `u_instance_init()` in `cwt/instance/instance.inc.sh` for details and usage example.
- **Actions** - also referred to as *entry points*, *operations*, *tasks*, or just *commands* - are scoped by subject, e.g. *instance init*, *app compile*, etc. CWT determines a list of available actions by looking up folders and shell scripts matching certain rules.
- **Hooks** are function calls mimicking events where "listening" or implementing entails creating some specific file(s) in certain path(s) corresponding to filters specified in arguments. They match actions by subjects and provide additional variants - which can use any global, and can either load all matching includes found, or only the most specific. See `hook()` and `u_hook_most_specific` in `cwt/utilities/hook.sh` for details and usage examples.

## Preprequisites

- Local host or VM with **Bash shell version 4+** (e.g. MacOS : `brew update && brew install bash && sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' && chsh -s /usr/local/bin/bash`)
- Git
- Existing project (new or old)
- [optional] Remote host accessible via SSH with Bash 4+
- [optional] *GNU make* in local / remote host(s)

Disclaimer : CWT is currently only tested on Debian-based Linux distros.

## Usage / Getting started

There are 2 ways to use CWT in existing or new projects :

1. Use a single, "monolothic" repo for the whole project
1. Keep application code in a separate Git repo (this is the default assumption in the `.gitignore` config featured in this repo)

The files contained in CWT core - this repo - may be placed either inside the application code (in this case `APP_DOCROOT` = `PROJECT_DOCROOT`), inside its parent folder (this is the default assumption and usually has its own separate "dev stack" Git repo), or even anywhere else on the host (see `APP_DOCROOT` and `APP_GIT_WORK_TREE` global env vars).

So the first step will always be to clone or download / copy / paste the files from this repo to desired location (in relation to your choice for this project instance source files organization described above), then :

1. Review the `.gitignore` file and adapt it to suit your needs.
1. Launch *instance init* action (e.g. run `make` or `make init`) - this will generate `readonly` global env vars and optional Makefile by default. See `cwt/instance/instance.inc.sh` and `cwt/utilities/global.sh` for details.
1. [optional] launch *host provision* action (e.g. run `make-host-provision`) - this is not implemented in CWT, but this "entry point" exists to streamline host-level software installation in extensions.
1. [optional] launch *instance start* action (e.g. run `make-instance-start`) - this is meant to run any service required to use or work on current project instance.

These steps are mere indications : in real life, you probably want to "wrap" these calls in your own scripts (e.g. to preset some arguments, etc), usually in the `./scripts` folder. Examples and detailed explanations are provided in CWT source code comments.

## File structure

```txt
/path/to/my-project/    ← Project root dir ($PROJECT_DOCROOT)
  ├── cwt/              ← CWT "core" source files. Update = delete + replace entire folder
  │   ├── app/          ← App-level tasks (e.g. watch, compile, lint, etc.)
  │   ├── env/          ← Default generic global env. vars
  │   ├── extensions/   ← Bundled generic CWT extensions (opt-in : see .cwt_extensions_ignore)
  │   ├── git/          ← Integration of Git hooks with CWT hooks + Git-related utilities
  │   │   └── samples/  ← [doc] Examples of git hooks implementations
  │   ├── host/         ← Host-level metadata / crontab / network utils + "abstract" provision action
  │   ├── instance/     ← Actions related to the entire project instance (init, destroy, start, stop)
  │   ├── test/         ← Self-test entry point / automated tests actions
  │   │   └── cwt/      ← CWT 'core' internal tests (uses shunit2 - see 'vendor' dir)
  │   ├── utilities/    ← CWT internal functions (hides complexity)
  │   └── vendor/       ← Bundled third-party dependencies (only shunit2 by default)
  ├── scripts/          ← Current project specific scripts
  │   └── cwt/          ← CWT-related project-specific extension, local files and overrides
  │       ├── extend/   ← [optional] Custom project-specific CWT extension
  │       ├── local/    ← [git-ignored] Generated files specific to this local instance
  │       └── override/ ← [optional] Allows to replace virtually any file sourced in CWT scripts
  ├── web/              ← [optional+configurable] Application dir ($APP_DOCROOT or $APP_GIT_WORK_TREE*)
  │   └── dist/         ← [optional+configurable] Publicly accessible application dir ($APP_DOCROOT*)
  └── .gitignore        ← Don't forget to review and edit to suit project needs
```

`*` : if using the multi-repo pattern, which is the default assumption.

## Adapt / Alter / Extend CWT

Altering or extending CWT involves either :

- creating bash shell scripts in the `scripts` dir
- creating your own generic extension(s) in `cwt/extensions` (1 folder = 1 extension)
- provide your own operations, globals, or implement CWT hooks in `scripts/cwt/extend`

Here are the different ways to adapt CWT to current project needs :

### Globals

Since every entry point sources `cwt/bootstrap.sh` to load CWT functions and globals, these (`readonly`) variables are available everywhere. Their values are assigned during *instance init* which generates a single, git-ignored script : `scripts/cwt/local/global.vars.sh`.

One of the most straightforward ways to customize or add globals is by providing your own `global.vars.sh` file in current project instance's `scripts` folder, however any extension can provide its own - be it in the folder of the extension directly, or inside any of its subfolder (called *subjects*).

If all you need is a constant, the following syntax will not prompt for user input in terminal during *instance init* :

```sh
global MY_CONSTANT_VALUE "the value"
```

And if you need to always prompt for input during *instance init* (when the `-y` flag is not set), use only the 1st argument :

```sh
global MUST_INPUT_ON_INIT
```

See `cwt/utilities/global.sh` for details about the `global()` function, but we'll mention here one of its most commonly useful feature : the ability to stack values on each call with the same var name, which will be separated by space (and can be placed in different files because they will share the same namespace during *instance init*), e.g. :

```sh
global VALUES_WILL_CONCAT "[append]=path/to/file-1.txt"
global VALUES_WILL_CONCAT "[append]=path/to/file-2.txt"
global VALUES_WILL_CONCAT "[append]=path/to/file-3.txt"
global VALUES_WILL_CONCAT "[append]='(if value has space or special characters, use quotes)'"

# Example usage elsewhere, once "instance init" has run :
for value in $VALUES_WILL_CONCAT; do
  echo "$value"
done
```

These declarations are to be placed inside files named `global.vars.sh`. To show where these files can be placed in order to get picked up for aggregation - and in which order - during *instance init* in current project, you can use the following convenience command :

```sh
make globals-lp
# Or :
cwt/env/global_lookup_paths.make.sh
```

CWT provides the followig globals by default (see `cwt/env/global.vars.sh`). These illustrate the syntax to declare default values and optional help text that will be displayed when user input is prompted in terminal during *instance init* when the `-y` flag is not set (otherwise it won't prompt for anything and just use the default value) :

```sh
global PROJECT_DOCROOT "[default]='$PWD' [help]='Absolute path to project instance. All scripts using CWT *must* be run from this dir. No trailing slash.'"
global APP_DOCROOT "[default]='$PROJECT_DOCROOT/web' [help]='The path usually publicly exposed by web servers. Useful if it differs from the rest of current project sources.'"

# [optional] Set these values for applications having their own separate repo.
# @see cwt/git/init.hook.sh
global APP_GIT_ORIGIN "[help]='Optional. Ex: git@my-git-origin.org:my-git-account/cwt.git. Allows projects to have their own separate repo.'"
global APP_GIT_WORK_TREE "[ifnot-APP_GIT_ORIGIN]='' [default]='$APP_DOCROOT' [help]='Some applications might contain APP_DOCROOT in their versionned sources. This global is the path of the git work tree (if different).'"
global APP_GIT_INIT_CLONE "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify if the APP_GIT_ORIGIN repo should automatically be cloned (once) during \"instance init\".'"
global APP_GIT_INIT_HOOK "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify a default selection of Git hooks should automatically trigger corresponding CWT hooks. WARNING : will override any git hook script if previously created.'"

global INSTANCE_TYPE "[default]=dev [help]='E.g. dev, stage, prod... It is used as the default variant for hook calls that do not pass any in args.'"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)' [help]='This value is used to identify different project instances and MUST be unique per host.'"
global PROVISION_USING "[default]=docker-compose [help]='Generic differenciator used by many hooks. It does not have to be explicitly named after the host provisioning tool used. It could be any distinction used as variants in hook implementations.'"
global HOST_TYPE "[default]=local [help]='Idem. E.g. local, remote...'"
global HOST_OS "$(u_host_os)"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_instance_write_mk()
# @see u_instance_task_name()
# @see Makefile
global CWT_MAKE_INC "[append]='$(u_cwt_extensions_get_makefiles)'"
global CWT_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"
```

Once *instance init* has been run, every global env. vars aggregated are (over)written in 2 files :

- `.env` file in `$PROJECT_DOCROOT`, which is meant for Makefile and other programs like `docker-compose` (see the `cwt/extensions/docker-compose` extension, disabled by default)
- `scripts/cwt/local/global.vars.sh`, which is exporting the resulting read-only shell variables and get loaded on every command that "bootstraps" CWT (see `cwt/bootstrap.sh`).

### Actions

CWT provides generic actions most projects usually need. Some preset commands designed to trigger common tasks (compilation, git hooks, etc) are in place, but except for *instance init* and some permission and ownership generic operations, these are merely "abstract" entry points : they exist so that extensions implement them in a modular way. They do nothing on their own.

`actions` are ordered by `subject`, which is expressed in the file structure like so :

- **folders** represent **subjects**,
- and their **files** represent **actions**.

Exceptions : folders beginning with a dot (e.g. `.git`), and files using double extensions (e.g. `my_file.inc.sh`) or beginning with a dot (e.g. `.cwt_actions_ignore`).

CWT will look in `./cwt` to determine default CWT actions, then it will do the samefor every folders in `cwt/extensions` and `scripts/cwt/extend`. For detailed explanations and examples, see `u_cwt_extend()` in `cwt/utilities/cwt.sh`.

To print the list of available actions in current project instance, you can use the following convenience command :

```sh
make list-actions
# Or :
cwt/instance/list_actions.make.sh
```

CWT provides basic actions most projects usually need such as instance-specific settings setup and preset commands designed to trigger common tasks (compilation, git hooks, etc). By default, CWT generates the following *make* shortcuts correponding to these *subject / action* pairs - also called *entry points* - during *instance init* (this will differ when extensions are enabled, added and/or removed) :

```txt
app/compile             (cwt/app/compile.sh)            - shortcut    $ make app-compile
app/git                 (cwt/app/git.sh)                - shortcut    $ make app-git
app/install             (cwt/app/install.sh)            - shortcut    $ make app-install
app/lint                (cwt/app/lint.sh)               - shortcut    $ make app-lint
app/watch               (cwt/app/watch.sh)              - shortcut    $ make app-watch
app/watch_stop          (cwt/app/watch_stop.sh)         - shortcut    $ make app-watch-stop
git/write_hooks         (cwt/git/write_hooks.sh)        - shortcut    $ make git-write-hooks
host/provision          (cwt/host/provision.sh)         - shortcut    $ make host-provision
host/registry_del       (cwt/host/registry_del.sh)      - shortcut*   $ make host-reg-del
host/registry_get       (cwt/host/registry_get.sh)      - shortcut*   $ make host-reg-get
host/registry_set       (cwt/host/registry_set.sh)      - shortcut*   $ make host-reg-set
instance/build          (cwt/instance/build.sh)         - shortcut**  $ make build
instance/destroy        (cwt/instance/destroy.sh)       - shortcut**  $ make destroy
instance/fix_ownership  (cwt/instance/fix_ownership.sh) - shortcut**  $ make fix-ownership
instance/fix_perms      (cwt/instance/fix_perms.sh)     - shortcut**  $ make fix-perms
instance/init           (cwt/instance/init.sh)          - shortcut*** $ make init # (or just "make")
instance/rebuild        (cwt/instance/rebuild.sh)       - shortcut**  $ make rebuild
instance/registry_del   (cwt/instance/registry_del.sh)  - shortcut**  $ make reg-del
instance/registry_get   (cwt/instance/registry_get.sh)  - shortcut**  $ make reg-get
instance/registry_set   (cwt/instance/registry_set.sh)  - shortcut**  $ make reg-set
instance/start          (cwt/instance/start.sh)         - shortcut**  $ make start
instance/stop           (cwt/instance/stop.sh)          - shortcut**  $ make stop
test/self_test          (cwt/test/self_test.sh)         - shortcut*** $ make self-test
```

- `*` : Shortening rules can be defined using the `CWT_MAKE_TASKS_SHORTER` global. Ex : `global CWT_MAKE_TASKS_SHORTER "[append]='something_too_long_for_make_shortcut/stlfms'"`
- `**` : The `instance` is implicit and omitted for default CWT actions' `make` shortcuts.
- `***` : Some exceptions are hardcoded in this repo's `./Makefile`. Others can be added using the `CWT_MAKE_INC` global. Ex : `global CWT_MAKE_INC "[append]='path/to/make_include.mk'"`

Additional rules for *subject / action* pairs :

- Dirnames starting with a dot in `cwt/extensions` are excluded from extensions list
- Manual exclusion is possible for either subjects or actions using gitignore-like files (`.cwt_subjects_ignore` inside an extension folder, and `.cwt_actions_ignore` inside a subject dir). These files contain 1 name per line - the name of the subject or action to exclude (folder name or file name without extension).

### Hooks

Most default actions CWT provides out of the box use hooks so that extensions can react and implement their own operations. The convention used allows to predict which filepaths to use for implementing given hooks. To verify which files can be used (and will be sourced if they exist) when a hook is triggered, you can use the following convenience command :

```sh
make hook-debug a:start
# Or :
cwt/instance/hook.make.sh -d -t a:start
```

Given the example call above, here are the resulting lookup paths out of the box :

```txt
cwt/app/start.hook.sh
cwt/git/start.hook.sh
cwt/host/start.hook.sh
cwt/extensions/file_registry/host/start.hook.sh
cwt/instance/start.hook.sh
cwt/extensions/file_registry/instance/start.hook.sh
cwt/test/start.hook.sh
```

This result will differ when extensions are enabled, added and/or removed.

Additional parameters allow to target specific subjects and/or actions. See `cwt/utilities/hook.sh` for detailed examples on using the `hook()` function.

Here's an example illustrating some of the most commonly used filters :

```sh
# Triggers the 'fs_perms_set' action, filtered by subject ('app' and 'instance')
# and allowing variants based on 3 different globals :
hook -s 'app instance' \
  -a 'fs_perms_set' \
  -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'

# To verify which files can be used (and will be sourced) when this hook is
# triggered :
make hook-debug s:app instance a:fs_perms_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
```

Given the following globals values (which get set during *instance init*) : `PROVISION_USING='docker-compose-3'`, `HOST_TYPE='local'`, and `INSTANCE_TYPE='dev'`, the example above would output :

```txt
cwt/app/fs_perms_set.hook.sh
  exists
cwt/app/fs_perms_set.docker-compose.hook.sh
cwt/app/fs_perms_set.docker-compose-3.hook.sh
cwt/app/fs_perms_set.docker-compose-3.local.hook.sh
cwt/app/fs_perms_set.docker-compose-3.local.dev.hook.sh
cwt/app/fs_perms_set.docker-compose-3.dev.hook.sh
cwt/app/fs_perms_set.local.hook.sh
cwt/app/fs_perms_set.local.dev.hook.sh
cwt/app/fs_perms_set.dev.hook.sh
cwt/instance/fs_perms_set.hook.sh
  exists
cwt/instance/fs_perms_set.docker-compose.hook.sh
cwt/instance/fs_perms_set.docker-compose-3.hook.sh
cwt/instance/fs_perms_set.docker-compose-3.local.hook.sh
cwt/instance/fs_perms_set.docker-compose-3.local.dev.hook.sh
cwt/instance/fs_perms_set.docker-compose-3.dev.hook.sh
cwt/instance/fs_perms_set.local.hook.sh
cwt/instance/fs_perms_set.local.dev.hook.sh
cwt/instance/fs_perms_set.dev.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.docker-compose.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.docker-compose-3.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.docker-compose-3.local.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.docker-compose-3.local.dev.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.docker-compose-3.dev.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.local.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.local.dev.hook.sh
cwt/extensions/file_registry/instance/fs_perms_set.dev.hook.sh
```

Another hook function exists when we need to only source the "most specific" match.

The notion of specificity uses the file having the deepest path and the highest number of dots in its path. In case of equality, the first match will be used. This "score" - a simple addition of slash & dot count in the filepath - allows to differenciate CWT's file-name-based implementations (hooks, globals, etc.) because of the way its patterns work :

- multiple extension (i.e. variants : `pre_bootstrap.docker-compose.hook.sh`)
- complements (e.g. `scripts/complements/test/self_test.hook.sh`)
- overrides (e.g. `scripts/cwt/overrides/extensions/docker-compose/instance/init.docker-compose.hook.sh`)

NB : some "artificial" advantage is given to the project-specific `./scripts` path in comparison to generic CWT extensions so that the custom implementations always take precedence over extensions'. Here's an example :

```sh
# Basic usage - only sources 1 match (the "most specific") :
u_hook_most_specific -s 'instance' -a 'registry_get' -v 'HOST_TYPE'

# Dry run example.
# @see u_stack_template() in cwt/extensions/docker-compose/stack/stack.inc.sh
local hook_most_specific_dry_run_match
u_hook_most_specific 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t
echo "$local hook_most_specific_dry_run_match" # <- Prints the most specific "docker-compose.yml" found.
```

### Extensions

CWT Extensions can provide additional actions and react to hooks. Any folder present in the `cwt/extensions` dir is recognized as a CWT extension, as well as `scripts/cwt/extend` which is meant for non-reusable, project-psecific implementations.

Extensions in `cwt/extensions` can be enabled or disabled by editing the file `cwt/extensions/.cwt_extensions_ignore` (use 1 folder name per line to disable, or delete the line to enable).

Additional rules :

- Once *instance init* has run, any file named `make.mk` inside the extension folder will be included when `make` commands are executed - e.g. `cwt/extensions/docker4drupal/make.mk`.
- Any file named `global.vars.sh` inside the extension folder will be aggregated during *instance init*.
- TODO [evol] CWT could also provide some minimalistic way to declare extensions' dependencies, i.e. as in `cwt/extensions/docker4drupal/.cwt_requires` for example.

### Overrides

This mecanism exists so that when some existing functionality or extension from CWT impedes anything specific to a project, we can entirely skip that file and replace it with our own version.

If the "counterpart" of a given script exists in the folder `scripts/cwt/override`, it will be used *instead* of the original file. This allows to replace any includes or hook implementations.

Example : if we want to override `cwt/git/init.hook.sh` - effectively bypassing the existing implementation, we'll create the following file :

```txt
scripts/cwt/override/git/init.hook.sh
```

The matching is done by by replacing the leading `cwt/` in filepaths with `scripts/cwt/override/`. It works for extensions too. Here's an example using an include instead of a hook implementation :

```txt
cwt/extensions/docker-compose/docker-compose.inc.sh
-> scripts/cwt/override/extensions/docker-compose/docker-compose.inc.sh
```
