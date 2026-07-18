# CWT subject : nested

- nested-cwt : deals with child CWT project instances (any host-related things must automatically climb up the chain to avoid duplicating crontabs, logs, etc)
- nested-git : deals with child git clones / work trees
- nested-extension = sub-modules = sub-folder(s) in any CWT extension place via .cwt_subjects_ignore
- nested-blueprint ? (see builder + possibility of sub-modules)
