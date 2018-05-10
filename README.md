# Common Web Tools (CWT)

WIP / not ready for use yet (re-organization + evaluation stage).

TODO rewrite **Documentation** : [paulmicha.github.io/common-web-tools](https://paulmicha.github.io/common-web-tools/)

## WHAT

Scaffolding bash shell CLI for usual web project tasks.

CWT is not a program; it's a generic, customizable "glue" between programs. [Third-party tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) integration is provided by extensions having their own separate Git repository. TODO include by default a predefined list of extensions - like in the [DrupalVM](https://www.drupalvm.com/) project ?

CWT "core" - this repo - contains common utilities related to managing global environment variables, local and remote hosts, project instance self-tests, and the building blocks of the conventions facilitating the implementation of recurrent web project tasks (see *HOW* below).

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

## WHY

To facilitate tools testing / throwing away what doesn't work *with minimal impact to other parts of the project*. To be more productive.

"*[...] There are core parts of the technology that deliver most of the value / differentiator, and these are important to get right. There’s usually then a bunch of other software and services which is more like scaffolding; **you have it around in order to get stuff done**.*
*[...] “Mash-up” shouldn’t be a dirty hackfest concept.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

See also RDX's article (2016/07/20) : [Modern Software Over-Engineering Mistakes](https://medium.com/@rdsubhas/10-modern-software-engineering-mistakes-bc67fbef4fc8).

## Targeted audience

Developers with or without much knowledge on using a terminal (CLI) working under Linux, MacOS, or Windows (using [Git Bash](https://git-for-windows.github.io/) or [Windows Subsystem for Linux ("bash on Ubuntu on Windows")](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)).

## Why bash

If CWT targets the same portability as Python (~ since [2011](https://unix.stackexchange.com/a/24808)), why not just use that language instead ?

That choice has more to do with personal interest, self-teaching, and minimalism (though one could perfectly implement a minimalist scaffolding tool in either language).

## High-level Goals

CWT only cares about testing and making [different tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) work together as painlessly as possible. The success (or failure) of this tool would be measured in **cognitive ressource** - i.e. how quickly / cheaply can I try other tools together to see if they fit my needs ?

Regading how best to achieve this "economical" objective, my current intuition is to apply focus on [meaning](https://pierrelevyblog.com/2017/12/08/what-is-meaning/) and communication (i.e. naming things as transparently as possible, information design, terse documentation and code comments, etc).

Among secondary goals are :

- [modularity](https://www.youtube.com/watch?v=vypCsVm5z28) - to **hide complexity** by fragmentation (*"people got mad when I put it all in one file"*). "*[Start] with a list of difficult design decisions or design decisions that are likely to change. Each module is then designed to hide such a decision from the others*" -- David Parnas, *on the criteria to be used in decomposing systems into modules* (1971)
- Code generation (WIP)

## Preprequisites

- Local host or VM with **Bash shell version 4+** (e.g. MacOS : `brew update && brew install bash && sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' && chsh -s /usr/local/bin/bash`)
- Git
- Existing project (new or old)
- [optional] Remote host accessible via SSH with Bash 4+
- [optional] *GNU make* in local / remote host(s)

CWT is currently only tested on Debian and/or Ubuntu Linux hosts.

## Usage

There are 2 ways to use CWT in existing or new projects :

1. Use a single, "monolothic" repo for everything
1. Keep application code in a separate Git repo (default, see `.gitignore`)

### Option 1 first steps ("monolothic" repo)

- Download and/or copy&paste CWT files into project root dir (existing or new Git repo)
- Undo default ignored subfolders in `.gitignore` file if/as needed

### Option 2 first steps (separate Git repo)

- Download CWT in desired location (aka the project root dir `$PROJECT_DOCROOT`)
- Clone the application into a subfolder named e.g. `web`, `public`, etc. (`$APP_DOCROOT`)
- Gitignore that subfolder by updating the `.gitignore` file accordingly
- [optional] Make any alterations necessary
- [optional] Maintain as a separate repo

### Next steps

When CWT files are in place alongside the rest of the project :

- Init local instance
- Install host-level software (local and/or remote provisioning)
- Install app instance(s) (local and/or remote)
- [optional] Implement automated tests
- [optional] Implement deployment to desired remote instance(s)

See section *Frequent tasks (howtos / FAQ)* for details.

## CWT 'core' file structure

```txt
/path/to/project/           ← Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              ← App init / (re)build / watch.
  │   ├── env/              ← Environment settings (global variables) actions (e.g. (re)write).
  │   │   └── current/      ← Generated settings specific to local instance (git-ignored).
  │   ├── extensions/       ← Contains CWT extensions. Remove or add according to project needs.
  │   ├── git/              ← Versionning-related includes.
  │   │   └── hooks/        ← Entry points for auto-exec (tests, code linting, etc.)
  │   ├── host/             ← Host-level metadata / crontab / network helpers.
  │   ├── instance/         ← Actions related to the entire project instance (init, destroy, start, stop)
  │   ├── remote/           ← Remote operations (e.g. instance tasks, but can be any action)
  │   │   └── instances/    ← Generated settings for each remote instance (git-ignored).
  │   ├── test/             ← Automated tests and actions.
  │   │   └── cwt/          ← CWT 'core' internal tests (uses shunit2 - see 'vendor' dir).
  │   ├── utilities/        ← CWT internal functions (hides complexity).
  │   └── vendor/           ← Bundled third-party dependencies.
  ├── scripts/              ← [configurable] default path to current project's scripts ($PROJECT_SCRIPTS).
  ├── web/                  ← [configurable] The app dir. Can be outside project dir ($APP_DOCROOT).
  └── .gitignore            ← Replace with your own and/or edit.
```

## Alter / Extend CWT

Altering or extending CWT happens in the `scripts` dir by default, but this path may be overridden using the `PROJECT_SCRIPTS` global. Here are the different ways to adapt CWT to current project needs :

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
