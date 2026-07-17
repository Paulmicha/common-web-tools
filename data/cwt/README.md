# Git-ignored local environment files

The files contained in this directory are automatically generated and git-ignored. They should not be edited manually.

CWT generates by default the following files during **instance init**:

- `global.vars.sh` — readonly global values for the current local instance (sourced on every bootstrap)
- `generated.mk` — make shortcuts for discovered subject/action entry points (and per-case test targets)
- `cache/` — primitives cache (`cwt.sh`), hook caches, test-case registry, etc.

Extensions may also use this folder for instance-specific generated code (e.g. registry files under `registry/`).

See `u_instance_init()` in `cwt/instance/instance.inc.sh` and [docs/cwt/globals.md](../../docs/cwt/globals.md).
