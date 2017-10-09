# Specific scripts

These scripts are meant to override and/or customize common scripts. The purpose is to allow copying common scripts into other projects's monolithic repository while maintaining their specific implementations and/or overrides separate, in this folder.

## Conventions

Some scripts may anticipate potential overrides by testing if their specific counterpart exists in this dir. Example : `scripts/env/registry.sh`.
