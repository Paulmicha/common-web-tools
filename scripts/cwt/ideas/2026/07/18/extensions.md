# CWT core concept : Extensions

TODO important note : any nested extension MUST have their hook implementations to have exact same specificity (weight) as their non-nested extension point closest to project docroot.

Example :

Implementing some `u_hook_most_specific()` contract in a submodule (child extension) :

`cwt/extensions/entity/field`

Must have the exact same specificity as if it was implemented in :

`cwt/extensions/entity`

## CWT data types

- globals (readonly or mutable, may be secret + TODO encrypted ?)
- sidecars in data/* dirs (ex: logs)
- other yml (ex: remote instances or any entity)
- encrypted (git) versionned files (cf. `data/crypted`)

## CWT extension points

- ./cwt
- ./cwt/extensions/$extension
- ./cwt/extensions/$extension/**/$nested_extension (via .cwt_subjects_ignore)
- ./scripts/cwt/contrib/$extension
- ./scripts/cwt/contrib/$extension/**/$nested_extension (via .cwt_subjects_ignore)
- ./scripts/cwt/extend
- ./scripts/cwt/extend/**/$nested_extension (via .cwt_subjects_ignore)

## CWT Generic -> Specific scale of actions (entry points)

Goal :
The bottom of this list wins when implementing the same `u_hook_most_specific()` :

1. cwt/$subject/$action
1. cwt/extensions/$extension/$subject/$action
1. cwt/extensions/$extension//**/$nested_extension (via .cwt_subjects_ignore)
1. scripts/cwt/contrib/$extension/$subject/$action
1. scripts/cwt/contrib/$extension/**/$nested_extension (via .cwt_subjects_ignore)
1. scripts/cwt/extend/$subject/$action
1. scripts/cwt/extend/**/$nested_extension (via .cwt_subjects_ignore)
