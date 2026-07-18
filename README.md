# Common Web Tools (CWT)

## TL;DR

Clone or copy this repo into your project docroot, then:

```sh
cp SPECIMEN.env.yml env.yml   # edit as needed
make setup                    # or: make   → instance init
```

Deep dives live under [`docs/cwt/`](docs/cwt/). Extension notes: [`cwt/extensions/README.md`](cwt/extensions/README.md).

## WHAT

CWT is a scaffolding bash shell CLI for usual web project tasks — a generic, customizable, extensible toolbox for **local (internal) development**.

CWT is not a program; it is the “glue” between programs. Third-party integration is provided by **extensions** (bundled under `cwt/extensions/`, often disabled by default). Core contains utilities for global environment variables, minimal host operations, optional git hooks, log/thread/loop wrappers, and low-level automated tests (`make test-cwt`).

CWT is **not** meant for production. It helps individual developers or teams keep a common CLI across older and newer projects.

## PURPOSE

CWT organizes (mostly bash) scripts around conventions so you can swap implementations without rewriting every project’s workflow:

- host-level dependencies / provisioning
- credentials and registries
- building / running / stopping / destroying instances (variants per env type)
- generating local app settings
- linting / watching / compiling
- cron / long-running loops
- automated tests
- remote two-way sync
- etc.

## HOW (concepts in brief)

CWT relies on **file structure**, **naming conventions**, and a few primitives:

| Concept | Summary | Deep dive |
|---------|---------|-----------|
| **Globals** | Instance env vars from `env.yml` / `global.vars.sh`, written to `.env` + `data/cwt/global.vars.sh` | [docs/cwt/globals.md](docs/cwt/globals.md) |
| **Bootstrap** | `. cwt/bootstrap.sh` → numbered phases; eager `*.inc.sh` vs lazy `*.opt-inc.sh` | [docs/cwt/bootstrap.md](docs/cwt/bootstrap.md) |
| **Instance init** | Aggregates globals, optional git hooks, generates make shortcuts | `u_instance_init()` in `cwt/instance/instance.inc.sh` |
| **Actions** | Folders = subjects, files = actions → `data/cwt/generated.mk` | [docs/cwt/actions-and-make.md](docs/cwt/actions-and-make.md) |
| **Hooks** | File-based events (`*.hook.sh`) with variant combinations | [docs/cwt/hooks.md](docs/cwt/hooks.md) |

Prefer the lowest of five **implementation layers** (data → globals → abstract entry points → core extensions → project extend). See [docs/cwt/layers.md](docs/cwt/layers.md).

## Prerequisites

- Bash **4+** (macOS: install a modern bash via Homebrew and set it as your shell if needed)
- Git
- An existing or new project directory
- [optional] Remote host with Bash 4+ over SSH
- [optional] GNU make

Disclaimer: CWT is primarily tested on Debian-based Linux.

## Usage / Getting started

### Placement

Two common layouts:

1. Single “monolithic” repo for the whole project
2. Application code in a separate Git repo (default assumption in this repo’s `.gitignore`)

CWT core (`cwt/`) may sit inside the app (same docroot), in a parent “dev stack” repo (usual), or elsewhere on the host. App paths are typically declared per `CWT_APPS` entry (e.g. `SITE_DOCROOT`) via `env.yml`. **All** CWT scripts and `make` targets must be run from `$PROJECT_DOCROOT`.

### Step by step

1. Copy this repo’s files into the chosen docroot (or clone and use as the stack root).
2. Review [`.gitignore`](.gitignore) and adapt it.
3. Override extension defaults: copy `cwt/extensions/.cwt_extensions_ignore` → `scripts/cwt/override/.cwt_extensions_ignore` and edit (delete a line to **enable** that extension).
4. Copy [`SPECIMEN.env.yml`](SPECIMEN.env.yml) → `env.yml` and edit. Settings that **do not vary** much between instance types belong here (stack version, apps, paths). Use gitignored `.env-local.yml` for machine-private overrides.
5. Optionally implement project code under `scripts/cwt/extend/` and overrides under `scripts/cwt/override/`.
6. Run **instance setup**:

