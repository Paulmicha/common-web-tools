# Common web tools

## WHAT

Scripts bash for usual devops tasks aimed at relatively small web projects.

## PURPOSE

- setup server app dependencies (with variants per env. type: dev, test, live)
- instanciate different environments locally and/or remotely
- implement deployment / remote 2-way sync

## HOW

There already are many existing tools to do these tasks, such as :

1. Ansible (à la GeerlingGuy/DrupalVM) + Ansistrano
1. docker-compose, wodby/docker4drupal
1. Dokku, Rancher, Deis, Mesos...

The approach here is to provide a minimal base for abstracting out usual tasks (maintain a common set of commands with varying implementations), while allowing to complement, combine, replace or add specific operations **with or without** existing tools.

## WHY

Over the years, the maintenance of older projects became tedious (typically LAMP stack based projects). For instance, when old VMs are deleted, it can be difficult to recreate a compatible local dev environment supporting all dependencies from that project "era".

Even newer projects on other stacks may also break when re-instanciated elsewhere after some major changes in the NPM ecosystem (typically old node_modules without shrinkwrap, before the NPM lock mecanism).

While tools like Ansible, `docker-compose` or even `nvm` may help, reworking parts of small-ish projects from different eras to use these tools isn't always possible.

That's where this collection might help, e.g. by copy/pasting it in existing monolithic - or separate "local dev stack" - repos.

## Usage

TODO
