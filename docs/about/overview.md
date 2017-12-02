# Overview

This page presents the CWT project.

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

Abstracting differences to streamline recurrent devops needs. There already are free existing tools addressing some tasks, such as :

- Ansible roles (e.g. GeerlingGuy/DrupalVM)
- docker-compose (e.g. wodby/docker4drupal)
- Ansistrano, Portainer, Swarm, Helm, draft.sh, Dokku, Jenkins, Drone, Rancher, Mesos...

The approach here is to provide a minimal base for abstracting usual tasks while allowing to complement, combine, replace or add specific operations **with or without** existing tools.

## WHY

To be more productive. To [standardize](https://imgs.xkcd.com/comics/standards.png) the use of common solutions for targeted use cases - see *purpose*.

Over the years, the maintenance of older projects can become tedious. For instance, when old VMs are deleted, it can be difficult to recreate a compatible local dev environment supporting all dependencies from that project "technological era".

While tools like Ansible, `docker-compose` or `nvm` already address these concerns, adapting or integrating such projects to use these tools for common tasks requires some amount of work (or "glue").

## File structure (and status)

CWT is under construction. Folders might still move around depending on its use, until I feel it can start proper versionning. Consider this repo a scratchpad for now.

CWT essentially relies on a relative global namepace. Its creation process involves building it "on the fly" in other side projects in which each step listed above (*Next steps*) is achieved by specific, custom scripts placed in a different `scripts` dir alongside `cwt` in `PROJECT_DOCROOT`. In such cases, `CWT_CUSTOM_DIR` is also set to `$PROJECT_DOCROOT/scripts` (See the *Alter / Extend CWT* section).

Ultimately, it should not compete with other projects (and I couldn't find a better word than "glue" for now, sorry).

This section illustrates a minimalist approach to organizational problems. It's still under study. Long-term considerations involve code generators, IEML, and the relationship between philosophy and programming ("naming things", "no language exists in isolation"). Short-term : makefile integration ?

The file structure follows [loose naming and folder structure conventions](https://paulmicha.github.io/common-web-tools/about/patterns.html). Typically facts, actions, subjects are used to categorize fragments of bash scripts meant to be sourced directly inside custom scripts (not included in the CWT project).

```txt
/path/to/project/           <- Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              <- [WIP] App init / (re)build / watch fragments.
  │   ├── custom/           <- [configurable] default "modules" dir (alter or extend CWT. $CWT_CUSTOM_DIR)
  │   ├── db/               <- [WIP] Database-related fragments.
  │   ├── env/              <- Environment settings fragments (global variables).
  │   │   └── current/      <- Generated settings specific to local instance (git-ignored).
  │   ├── git/              <- Versionning-related fragments.
  │   │   └── hooks/        <- [WIP] Entry points for auto-exec (tests, code linting, etc.)
  │   ├── provision/        <- [WIP] Host-level dependencies related fragments (softwares setup).
  │   ├── remote/           <- [TODO] Remote operations fragments (add, provision, etc.)
  │   │   └── deploy/       <- [TODO] Deployment-related fragments.
  │   ├── stack/            <- [WIP] Services and/or workers management fragments.
  │   ├── test/             <- [TODO] Automated tests related fragments.
  │   │   └── self/         <- [TODO] CWT internal tests.
  │   └── utilities/        <- CWT internal functions (hides complexity).
  ├── dumps/                <- [configurable] Database dump files (git-ignored).
  ├── web/                  <- [configurable] The app dir - can be outside project dir ($APP_DOCROOT).
  └── .gitignore            <- Replace with your own and/or edit.
```