```sh
make setup
# Or:
cwt/instance/setup.sh
```

Setup runs, in order:

1. **instance init** — write globals (`.env`, `data/cwt/global.vars.sh`), generate `data/cwt/generated.mk`, optional git hooks, caches
2. **instance start** — start services if hooks implement them
3. **stage2 / post setup hooks** — e.g. create DBs, import dumps, vendor install (extension-defined)

Idempotent: safe to re-run. If globals are already `readonly` in the current shell, use a new terminal or `make reinit` instead of `setup` for the init step.

### Setup parameters

From [`cwt/instance/setup.sh`](cwt/instance/setup.sh):

| Param | Global | Default |
|-------|--------|---------|
| 1 | `INSTANCE_TYPE` | `dev` |
| 2 | `HOST_TYPE` | `local` |
| 3 | `STACK_VERSION` | empty (falls back to global default `v1` on init) |
| 4 | `PROVISION_USING` | `compose` (note: core global default when undeclared is `cwt`) |

Examples:

```sh
make setup
make setup prod
make setup prod remote myproject-2024 lamp
```

## File structure

```txt
/path/to/my-project/          ← $PROJECT_DOCROOT
  ├── app,site,api/ …         ← [optional] application trees (per CWT_APPS / env.yml)
  ├── changelog/              ← [optional] documentation of past or planned modifications
  ├── cwt/                    ← CWT core (update = replace folder)
  │   ├── env/                ← core global.vars.sh + helpers
  │   ├── extensions/         ← bundled extensions (opt-in via ignore file)
  │   ├── git/                ← git hooks integration + utilities
  │   ├── host/               ← host provision, registry, vitals
  │   ├── instance/           ← lifecycle + logged runners + chain/pipe
  │   ├── log/,sidecar/,loop/,thread/ ← core CWT wrappers
  │   ├── make/               ← default.mk + call_wrap
  │   ├── test/               ← shunit2 low-level suite
  │   ├── utilities/          ← internal libraries
  │   ├── vendor/             ← shunit2, bash-yaml
  │   └── bootstrap.sh        ← included in all entry points, loads bash functions and globals
  ├── data/                   ← runtime / generated (mostly gitignored)
  │   ├── cronjobs/           ← [git-ignored] default place for cron jobs outputs
  │   ├── cwt/                ← [git-ignored] Generated files specific to this local instance
  │   │   ├── cache/          ← current local instance generated hooks and *.opt-inc.sh auto-include cache
  │   │   ├── registry/       ← [optional] contains keyed "file-based store" values
  │   │   ├── generated.mk    ← current local instance generated make entry points
  │   │   └── global.vars.sh
  │   ├── logs/               ← [git-ignored] default place for logs (see also log-rotate)
  │   ├── media/              ← [git-ignored] default place for media
  │   ├── private/            ← [git-ignored] default place for private files
  │   ├── test-results/       ← [optional] frozen (versionned) test results
  │   ├── threads/            ← [git-ignored] default place for storing threads info
  │   ├── tmp/                ← [git-ignored] default place for temporary files
  │   └── ...
  ├── docs/
  │   ├── cwt/                ← CWT-related deep-dive guides and living documentation
  │   └── ...
  ├── scripts/cwt/
  │   ├── extend/             ← project-specific extension
  │   └── override/           ← replace any sourced CWT path
  ├── .gitignore
  ├── Makefile
  ├── .env.yml                ← current local instance generated ENV vars
  ├── .env-local.yml          ← [optional, git-ignored] secret ENV vars (hardcoded)
  ├── .env-local.foobar.yml   ← [optional, git-ignored] conditional secret ENV vars (hardcoded)
  ├── env.yml                 ← this project instance global env vars declaration
  ├── SPECIMEN.env.yml        ← copy to env.yml
  └── ...
```

