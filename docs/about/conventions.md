# Conventions used in code

- Sourcing : prefer the shorter notation - single dot, ex: `. cwt/aliases.sh`
- UPPERCASE / lowercase differenciates global variables from `local` variables (only used in function scopes)
- Parameters : variables storing values coming from arguments are prefixed with `P_` or `p_` (for *parameter*), ex: `$P_PROJECT_STACK`. See `cwt/stack/init.sh`
- Function names for utilities in `cwt/utilities` are all prefixed by `u_` (for *utility*), ex: `u_autoload_override`
- Separator for a single name having multiple words : use underscores `_` in variables, functions, and script/include names. Use dashes `-` in folder names.
- Dashes `-` in stack names are used to dynamically match env settings "dist" files (includes) - 1 dash = 1 dir level, ex: stack name `my_stack_name-3` would trigger lookups in `cwt/env/dist/my-stack-name/app.vars.sh.dist`, `cwt/env/dist/my-stack-name/3/app.vars.sh.dist`, etc. See `cwt/env/README.md`.

TODO double file extension pattern
