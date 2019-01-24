# Git-ignored local environment files

The files contained in this directoryautomatically generated and git-ignored. They should not be edited manually.

CWT generates by default the following files during "**instance init**" :

- `global.vars.sh` declares global values specific to the current local instance
- `default.mk` provides generic `make` "convenience" aliases corresponding to CWT primitives (actions by subject)

Extensions may also use this folder to store current instance-specific generated code.

See `u_instance_init()` in `cwt/instance/instance.inc.sh` for more details.