The canonical path for writing files related to time-recurrent or long processes is :

```txt
data/<data_name>/YYYY/MM/DD/HH.MM.SS.MS.<file_name>.md
```

Ex : `data/event/2026/07/17/11.06.55.1234.drush_cron.md`

The `changelog/` dir tipically contains files like :

```txt
changelog/YYYY/MM/DD-<file_name>.md
```

Ex : `changelog/2026/07/17-implement-new-ollama-subject.md`

Generated (do not hand-edit): `.env`, `data/cwt/global.vars.sh`, `data/cwt/generated.mk`, `data/cwt/cache/*`.

## Five implementation layers

| # | Layer | Owns |
|---|-------|------|
| 1 | Data | `data/…`, host files — state only |
| 2 | Global ENV vars | readonly globals vs calling-scope mutables |
| 3 | Abstract core entry points | wraps / placeholders |
| 4 | Core extensions | abstract + minimal concrete |
| 5 | Project extend | `scripts/cwt/extend/**` |

Full table, mermaid, and **launch** layer stack (raw → thread → log wrap): [docs/cwt/layers.md](docs/cwt/layers.md).

## Adapt / Alter / Extend

- Project scripts under `scripts/`
- Generic reusable extensions as folders in `cwt/extensions/`
- Project-only hooks/globals/actions in `scripts/cwt/extend/`
- Hard replacements via `scripts/cwt/override/`

Details: [docs/cwt/extensions.md](docs/cwt/extensions.md).

### Globals (summary)

On init, globals are written to:

- `.env` — Makefile and other tools
- `data/cwt/global.vars.sh` — sourced every bootstrap (phase 30)

Declare via `global NAME "…"` in `global.vars.sh` files, or YAML in `env.yml` / `.env-local.yml`. List aggregation paths:

```sh
make globals-lp
```

Selected core defaults (`cwt/env/global.vars.sh`):

```sh
global PROJECT_DOCROOT "[default]='$PWD' …"
global STACK_VERSION "[default]=v1 …"
global INSTANCE_TYPE "[default]=dev …"
global PROVISION_USING "[default]=cwt …"
global HOST_TYPE "[default]=local …"
global HOST_OS "$(u_host_os)"
global CWT_APPS "[default]='site' …"
global CWT_MAKE_INC "[append]='$(u_cwt_extensions_get_makefiles)'"
global CWT_SYNONYMS "[append]='registry/reg lookup-path/pl logged-thread/lt logged-batch/lb logged-chain/lc logged-sequence/ls logged-loop/ll logged-pipe/lp transcribe-transcribe/transcribe'"
```

More: [docs/cwt/globals.md](docs/cwt/globals.md). Secrets stance: [docs/cwt/secrets.md](docs/cwt/secrets.md).

### Actions (summary)

```sh
make list-actions
```

Hardcoded shortcuts ([`cwt/make/default.mk`](cwt/make/default.mk)): `init` (also default `make`), `init-debug`, `setup`, `hook`, `hook-debug`, `globals-lp`, `debug`.

After init, `data/cwt/generated.mk` adds subject/action targets. Typical core shortcuts (instance subject often omitted):

