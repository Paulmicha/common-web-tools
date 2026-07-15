# CWT extensions

Every folder in this path is an extension, but not their subfolders.

In order to disable extensions without having to delete or move their folder,
add one per line in the dotfile `.cwt_extensions_ignore` (to be placed in
`scripts/cwt/override/.cwt_extensions_ignore`).

Core also ships `cwt/extensions/.cwt_extensions_ignore` (default exclusions for
this tree). Project override files take precedence when present.

### preset

Canonical / ideal CWT presets (discover → list → write → improve). Lives as an
extension so packs stay out of core subjects; subject folder matches the
extension name (same layout as `software` / `nested_cwt`):

| Action | Path | Make |
|--------|------|------|
| Catalog ideals | `cwt/extensions/preset/preset/discover.sh` | `make preset-discover` |
| Host-filtered catalog | `cwt/extensions/preset/preset/list.sh` | `make preset-list` |
| Apply packs / scaffolds | `cwt/extensions/preset/preset/write.sh` | `make preset-write …` |
| Diagnose / hook dry-run | `cwt/extensions/preset/preset/improve.sh` | `make preset-improve …` |

Helpers: `cwt/extensions/preset/preset/preset.inc.sh` (`u_preset_root` → that dir).
Pack templates (`app`, `db`, `11ty`, …) sit under the subject folder so they are
not mistaken for extension subjects. Enabled by default (not listed in
`.cwt_extensions_ignore`).

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
