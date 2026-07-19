# CWT core concept : Extensions

CWT data types :

- globals (readonly or mutable, may be secret + TODO encrypted ?)
- sidecars in data/* dirs (ex: logs)
- other yml (ex: remote instances or any entity)
- encrypted (git) versionned files (cf. `data/crypted`)

CWT extension points :

- ./cwt
- ./cwt/extensions/$extension
- ./scripts/cwt/contrib/$extension
- ./scripts/cwt/extend

CWT Generic -> Specific scale of actions (entry points) :

1. cwt/$subject/$action
1. cwt/extensions/$extension/$subject/$action
1. scripts/cwt/contrib/$extension/$subject/$action
1. scripts/cwt/extend/$subject/$action