| Name | Script | Shortcut |
|------|--------|----------|
| *git write-hooks* | `cwt/git/write_hooks.sh` | `make git-write-hooks` |
| *host provision* | `cwt/host/provision.sh` | `make host-provision` |
| *host registry-\** | `cwt/host/registry_*.sh` | `make host-reg-*` |
| *host vitals* | `cwt/host/vitals.sh` | `make host-vitals` |
| *instance build* | `cwt/instance/build.sh` | `make build` |
| *instance destroy* | `cwt/instance/destroy.sh` | `make destroy` |
| *instance fix-ownership* | `cwt/instance/fix_ownership.sh` | `make fix-ownership` |
| *instance fix-perms* | `cwt/instance/fix_perms.sh` | `make fix-perms` |
| *instance init* | `cwt/instance/init.sh` | `make init` / `make` |
| *instance rebuild* | `cwt/instance/rebuild.sh` | `make rebuild` |
| *instance registry-\** | `cwt/instance/registry_*.sh` | `make reg-*` |
| *instance reinit* | `cwt/instance/reinit.sh` | `make reinit` |
| *instance restart* | `cwt/instance/restart.sh` | `make restart` |
| *instance setup* | `cwt/instance/setup.sh` | `make setup` |
| *instance start / stop* | `cwt/instance/start.sh` / `stop.sh` | `make start` / `stop` |
| *instance chain* | `cwt/instance/chain.sh` | `make chain` |
| *instance parallel / pipe* | `cwt/instance/parallel.sh` / `pipe.sh` | `make parallel` / `pipe` |
| *instance logged-\** | `cwt/instance/logged_*.sh` | `make lt` / `lc` / `ls` / `lb` / `lp` / `ll` |
| *instance switch-stack-version* | `cwt/instance/switch_stack_version.sh` | `make switch-stack-version` |
| *instance uninit* | `cwt/instance/uninit.sh` | `make uninit` |
| *cwt upgrade* | `cwt/cwt/upgrade.sh` | `make cwt-upgrade` |
| *cwt cache-clear* | `cwt/cwt/cache_clear.sh` | `make cc` |
| *test cwt* | `cwt/test/cwt.sh` | `make test-cwt` |

Logged runners and operators: [docs/cwt/observability.md](docs/cwt/observability.md), [docs/cwt/layers.md](docs/cwt/layers.md).

```sh
make lt e:some-entry
make lc e:1:step-a e:2:step-b a:arg
make lb e:job-a e:job-b
make lp e:stage-a e:stage-b
make ll e:long-running
```

After changing `CWT_SYNONYMS`: `make reinit`.

### Automatic includes (summary)

| Pattern | When |
|---------|------|
| `$subject/$subject.inc.sh` / `$ext/$ext.inc.sh` | Eager → `CWT_INC` (phase 60) |
| `$subject/$subject.opt-inc.sh` | Lazy when any action in that subject is the caller |
| `$subject/$action.opt-inc.sh` | Lazy for that action (also seedable into hook cache) |

More: [docs/cwt/bootstrap.md](docs/cwt/bootstrap.md).

### Hooks (summary)

```sh
make hook-debug a:start
make hook-debug s:instance a:start v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
```

`PROVISION_USING=compose` and `docker-compose` both expand in lookups (dual-compat). Specificity and filters: [docs/cwt/hooks.md](docs/cwt/hooks.md).

Example:

```sh
hook -s 'app instance' \
  -a 'fs_perms_set' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
```

Default `fs_perms_set` only touches CWT-managed paths (`./data`, `./cwt`, `./scripts/cwt`, `./.git`, plus a small whitelist of root files such as `env.yml` / `Makefile`).

### Extensions (summary)

Enable/disable via ignore files (see above). Catalog of bundled folders:

