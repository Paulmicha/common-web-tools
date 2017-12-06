# Common Web Tools (CWT)

WIP / not ready for use yet (re-organization + evaluation stage, documentation-driven).

**Documentation** : [paulmicha.github.io/common-web-tools](https://paulmicha.github.io/common-web-tools/)

## WHAT

Scripts bash for usual devops tasks aimed at relatively small web projects.

CWT is not a program; it's a generic, customizable "glue" between programs. Simple, loosely articulated bash scripts.

## PURPOSE

Provide a common set of commands to execute variable implementations of the following tasks :

- install host-level dependencies (provision required packets/apps/services) - locally and/or remotely
- instanciate project locally and/or remotely, with variants per env. type - dev, test, live... (e.g. get or generate services credentials, write local app settings, create database, build...)
- implement deployment and/or automated tests
- remote 2-way sync

CWT targets individual developers or relatively small teams attempting to streamline or implement a common workflow across older *and* newer projects.

## HOW

Abstracting differences to streamline recurrent devops needs.

The approach here is to provide a minimal base for abstracting usual tasks while allowing to complement, combine, replace or add specific operations **with or without** [existing tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html).

## WHY

To be more productive. To easily test and quickly throw away what doesn't work. To [standardize](https://imgs.xkcd.com/comics/standards.png) the use of common solutions for targeted use cases - see *purpose*.

Productivity (and simplicity) are relative and complex topics, so it might as well come down to questions like :

- "does it look like I'll bother enough ?"
- "what's there to gain ?"

While tools like Ansible, `docker-compose` or `nvm` already address these concerns, adapting or integrating such projects to use these tools for common tasks requires some amount of work (or "glue").

"*[...] There are core parts of the technology that deliver most of the value / differentiator, and these are important to get right. There’s usually then a bunch of other software and services which is more like scaffolding; **you have it around in order to get stuff done**.*
*[...] “Mash-up” shouldn’t be a dirty hackfest concept.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

See also RDX's article from 2016/07/20 : [Modern Software Over-Engineering Mistakes](https://medium.com/@rdsubhas/10-modern-software-engineering-mistakes-bc67fbef4fc8).

## What could an ideal solution look like ?

The ideal solution would be measured in cognitive ressource - i.e. how do I quickly get these problems out of the way, *everytime* ?

It can seem titanesque to evaluate many [tools available nowadays](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html), so patterns like *presets* (or *recipes*) / declarative approaches (i.e. `*.yml` files) could be concepts simple enough to quickly "get".

My current intuition of an "ideal" scaffolding tool is to apply focus on [language](https://pierrelevyblog.com/2017/10/06/the-next-platform) and communication (information design) - that's the ultimate goal.

"*I want to hear from people pushing standard stuff beyond its limits. I think we grossly underestimate what off-the-shelf systems can do, and grossly overestimate the capabilities of the things we develop ourselves. It’s time to talk much more about real-world, practical, medium-enterprise software architecture.*

*[...] Software development should be the tool of last resort: “we’re building this because it doesn’t exist in the form we need it”. I want to hear from more tech leaders about how they solved a problem without building the software, and tactics for avoiding development. [...] I want to hear more about projects that deferred decisions and put off architecting until much later in the process.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

TODO document software evaluation process

TODO "frontier" (borders, delimitation) / what modularity teaches is to [hide complexity](https://www.youtube.com/watch?v=vypCsVm5z28) by fragmentation (*"people got mad when I put it all in one file"*).

TODO explore relativity in [shell scopes](http://wiki.bash-hackers.org/scripting/processtree) (wrapping, isolation) - e.g. `local`, `export`...

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

## File structure (and status)

CWT is under construction. Folders might still move around depending on its use, until I feel it can start proper versionning. Consider this repo a scratchpad for now.

CWT essentially relies on a relative global namepace. Its creation process involves building it "on the fly" in other side projects in which each step listed above (*Next steps*) is achieved by specific, custom scripts placed in a different `scripts` dir alongside `cwt` in `PROJECT_DOCROOT`. In such cases, `CWT_CUSTOM_DIR` is also set to `$PROJECT_DOCROOT/scripts` (See the *Alter / Extend CWT* section).

Ultimately, it should not compete with [other projects](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) (and I couldn't find a better word than "glue" for now, sorry).

This section illustrates a minimalist approach to organizational problems. It's still under study. Long-term considerations involve code generators, IEML, and the relationship between philosophy and programming ("naming things", "no language exists in isolation" - i.e. [schema.org](http://schema.org/docs/full.html)). Short-term : makefile integration ?

The file structure follows [loose naming and folder structure conventions](https://paulmicha.github.io/common-web-tools/about/patterns.html). Typically facts, actions, subjects are used to categorize includes of bash scripts meant to be sourced directly inside custom scripts (not included in the CWT project).

```txt
/path/to/project/           ← Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              ← [WIP] App init / (re)build / watch includes.
  │   ├── custom/           ← [configurable] default "modules" dir (alter or extend CWT. $CWT_CUSTOM_DIR).
  │   ├── db/               ← [WIP] Database-related includes.
  │   ├── env/              ← Environment settings includes (global variables).
  │   │   └── current/      ← Generated settings specific to local instance (git-ignored).
  │   ├── git/              ← Versionning-related includes.
  │   │   └── hooks/        ← [WIP] Entry points for auto-exec (tests, code linting, etc.)
  │   ├── provision/        ← [WIP] Host-level dependencies related includes (softwares setup).
  │   ├── remote/           ← [TODO] Remote operations includes (add, provision, etc.)
  │   │   └── deploy/       ← [TODO] Deployment-related includes.
  │   ├── stack/            ← [WIP] Services and/or workers management includes.
  │   ├── test/             ← [TODO] Automated tests related includes.
  │   │   └── self/         ← [TODO] CWT internal tests.
  │   └── utilities/        ← CWT internal functions (hides complexity).
  ├── dumps/                ← [configurable] Database dump files (git-ignored).
  ├── web/                  ← [configurable] The app dir - can be outside project dir ($APP_DOCROOT).
  └── .gitignore            ← Replace with your own and/or edit.
```

## Alter / Extend CWT

There a different ways to alter or extend CWT. They usually consist in providing your own bash files in `CWT_CUSTOM_DIR` following the conventions listed below.

It relies on [a minimalist "autoload" pattern](https://paulmicha.github.io/common-web-tools/about/patterns.html) (see **caveats** and **ways to mitigate** in documentation).

Notable alteration/extension entry points :

- `cwt/bash_utils.sh`
- `cwt/stack/init.sh`

### Complements

Given any bash include (sourced script include), the **complement** pattern simply attempts to include another corresponding file. The correspondance matches the relative path from `$PROJECT_DOCROOT/cwt` in `$CWT_CUSTOM_DIR` : if the complementary file exists, it is included (sourced) right where `u_autoload_get_complement()` is called.

Simple example from `cwt/bash_utils.sh` :

```sh
for file in $(find cwt/utilities/* -type f -print0 | xargs -0); do
  . "$file"
  u_autoload_get_complement "$file"
done
```

### Hooks

TODO

### Overrides

Same as the **complement** pattern, but this only includes the corresponding file :

Given any bash include (sourced script include), the **override** pattern attempts to include another corresponding file. The correspondance matches the relative path from `$PROJECT_DOCROOT/cwt` in `$CWT_CUSTOM_DIR` : if the overriding file exists, it is included (sourced) instead.

Example in `cwt/git/apply_config.sh` :

```sh
# When called in current shell scope, this will prevent the rest of the script
# to run - return early - if an override for the current file (calling this) was
# found and sourced.
eval $(u_autoload_override "$BASH_SOURCE")
```

Example in `u_hook()` :

```sh
for hook_script in "${lookup_paths[@]}"; do
  if [[ -f "$hook_script" ]]; then
    eval $(u_autoload_override "$hook_script" 'continue')
    . "$hook_script"
  fi
  u_autoload_get_complement "$hook_script"
done
```

### Presets

TODO

## Frequent tasks (howtos / FAQ)

Unless otherwise stated, all the examples below are to be run on *local* host from `PROJECT_DOCROOT` as sudo or root (i.e. for host provisioning support).

**NB** : Currently, no exit codes are used in any top-level entry points listed below. These includes (and all those sourced in the "main shell") use `return` instead of `exit`. CWT attempts to follow [Google's Shell Style Guide](https://google.github.io/styleguide/shell.xml) where possible.

Regarding ways to alter existing scripts, [the pattern "Autoload"](https://paulmicha.github.io/common-web-tools/about/patterns.html) usually means :

- Wrap customizations in functions or subshells
- Use `return` when working in the main shell scope - i.e. in your custom scripts autoloaded from `cwt/custom/overrides` and `cwt/custom/complements`

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
