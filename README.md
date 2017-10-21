# Common Web Tools (CWT)

## WHAT

Scripts bash for usual devops tasks aimed at relatively small web projects.

## PURPOSE

- setup app dependencies (with variants per env. type: dev, test, live)
- instanciate different environments locally and/or remotely
- implement deployment / remote 2-way sync

## HOW

Abstracting differences to streamline recurrent devops needs. There already are free existing tools addressing some tasks, such as :

1. Ansible roles (e.g. GeerlingGuy/DrupalVM)
1. docker-compose (e.g. wodby/docker4drupal)
1. Ansistrano, Portainer, Swarm, Helm, draft.sh, Dokku, Jenkins, Drone, Rancher, Mesos...

The approach here is to provide a minimal base for abstracting out usual tasks (maintain a common set of commands with varying implementations), while allowing to complement, combine, replace or add specific operations **with or without** existing tools.

## WHY

Over the years, the maintenance of older projects became tedious (typically LAMP stack based projects). For instance, when old VMs are deleted, it can be difficult to recreate a compatible local dev environment supporting all dependencies from that project "technological era".

While tools like Ansible, `docker-compose` or `nvm` already address these concerns, adapting or integrating such projects to use these tools for common tasks requires some amount of work (or "glue").

That's where this collection might help, e.g. by copy/pasting it in existing monolithic - or separate "local dev stack" - repos.

## Preprequisites

Local & remote hosts or VMs with bash support. CWT is tested on Debian and/or Ubuntu Linux hosts.

## Usage

There are 2 ways to use CWT in existing or new projects :

1. Use a single, "monolothic" repo for everything
1. Keep application code in a separate Git repo (default, see `.gitignore`)

### Option 1 first steps

- Download & copy/paste CWT files into project
- Undo default ignored subfolders in `.gitignore` file if/as needed

### Option 2 first steps

- Clone or download CWT in desired location (aka the project root dir)
- Clone the application into a subfolder named e.g. `web`, `public`, `build`, etc.
- Gitignore that subfolder by updating the `.gitignore` file accordingly
- [optional] Make any alterations necessary
- [optional] Maintain as a separate "dev stack" repo

### Next steps

When CWT files are in place :

- Initialize "stack" (environment settings & remote instance)
- Provision local and/or remote host
- Setup application (local and/or remote) instance
- [optional] Implement automated tests
- [optional] Implement deployment to desired remote instance(s)

See section *Frequent tasks (howtos / FAQ)* for details.

## Architecture

```txt
/path/to/project/
  ├── cwt/
  │   ├── app/                  <- App-related scripts + [wip] samples - local setup + tests.
  │   ├── db/                   <- Database-related scripts.
  │   ├── env/
  │   │   ├── current/          <- Generated values specific to current, local instance.
  │   │   └── dist/             <- Files used as "models" for env. vars during init.
  │   ├── git/
  │   │   └── hooks/
  │   ├── provision/            <- Host-level app dependencies setup scripts + [wip] samples.
  │   │   ├── ansible/
  │   │   ├── docker-compose/
  │   │   └── scripts/
  │   ├── remote/
  │   │   └── deploy/           <- Deployment-related scripts + [wip] samples.
  │   ├── specific/             <- [optional] Custom CWT scripts overrides.
  │   └── stack/                <- Scripts to (re)launch containers, watch / (re)build / CI tasks, workers, etc.
  ├── dumps/
  └── private/
```

## Frequent tasks (howtos / FAQ)

TODO