| Name | Default on? | Description |
|------|:-----------:|-------------|
| `apache` | | Apache VHost helpers (classic LAMP, non-compose) |
| `arangodb` | | Alias / image tag defaults |
| `builder` | | Templates / blueprints / prototypes stubs ([docs/cwt/builder.md](docs/cwt/builder.md)) |
| `cognition` | | `observe-*` / `recognize-*` stubs |
| `compose` | | Docker Compose start/stop/build/destroy (`DC_MODE`, stack helpers) |
| `crontab` | | Host crontab sync helpers |
| `db` | | Abstract DB hooks |
| `drupalwt` | | Drupal tasks ([extension README](cwt/extensions/drupalwt/README.md)) |
| `drupalwt_d4d` | | Drupal + compose / docker4drupal-oriented stack |
| `drush` | | Drush aliases / hooks |
| `file_registry` | ✔ | Default file-based registry (instance / host) |
| `git_crypt` | | Opt-in encryption hooks (stub) |
| `gpt` | | LLM abstracts (`gpt-start`, …) |
| `hosts_file` | | `/etc/hosts` helpers |
| `interaction` | | Interactive prompt helpers |
| `memory` | | Storage / store stubs |
| `moodle_d4php` | | Moodle + docker4php-oriented stack |
| `mysql` | | MySQL implementations of `db` |
| `nested_cwt` | | Nested instance list/exec ([docs/cwt/nested-cwt.md](docs/cwt/nested-cwt.md)) |
| `node` | | Aliases / default port |
| `ollama` | | Default hooks for `gpt-*` via Ollama |
| `pgsql` | | Postgres implementations of `db` |
| `remote` | | SSH sync utilities |
| `remote_cwt` | | Remote CWT helpers |
| `remote_db` | | DB dump sync via `db` + `remote` |
| `remote_traefik` | | Traefik / Let’s Encrypt defaults |
| `rules` | | Rule stubs |
| `software` | | Host package / provision hooks |
| `transcription` | | `transcribe` / `transcribe-all` |
| `views` | | View stubs |

Default-on assumes the stock core ignore list (everything listed there is off; `file_registry` is usually the exception). Project overrides win. More: [docs/cwt/extensions.md](docs/cwt/extensions.md), [`cwt/extensions/README.md`](cwt/extensions/README.md).

## Automated tests

```sh
make test-cwt
```

Single orchestration hook: `test` / `cwt`. Core cases under `cwt/test/cwt/*.test.sh`; extensions and `scripts/cwt/extend` can append via `test/cwt.hook.sh`. Per-case make targets are generated into `data/cwt/generated.mk` on `reinit` (registry: `data/cwt/cache/test-cases.sh`).

Full guide: [docs/cwt/testing.md](docs/cwt/testing.md).

## Docs index

| Guide | Topic |
|-------|--------|
| [docs/cwt/layers.md](docs/cwt/layers.md) | Implementation layers 1–5 + launch stack |
| [docs/cwt/globals.md](docs/cwt/globals.md) | Readonly vs mutable; `env.yml` |
| [docs/cwt/bootstrap.md](docs/cwt/bootstrap.md) | Phases; eager/lazy includes |
| [docs/cwt/hooks.md](docs/cwt/hooks.md) | Hooks + variant combos |
| [docs/cwt/actions-and-make.md](docs/cwt/actions-and-make.md) | Discovery; generated.mk |
| [docs/cwt/observability.md](docs/cwt/observability.md) | `lt`/`lc`/…; log/thread paths |
| [docs/cwt/testing.md](docs/cwt/testing.md) | `make test-cwt` |
| [docs/cwt/secrets.md](docs/cwt/secrets.md) | Registry / gitignore stance |
| [docs/cwt/extensions.md](docs/cwt/extensions.md) | Enable, override, families |
| [docs/cwt/builder.md](docs/cwt/builder.md) | Builder (ex-preset) |
| [docs/cwt/nested-cwt.md](docs/cwt/nested-cwt.md) | Nested virgin-env exec |
| [docs/cwt/sidecar-wrap.md](docs/cwt/sidecar-wrap.md) | Durable sidecar SoT |

## Roadmap

- Keep `make test-cwt` (and per-case targets) current
- Finish shared sidecar wrap body and migrate writers ([docs/cwt/sidecar-wrap.md](docs/cwt/sidecar-wrap.md))
- Fix macOS-specific errors
- Offload more tasks to third-party projects where sensible
- Reduce bashisms / improve POSIX compatibility where practical

## License

The MIT license (see [LICENSE](LICENSE)).
