# Overview

This page presents the CWT project.

## WHAT

"Scaffolding" CLI for usual development tasks aimed at relatively small web projects.

CWT is not a program; it's a generic, customizable "glue" between programs. Simple, loosely articulated bash scripts with a minimalist ambition.

## PURPOSE

TL;DR the *raison d'être* of - or *need* addressed by - CWT is to **maintain a standard CLI** while easily swapping out [implementations](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) (i.e. "not marrying them").

CWT provides a common set of commands to execute variable implementations of the following tasks :

- install host-level dependencies (provision required packets/apps/services - e.g. docker, node, etc) - locally and/or remotely
- instanciate project locally and/or remotely, with variants per env. type - dev, test, live... (e.g. get or generate services credentials, write local app settings, create database, build...)
- implement deployment and/or automated tests
- remote 2-way sync

CWT targets individual developers or relatively small teams attempting to streamline or implement a common workflow across older *and* newer projects (see *targeted audience* section below).

## HOW

Abstracting differences to streamline recurrent web development needs.

The approach here is to provide a minimal base for abstracting usual tasks while allowing to complement, combine, replace or add specific operations **with or without** [existing tools](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html).

## WHY

To be more productive. To easily test and quickly throw away what doesn't work. To [standardize](https://imgs.xkcd.com/comics/standards.png) the use of common solutions for targeted use cases - see *purpose*.

Productivity (and simplicity) are relative and complex topics, so it might as well come down to questions like :

- "does it look like I'll bother enough ?"
- "what's there to gain ?"

While tools like Ansible, `docker-compose` or `nvm` already address these concerns, adapting or integrating such projects to use these tools for common tasks requires some amount of work (or "glue").

"*[...] There are core parts of the technology that deliver most of the value / differentiator, and these are important to get right. There’s usually then a bunch of other software and services which is more like scaffolding; **you have it around in order to get stuff done**.*
*[...] “Mash-up” shouldn’t be a dirty hackfest concept.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

See also RDX's article from 2016/07/20 : [Modern Software Over-Engineering Mistakes](https://medium.com/@rdsubhas/10-modern-software-engineering-mistakes-bc67fbef4fc8).

## Targeted audience

Developers with or without much knowledge on using a terminal (CLI) working under Linux, MacOS, or Windows (using [Git Bash](https://git-for-windows.github.io/) or [Windows Subsystem for Linux ("bash on Ubuntu on Windows")](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)).

## Why bash

If CWT targets the same portability as Python (~ since [2011](https://unix.stackexchange.com/a/24808)), why not just use that language instead ?

That choice has more to do with personal interest, self-teaching, and minimalism (though one could perfectly implement a minimalist scaffolding tool in either language).

## What could an ideal solution look like (high-level goal)

The ideal solution would be measured in cognitive ressource - i.e. how do I quickly get these problems out of the way, *everytime* ?

It can seem titanesque to evaluate many [tools available nowadays](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html), so patterns like *extensions* (or *recipes*) / declarative approaches (i.e. `*.yml` files) could be concepts simple enough to quickly "get".

My current intuition of an "ideal" scaffolding tool is to apply focus on [language](https://pierrelevyblog.com/2017/10/06/the-next-platform) and communication (information design) - that's the ultimate goal.

"*I want to hear from people pushing standard stuff beyond its limits. I think we grossly underestimate what off-the-shelf systems can do, and grossly overestimate the capabilities of the things we develop ourselves. It’s time to talk much more about real-world, practical, medium-enterprise software architecture.*

*[...] Software development should be the tool of last resort: “we’re building this because it doesn’t exist in the form we need it”. I want to hear from more tech leaders about how they solved a problem without building the software, and tactics for avoiding development. [...] I want to hear more about projects that deferred decisions and put off architecting until much later in the process.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

TODO document software evaluation process

TODO "frontier" (borders, delimitation) / what [modularity](https://www.youtube.com/watch?v=vypCsVm5z28) teaches is to **hide complexity** by fragmentation (*"people got mad when I put it all in one file"*).

"*[Start] with a list of difficult design decisions or design decisions that are likely to change. Each module is then designed to hide such a decision from the others*"

-- David Parnas, *on the criteria to be used in decomposing systems into modules* (1971)

See also Ben Frain's *eCSS* book [chapter 5. File organisation and naming conventions](http://ecss.io/chapter5.html).

TODO explore relativity in [shell scopes](http://wiki.bash-hackers.org/scripting/processtree) (wrapping, isolation) - e.g. `local`, `export`...

TODO explore decentralized / "web de-siloing" technologies and [contributopia.org](https://contributopia.org)

TODO evaluate minimalist GUI opportunity (Electron ?)

## File structure (and status)

CWT is under construction. Folders might still move around depending on its use, until I feel it can start proper versionning. Consider this repo a scratchpad for now.

CWT essentially relies on a relative global namepace. Its creation process involves building it "on the fly" in other side projects in which each step listed above (*Next steps*) is achieved by specific, custom scripts placed in a different `scripts` dir alongside `cwt` in `PROJECT_DOCROOT`. In such cases, `PROJECT_SCRIPTS` is also set to `$PROJECT_DOCROOT/scripts` (See the *Alter / Extend CWT* section).

Ultimately, it should not compete with [other projects](https://paulmicha.github.io/common-web-tools/about/tools-considerations.html) (and I couldn't find a better word than "glue" for now, sorry).

This section illustrates a minimalist approach to organizational problems. It's still under study. Long-term considerations involve code generators, IEML, and the relationship between philosophy and programming ("naming things", "no language exists in isolation" - i.e. [schema.org](http://schema.org/docs/full.html)). Short-term : makefile integration ?

The file structure follows [loose naming and folder structure conventions](https://paulmicha.github.io/common-web-tools/about/patterns.html). Typically facts, actions, subjects are used to categorize includes of bash scripts meant to be sourced directly inside custom scripts (not included in the CWT project).

```txt
/path/to/project/           <- Project root dir ($PROJECT_DOCROOT).
  ├── cwt/
  │   ├── app/              <- [WIP] App init / (re)build / watch includes.
  │   ├── custom/           <- [configurable] default "modules" dir (alter or extend CWT. $PROJECT_SCRIPTS).
  │   ├── db/               <- [WIP] Database-related includes.
  │   ├── env/              <- Environment settings includes (global variables).
  │   │   └── current/      <- Generated settings specific to local instance (git-ignored).
  │   ├── git/              <- Versionning-related includes.
  │   │   └── hooks/        <- [WIP] Entry points for auto-exec (tests, code linting, etc.)
  │   ├── provision/        <- [WIP] Host-level dependencies related includes (softwares setup).
  │   ├── remote/           <- [TODO] Remote operations includes (add, provision, etc.)
  │   │   └── deploy/       <- [TODO] Deployment-related includes.
  │   ├── stack/            <- [WIP] Services and/or workers management includes.
  │   ├── test/             <- [TODO] Automated tests related includes.
  │   │   └── self/         <- [TODO] CWT internal tests.
  │   └── utilities/        <- CWT internal functions (hides complexity).
  ├── dumps/                <- [configurable] Database dump files (git-ignored).
  ├── web/                  <- [configurable] The app dir - can be outside project dir ($APP_DOCROOT).
  └── .gitignore            <- Replace with your own and/or edit.
```
