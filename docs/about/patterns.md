# Patterns

Briefly explains basic architectural aspects of CWT.

## Reference scope (systematic sourcing from project root dir)

- **Purpose**:
    - Simplicity for including (subshell exec or source) any file from anywhere - always use the same relative reference path everywhere
    - Sharing the same top-level [*current shell*](http://wiki.bash-hackers.org/scripting/processtree), or "main shell"
- **Caveat**: global scope abuse is an anti-pattern: potential variables collision, etc.
- **How to mitigate**:
    - Use functions with `local` vars for isolable parts
    - Follow variable and function naming [conventions](conventions.html).
    - KISS radically / strive for minimalism / limit modularity (only introduce when absolutely necessary)
    - [Make globals immutable (`readonly`) and use them sparingly](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)

## "Autoload" (dynamic includes)

- **Purpose**:
    - Leaziness (not really dependency management)
    - [Convention](conventions.html) over configuration
- **Caveats**:
    - relies on global antipattern (See *Systematic sourcing from project root dir*)
    - wasteful performance-wise
    - no accidental infinite recursion prevention
    - potentially excessive fragmentation / over-abstracting / over-engineering (YAGNI)
- **How to mitigate**:
    - [TODO] Provide [CWT self tests](https://github.com/sstephenson/bats) in `cwt/test/self`
    - Elements indicated in *Systematic sourcing from project root dir* apply here too

Notably used in:

- `cwt/bash_utils.sh`
- `cwt/stack/init.sh`
- `cwt/utilities/hook.sh`

This pattern should not prevent CWT to co-exist alongside [existing tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) and/or [Bash projects](https://github.com/awesome-lists/awesome-bash).

## Folders & files naming

- **Purpose**:
    - Less hesitation
    - Self-explanation
    - [flexibility (adaptability through variation)](flexibility-adaptability-variation.html)
- **Caveat**: Identic file names in different folders, see [this article about JS component-oriented file structure](https://hackernoon.com/the-100-correct-way-to-structure-a-react-app-or-why-theres-no-such-thing-3ede534ef1ed)
- **How to mitigate**: Not much, really... Brievety is favored over the downside mentioned above, because of the explicit reliance on (file) **tree**.

The general principle is : *file structure* should indicate `subject` + `intent`.

Folders are used to imbricate tasks by subject first, then action and/or fact(s) and/or preset(s) and/or [semver convention](https://semver.org/) are used to name files where appropriate. See [instance init](https://paulmicha.github.io/common-web-tools/usage/instance-init.html) and [alter / extend](https://paulmicha.github.io/common-web-tools/about/alter-extend.html).

Given CWT's minimalist ambition, dir/file naming could be just a principle not strictly followed.

Potential patterns could be :

- depth level : **deeper = more specific**
- folder tree + file naming : see [conventions](conventions.html)
