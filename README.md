# Common Web Tools (CWT)

WIP / not ready yet (experimental).

## WHAT

Scaffolding bash shell CLI for usual web project tasks. Customizable, extensible toolbox for local (internal) development tasks.

CWT is not a program; it's a generic, customizable "glue" between programs. [Third-party tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) integration is provided by extensions having their own separate Git repository. CWT includes by default (for now) a predefined list of extensions - like in the [DrupalVM](https://www.drupalvm.com/) project.

CWT "core" - this repo - contains common utilities related to managing global environment variables, local and remote hosts, project instance self-tests, and the building blocks of the conventions facilitating the implementation of recurrent web project tasks (see *HOW* below).

Important note : CWT is *not* a production hosting tool.

## PURPOSE

CWT helps individual developers or teams to streamline a similar workflow across older and newer projects. It allows to **maintain a common CLI** while easily swapping out [implementations](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) (i.e. "not marrying them").

CWT core provides some generic bash shell functions and scripts. It can generate a `Makefile` for chosen tasks. Most importantly, it organizes scripts around a set of conventions to implement in a **modular** way e.g. :

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

Provide some abstractions to complement, combine, replace or add specific operations.

CWT heavily relies on **file structure**, **naming conventions**, and a few concepts :

- **Globals** are the environment variables related to current project instance. They may be declared using the `global` function in files named `env.vars.sh` aggregated during initialization.
- **Bootstrap** is the entry point of any task's execution. It deals with the inclusion of all the relevant scripts and loads global variables (e.g. host type, instance type, etc).
- **Primitives** are fundamental values for CWT extension mecanisms. These are **subjects**, **actions**, and **extensions**.
- **Hooks** are function calls mimicking events (optionally filtered by primitives), where "listening" entails creating some specific file(s) in certain path(s) corresponding to its arguments.

## File structure

```txt
/path/to/project.instance/  ← Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              ← App-level tasks (e.g. fix permissions, watch, compile, etc.)
  │   ├── env/              ← Default global env. vars
  │   │   └── current/      ← [git-ignored] Generated global env. vars / Makefiles
  │   ├── extensions/       ← Contains CWT extensions. Remove or add according to project needs
  │   ├── git/              ← Versionning-related tasks
  │   │   └── hooks/        ← Entry points for auto-exec (tests, etc.)
  │   ├── host/             ← Host-level metadata / crontab / network utils + "abstract" provision action
  │   ├── instance/         ← Actions related to the entire project instance (init, destroy, start, stop)
  │   ├── test/             ← Self-test entry point / automated tests actions
  │   │   └── cwt/          ← CWT 'core' internal tests (uses shunit2 - see 'vendor' dir)
  │   ├── utilities/        ← CWT internal functions (hides complexity)
  │   └── vendor/           ← Bundled third-party dependencies (only shunit2 by default)
  ├── scripts/              ← [configurable] default path to current project's scripts ($PROJECT_SCRIPTS)
  ├── web/                  ← [configurable] The app dir. Can be outside project dir ($APP_DOCROOT)
  └── .gitignore            ← Replace with your own and/or edit
```

## WHY

To facilitate tools testing / throwing away what doesn't work *with minimal impact to other parts of the project*. To be more productive.

"*[...] There are core parts of the technology that deliver most of the value / differentiator, and these are important to get right. There’s usually then a bunch of other software and services which is more like scaffolding; **you have it around in order to get stuff done**.*
*[...] “Mash-up” shouldn’t be a dirty hackfest concept.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

See also RDX's article (2016/07/20) : [Modern Software Over-Engineering Mistakes](https://medium.com/@rdsubhas/10-modern-software-engineering-mistakes-bc67fbef4fc8).

## High-level Goals

CWT only cares about testing and making [different tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) work together as painlessly as possible. The success (or failure) of this tool would be measured in **cognitive ressource** - i.e. how quickly / cheaply can I try other tools together to see if they fit my needs ?

