# CWT extensions

Narrative guide (enable/disable, override, families): [docs/cwt/extensions.md](../../docs/cwt/extensions.md).
Root overview + catalog table: [README.md](../../README.md).

Every folder in this path is an extension, but not their subfolders.

In order to disable extensions without having to delete or move their folder,
add one per line in the dotfile `.cwt_extensions_ignore` (to be placed in
`scripts/cwt/override/.cwt_extensions_ignore`).

Core also ships `cwt/extensions/.cwt_extensions_ignore` (default exclusions for
this tree). Project override files take precedence when present.

### Includes: eager `*.inc.sh` vs lazy `*.opt-inc.sh`

| Pattern | When loaded | Use when |
|---------|-------------|----------|
| `$subject/$subject.inc.sh` or `$ext/$ext.inc.sh` | Eager — every bootstrap (`CWT_INC`, phase 60) | Helpers needed from other subjects **outside** `hook()`, wraps, or globals |
| `$subject/$subject.opt-inc.sh` | Lazy — phase 90 when any action in that subject dir sources bootstrap | Helpers only used by that subject’s actions |
| `$subject/$action.opt-inc.sh` | Lazy — phase 90 for that action only **or** seeded into `hook.${key}.sh` when a colocated `*.hook.sh` matches | Helpers for one action / foreign-subject hook implementers |

Phase 90 keys off the bootstrap **caller** path. For **foreign-subject hooks** (e.g. `software` implementing `host/provision`), place helpers next to the hook as `provision.opt-inc.sh` / `host.opt-inc.sh` — `hook()` prepends those `.` lines into the same cache file before the hook bodies (1a). See `changelog/2026/07/16-cwt-include-splitting-hook-mapped-deps.md`, `u_hook_opt_inc_append_candidates` in `cwt/utilities/hook.sh`, and `cwt/bootstrap/90-caller-opt-inc.bootstrap-inc.sh`.

Extension-root `$ext/$ext.inc.sh` cannot become caller opt-inc by rename alone; relocate into a subject/action `*.opt-inc.sh` (and rely on hook-cache seeding when used from foreign hooks).

### builder

Extension folder `builder` (was `preset`). Tip subjects are **stubs**:
`blueprint` / `blueprints`, `prototype` / `prototypes`, `template` / `templates`.
Pack files live under `cwt/extensions/builder/templates/` (`boilerplate/`,
`cwt/`, `services/`).

Listed in **core** `.cwt_extensions_ignore`, but the active project override
`scripts/cwt/override/.cwt_extensions_ignore` does **not** list `builder` —
after `make reinit`, stub targets register (`blueprint-*`, `prototype-*`,
`template-*`, …). Bodies remain `# TODO`.

Same pattern for `memory` (`storage-*`, `store-*`).

### cognition / transcription (optional, core-ignored by default)

| Extension | Role |
|-----------|------|
| `cognition` | `observe-*` / `recognize-*` stubs |
| `transcription` | Abstract `make transcribe` + `transcribe-all`; subject-free `u_hook_most_specific -a 'transcribe' …`; generic defaults `transcribe.hook.sh`, `ogg.hook.sh`, `wav.hook.sh`, `transcribe.py` (tested on debian-13 only for now) |

Both are listed in **core** `.cwt_extensions_ignore`. This home’s override omit them → they register after reinit. Path: `cwt/extensions/transcription/transcribe/`. Make shortcut: `transcribe-transcribe` → `transcribe` via `CWT_MAKE_TASKS_SHORTER`. No CoT / principle / plan agent stubs in core (see `changelog/2026/07/16-cwt-core-strip-agent-extensions.md`).

### gpt / ollama (optional, core-ignored by default)

| Extension | Role |
|-----------|------|
| `gpt` | Abstracts — `gpt-start`, `gpt-status`, `gpt-list`, `gpt-pull`, `gpt-stop`, `gpt-stop-all` (+ `gpt-wrap`) |
| `ollama` | Default hooks — `start` / `status` / `list` / `pull` / `stop` / `stop_all` `.hook.sh` |

Both listed in **core** `.cwt_extensions_ignore`. Subject folder is `gpt/` under both so make targets stay `gpt-*`. Ignoring `ollama` drops the default hooks while `gpt` can still register targets. Agent / tools / exchange stay out of this tip (dedicated project). See `changelog/2026/07/16-remaining-plans-simplification.md`.

### nested_cwt

Optional extension for listing nested CWT project instances and running commands
in a virgin env inside them:

| Action | Path | Make |
|--------|------|------|
| List / map layouts | `cwt/extensions/nested_cwt/nested_cwt/list.sh` | `make nested-cwt-list [ref]` |
| Virgin-env exec | `cwt/extensions/nested_cwt/nested_cwt/exec.sh` | `make nested-cwt-exec <ref> e:<entry>` / `exec.sh <ref> <entry>` / `-- <cmd>` |

`ref` is a short id from the instance folder name (Compose-style). On name
collisions, qualify with parent folders (`client/my-project`). Absolute paths
still work. Command argument forms after `<ref>`:

| Form | Behavior |
|------|----------|
| `<make-entry>` / `e:<make-entry>` | Nested `make <entry> …` (`e:` only when calling via `make`) |
| Path-like (`/`, `./`, `../`, contains `/`, ends `.sh`, or existing file) | Raw in child — no make wrap |
| `-- <cmd…>` | Explicit raw command |

Shared helpers: `nested_cwt.opt-inc.sh` (lazy via bootstrap phase 90 when any
subject action bootstraps). Optional `$action.opt-inc.sh` for action-only
helpers. Not `nested_cwt.inc.sh` (eager `CWT_INC`).

Listed in `.cwt_extensions_ignore` by default — remove `nested_cwt` from the
active ignore file and `make reinit` to enable.
