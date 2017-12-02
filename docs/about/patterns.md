# Patterns

Briefly explains basic architectural aspects of CWT.

## Systematic sourcing from project root dir

- **Purpose**:
    - Simplicity for including (subshell exec or source) any file from anywhere - always use the same relative reference path everywhere
    - Sharing the same top-level [*current shell*](http://wiki.bash-hackers.org/scripting/processtree), or "main shell"
- **Caveat**: global scope abuse is an anti-pattern: potential variables collision, etc.
- **How to mitigate**:
    - KISS radically
    - [Make globals immutable (`readonly`) and use them sparingly](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)
    - Use functions with `local` vars for isolable parts
    - Follow variable and function naming conventions, see section *conventions used in code* below

## "Autoload" (dynamic sourcing)

Notably used in:

- `cwt/bash_utils.sh`
- `cwt/stack/init.sh`
- `cwt/utilities/hook.sh`

- **Purpose**:
    - Leaziness (not really dependency management)
    - Convention over configuration
- **Caveats**:
    - relies on global antipattern (See *Systematic sourcing from project root dir*)
    - wasteful performance-wise
    - no accidental infinite recursion prevention
- **How to mitigate**:
    - Provide [CWT self tests](https://github.com/sstephenson/bats) in `cwt/test/self`

This pattern might be used to integrate some [existing (and more elaborate) Bash projects](https://github.com/awesome-lists/awesome-bash).

## Folders & files naming

The general principle is : *file structure* should indicate intent. CWT's organization follows task (action), subject and/or facts, and the [semver convention](https://semver.org/).

The order or imbrication is still under study, but given CWT's minimalist ambition, it probably will remain just a principle.

As this is not really a pattern and more a basic guideline to name folders, scripts or functions, it may help deciding how to split or group operations and inform folder structure choices.

- **Purpose**:
    - Less hesitation
    - Self-explanation
- **Caveat**: Identic file names in different folders, see [this article about JS component-oriented file structure](https://hackernoon.com/the-100-correct-way-to-structure-a-react-app-or-why-theres-no-such-thing-3ede534ef1ed)