Regading how best to achieve this "economical" objective, my current intuition is to apply focus on [meaning](https://pierrelevyblog.com/2017/12/08/what-is-meaning/) and communication (i.e. naming things as transparently as possible, information design, terse documentation and code comments, etc).

Among secondary goals are :

- [modularity](https://www.youtube.com/watch?v=vypCsVm5z28) - to **hide complexity** by fragmentation (*"people got mad when I put it all in one file"*). "*[Start] with a list of difficult design decisions or design decisions that are likely to change. Each module is then designed to hide such a decision from the others*" -- David Parnas, *on the criteria to be used in decomposing systems into modules* (1971)
- Code generation (WIP)

## Targeted audience

Developers with or without much knowledge on using a terminal (CLI) working under Linux, MacOS, or Windows (using [Git Bash](https://git-for-windows.github.io/) or [Windows Subsystem for Linux ("bash on Ubuntu on Windows")](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)).

## Why bash

If CWT targets the same portability as Python (~ since [2011](https://unix.stackexchange.com/a/24808)), why not just use that language instead ?

That choice has more to do with personal interest, self-teaching, and minimalism (though one could perfectly implement a minimalist scaffolding tool in either language).

## Preprequisites

- Local host or VM with **Bash shell version 4+** (e.g. MacOS : `brew update && brew install bash && sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' && chsh -s /usr/local/bin/bash`)
- Git
- Existing project (new or old)
- [optional] Remote host accessible via SSH with Bash 4+
- [optional] *GNU make* in local / remote host(s)

Disclaimer : CWT is currently only tested on Debian and/or Ubuntu Linux hosts.

## Usage / Getting started

There are 2 ways to use CWT in existing or new projects :

1. Use a single, "monolothic" repo for the whole project
1. Keep application code in a separate Git repo (this is the default assumption in the `.gitignore` config featured in this repo)

The files contained in CWT core - this repo - may be placed either inside the application code (in this case `APP_DOCROOT` = `PROJECT_DOCROOT`), inside its parent folder (this is the default assumption and usually has its own separate "dev stack" Git repo), or even anywhere else on the host (see `APP_DOCROOT`, `PROJECT_SCRIPTS` and `APP_GIT_WORK_TREE` global env vars).

So the first step will always be to clone or download / copy / paste the files from this repo to desired location (in relation to your choice for this project instance source files organization described above), then :

1. Review the `.gitignore` file and adapt it to suit your needs.
1. Launch *instance init* action (e.g. run `make` or `make instance init`) - this will generate `readonly` global env vars and optional Makefiles. See `cwt/instance/instance.inc.sh` and `cwt/utilities/global.sh` for details.
1. [optional] launch *host provision* action (e.g. run `make host provision`) - this is not implemented in CWT, but this "entry point" exists to streamline host-level software installation in extensions.
1. [optional] launch *instance start* action (e.g. run `make instance start`) - this is meant to run any service required to use or work on current project instance.

See *Frequent tasks (howtos / FAQ)* below for other tasks and details.

## Alter / Extend CWT

Altering or extending CWT involves either :

- creating bash shell scripts in the `scripts` dir (this path may be overridden using the `PROJECT_SCRIPTS` global)
- creating your own extension(s) in `cwt/extensions` (1 folder = 1 extension)

Here are the different ways to adapt CWT to current project needs :

### Global (env) variables

Since every entry point sources `cwt/bootstrap.sh` to load CWT functions and globals, these (`readonly`) variables are available everywhere. Their values are assigned during *instance init* which generates a single, git-ignored script : `cwt/env/current/global.vars.sh`.

One of the most straightforward ways to customize or add globals is by providing your own `global.vars.sh` file in current project instance's `scripts` folder, however any extension can provide its own - be it in the folder of the extension directly, or inside any of its subfolder (called *subjects*).

CWT core provides 13 globals by default (see `cwt/env/global.vars.sh`, and `cwt/utilities/global.sh` for details about the `global()` function) :

```sh
global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"
global INSTANCE_TYPE "[default]=dev"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)'"
global HOST_TYPE "[default]=local"
global HOST_OS "$(u_host_os)"
global PROVISION_USING "[default]=docker-compose"

# Path to custom scripts ~ commonly automated processes. CWT will also use this
# path to look for overrides and complements.
# @see u_autoload_override()
# @see u_autoload_get_complement()
global PROJECT_SCRIPTS "[default]=scripts"

# This allows supporting multi-repo projects, i.e. 1 repo for the app + 1 for
# the "dev stack" :
# - Use CWT_MODE='monolithic' for single-repo projects.
# - Use CWT_MODE='separate' for multi-repo projects (mandatory app Git details).
# TODO support any other combination of any number of repos ?
global CWT_MODE "[default]=separate"
global APP_GIT_ORIGIN "[if-CWT_MODE]=separate"
global APP_GIT_WORK_TREE "[if-CWT_MODE]=separate [default]=$APP_DOCROOT"

# [optional] Allows extensions to provide their own makefile includes (after
# instance init). This global must contain a list of paths relative to
# $PROJECT_DOCROOT separated by space.
# @see https://www.gnu.org/software/make/manual/html_node/Include.html
# @see cwt/env/current/README.md
# @see Makefile
global CWT_MAKE_INC
```

### Hooks & Primitives

TODO

### Extensions

Any folder present in the `cwt/extensions` dir is considered a CWT extension. Their structure follows that of the `cwt` dir (see *Hooks & Primitives*). The only particularity is the ability to declare dependencies (i.e. other extensions required to use the current one) by providing a dotfile named `.cwt_requires` at the root of the extension dir.

Example contents from `cwt/extensions/docker4drupal/.cwt_requires` :

```sh
docker-compose:https://github.com/Paulmicha/cwt.docker-compose.git
mysql:https://github.com/Paulmicha/cwt.mysql.git
```

### Overrides and Complements

These mecanisms consist respectively in loading an additional script or replacing it by another corresponding script. The correspondance matches the relative path from `$PROJECT_DOCROOT/cwt` in `$PROJECT_SCRIPTS` : if the complementary file exists, it is included (sourced) - either instead of the original include, or simply as an extra.

Example use case from `cwt/bootstrap.sh` :

```sh
for file in $CWT_INC; do
  # Any additional include may be overridden.
  u_autoload_override "$file" 'continue'
  eval "$inc_override_evaled_code"

  . "$file"

  # Any additional include may be altered using the 'complement' pattern.
  u_autoload_get_complement "$file"
done
```

## Frequent tasks (howtos / FAQ)

TODO
