# Current environment files

The files contained in this directory are automatically generated during "instance init" and git-ignored. They should not be edited manually.

- `cwt/env/current/global.vars.sh` declares global values specific to the current local instance
- `cwt/env/current/default.mk` provides generic `make` "convenience" aliases corresponding to CWT primitives (actions by subject)

Extensions may also use this folder to store instance-specific generated code.

See `u_instance_init()` in `cwt/instance/instance.inc.sh` for more details about the "instance init" process.
