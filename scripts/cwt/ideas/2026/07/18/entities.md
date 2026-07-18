# CWT core concept : Entities

## General idea (the shape of contracts for defining entities)

TODO *.yml minimal structure to say "hello, this entity depends on :"
  - foobar.dependency.yml (pipx, git repo, generic source, deb package, appimage, apt-related ...)
  - foobar.cwt-extension.yml ?
  - foobar.hardware.yml ? version ? version.able ?
  - foobar.software.yml ? version ? version.able ?
  - foobar.state.yml

TODO cwt/extensions/entity/is/able.sh (entity contracts : cognition.able, etc)
TODO cwt/extensions/entity/is/event.sh (source : manual, agent, cronjob, interaction, timestamp...)
TODO cwt/extensions/entity/is/public.sh
TODO cwt/extensions/entity/is/private.sh
TODO cwt/extensions/entity/is/relation.sh (for fieldable relationships)
TODO cwt/extensions/entity/is/root.sh (synonyms : primordial, prime, original)
TODO cwt/extensions/entity/is/sibling.sh (synonyms : neighbor, sister, brother)
TODO cwt/extensions/entity/is/leaf.sh
TODO cwt/extensions/entity/has/label.sh (synonyms : title, name)
TODO cwt/extensions/entity/has/type.sh (synonyms : category)
TODO cwt/extensions/entity/has/bundle.sh (synonyms : subtype)
TODO cwt/extensions/entity/has/plan.sh
TODO cwt/extensions/entity/has/log.sh
TODO cwt/extensions/entity/has/changelog.sh
TODO cwt/extensions/entity/has/idea.sh
TODO cwt/extensions/entity/has/sidecar.sh
TODO cwt/extensions/entity/has/wrapper.sh
TODO cwt/extensions/entity/has/nested.sh (synonyms : children, child)
TODO cwt/extensions/entity/has/sibling.sh (synonyms : neighbor, sister, brother)
TODO cwt/extensions/entity/has/parent.sh (synonyms : genitor, mother, father)
TODO cwt/extensions/entity/has/ancestor.sh
TODO cwt/extensions/entity/has/descendants.sh
TODO cwt/extensions/entity/has/primitive.sh
TODO cwt/extensions/entity/has/primordial.sh
TODO cwt/extensions/entity/has/relation.sh (of type foobar, matching emitters / recievers, etc)
TODO cwt/extensions/entity/has/permission.sh
TODO cwt/extensions/entity/has/restriction.sh
TODO cwt/extensions/entity/has/field.sh
TODO cwt/extensions/entity/has/origin.sh
TODO cwt/extensions/entity/has/author.sh
TODO cwt/extensions/entity/has/license.sh
TODO cwt/extensions/entity/has/version.sh
TODO cwt/extensions/entity/has/state.sh (synonyms : status, health, vitals ?)
TODO cwt/extensions/entity/implements/hook.sh
TODO cwt/extensions/entity/uses/global.sh

## Dependencies

- CWT
- Core extension : entity

## Capabilities

TODO recap all *.able.yml known to date :

- "$wrap.able" (cwt log, host process, cwt thread, logged-thread = lt, etc)
- "$nest.able" (nested-git, nested-cwt, nested-host (vm ?), nested-cmd ?, nested-process ?, nested-thread ?, nested-protocol ? nested-crypt ? etc)
- "$action.able" (cwt entry points by subject - ex: rotate, recognize, protocol, cwt/extensions/entity/has/cognition.sh, etc)
- "$sidecar.able" (changelog, accesslog ?, timestamp (ms precision, last 5min...), datestamp (daily, monthly, yearly))

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
