# CWT core extension : Entities

## General idea

TODO *.yml minimal structure
TODO cwt/extensions/entity/is/able.sh

## Dependencies

- TODO by subject

## Capabilities

TODO recap all *.able.yml known to date :

- "$wrappers.able" (log, thread, logged-thread, etc)
- "$nested.able" (nested-git, nested-cwt, nested-host (vm ?), nested-cmd ? etc)
- "$action.able" (cwt entry points by subject - ex: recognize, entity "$crud" actions, etc)

## Entities

- Primordial = most generic = empty object = the entity.entity.yml definition (mother of all entities)
- Inheriting is done like remote instances yml "includes"
- Inheriting from Parent(s) entities could be synonym of "genericity".

Scale of entities "genericity", descending order of most to least :

1. primordial = most abstract
1. primitive ancestor ?
1. ancestor = up to level n - 2
1. parent = level n - 1
1. self = level n
1. child = level n + 1
1. descendants = from level n + 2

## Subjects x Actions

- TODO entity types (type is a field)
- TODO taxonomy : patternify ?

## Hooks

- TODO
