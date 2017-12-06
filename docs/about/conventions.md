# Conventions

See [flexibility (adaptability through variation)](flexibility-adaptability-variation.html) for mecanisms and use cases - this documentation exemplifies syntax.

## Naming things

In the "*Folders & files naming*" section, a principle is mentionned : **file structure** should indicate `subject` + `intent`.

This is informal (not to follow strictly, see *Flexibility and recursion* section), though CWT does use an extensible whitelisting mecanism to produce tree-like naming possibilities sometimes called "hooks".

```sh
# From cwt/env/vars.sh :
global CWT_SUBJECTS 'app env git provision remote stack service task worker logger cwt'
global CWT_ACTIONS 'bootstrap init load reload unload install reinstall uninstall build rebuild start restart stop add remove process trigger watch compile test plan delay deploy destroy'
global CWT_VARIANTS 'pre post'
```

Given these arbitrary global variables (and values) - `CWT_SUBJECTS`, `CWT_ACTIONS` and `CWT_VARIANTS` (all space-separated strings) - we can attempt some formalism in the method of determining "possibilities". For instance :

1. Pick any combination of CWT_SUBJECTS, CWT_ACTIONS and/or CWT_VARIANTS.
1. Pick a differenciation syntax using **prefix/suffix** and/or **delimiters** like : `(space) -_,;:|=!?#&/*+.--` and/or **enclosures** such as : `____()[]{}""''` and/or **placeholders** like : `__replace_this_MY_VARNAME_value__`
1. Pick a [generative mecanism](flexibility-adaptability-variation.html)

## Logical operators

Given CWT's minimalist ambition, it's delicate to mention yet another complexifying possibility.

TODO (missing documentation) evaluate relevance of pointing towards syntactic representations of condition, exclusion, alternative, union, ambivalence, equality, inversion (positive/negative)...

## Bash syntax

- Folder paths in variables : NEVER append trailing slash
- Bash script files using `*.sh` extension are meant to be `source`d (not executed directly)
- Bash script files using a **multiple extension pattern** - e.g. `*.deps.sh`, `*.vars.sh`, `*.hook.sh` will ALWAYS be dynamically sourced.
- Bash script files named *without extension* are meant to be executed (not `source`d directly)
- Sourcing : prefer the shorter notation - single dot, ex: `. cwt/aliases.sh`
- TODO document relativity (wrapping, isolation) in [flexibility (adaptability through variation)](flexibility-adaptability-variation.html) UPPERCASE / lowercase differenciates global variables from `local` variables (only used in function scopes)
- Parameters : variables storing values coming from arguments are prefixed with `P_` or `p_` (for *parameter*), ex: `$P_PROJECT_STACK`. See `cwt/stack/init.sh`
- Function names for utilities in `cwt/utilities` are all prefixed by `u_` (for *utility*), ex: `u_autoload_override`
- Separator for a single name having multiple words : use underscores `_` in variables, functions, and script/include names. Use dashes `-` in folder names.
- Semver suffixes start with `-` (e.g. in stack names), and are used to generate lookup paths for includes.
