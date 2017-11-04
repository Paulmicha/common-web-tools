# Common Web Tools (CWT) documentation - Overview

This page presents the CWT project.

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

## File structure

```txt
/path/to/project/               <- Project root dir.
  ├── cwt/
  │   ├── app/                  <- App setup / watch / (re)build scripts + [wip] samples.
  │   ├── custom/
  │   │   ├── complements/      <- [optional] Add your custom script complements here (see "Autoload").
  │   │   └── overrides/        <- [optional] Add your custom script overrides here (see "Autoload").
  │   ├── db/                   <- Database-related scripts.
  │   ├── env/
  │   │   ├── current/          <- Generated values specific to current, local instance.
  │   │   └── dist/             <- Files used as "models" for env. vars during init.
  │   ├── git/
  │   │   └── hooks/
  │   ├── provision/            <- Host-level dependencies setup scripts + [wip] samples.
  │   │   ├── ansible/
  │   │   ├── docker-compose/
  │   │   └── scripts/
  │   ├── remote/
  │   │   └── deploy/           <- Deployment-related scripts + [wip] samples.
  │   ├── stack/                <- Manage required services and/or containers, CI tasks, workers + [wip] samples.
  │   └── test/                 <- Automated tests related scripts + [wip] samples.
  │       ├── behat/
  │       └── gemini/
  ├── dumps/
  ├── web/                      <- Public web application dir. May use other names like docroot, www, public...
  └── .gitignore                <- Replace with your own and/or edit.
```

---

Back to [documentation index](index.md)
