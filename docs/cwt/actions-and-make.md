# Actions and Make

An **action** is a script `cwt/<subject>/<action>.sh` (or under an extension / `scripts/cwt/extend/`). `make init` / `reinit` discovers them and generates `data/cwt/generated.mk` shortcuts (`subject-action`, with shorter aliases from `CWT_MAKE_TASKS_SHORTER`).

```mermaid
flowchart TD
  disk["subject/action.sh"] --> init["make init / reinit"]
  init --> prim["u_cwt_extend primitives"]
  prim --> mk["data/cwt/generated.mk"]
  shorter["CWT_MAKE_TASKS_SHORTER"] --> mk
  mk --> makeCall["make subject-action / lt / …"]
  makeCall --> wrap["call_wrap.make.sh"]
  wrap --> script["action script"]
  script --> bs[". cwt/bootstrap.sh"]
```

```bash
make list-actions
make make-list-entry-points
```

Always run from `$PROJECT_DOCROOT`. Prefer `make <entry>`; the equivalent path is the script itself after `. cwt/bootstrap.sh`.

## Discovery rules

- **Folders** = subjects; **files** = actions (`*.sh`).
- Exceptions: dirs starting with `.`; files with double extensions (`*.inc.sh`) or starting with `.`; `.cwt_actions_ignore` / `.cwt_subjects_ignore`.
- Lookup: `./cwt`, every **enabled** extension under `cwt/extensions`, and `scripts/cwt/extend`.
- Details: `u_cwt_extend()` in `cwt/utilities/cwt.sh`.

## Hardcoded vs generated

| Source | Targets |
|--------|---------|
| [`cwt/make/default.mk`](../../cwt/make/default.mk) | `init`, `init-debug`, `setup`, `hook`, `hook-debug`, `globals-lp`, `debug` |
| `data/cwt/generated.mk` (after init) | All discovered subject/action shortcuts + per-case test targets |

`.DEFAULT_GOAL` in the root [`Makefile`](../../Makefile) is `init`. The Makefile also `-include`s `.env`, `data/cwt/generated.mk`, optional `CWT_MAKE_INC`, and `scripts/cwt/extend/custom.mk`.

The `instance` subject is omitted from many make names (`make start` ≡ `instance start`). Shortening uses `CWT_MAKE_TASKS_SHORTER` (bash `${task//search/replace}` in `u_make_task_name()`).

Canonical short aliases:

| Shortcut | Full make target |
|----------|------------------|
| `lt` | `logged-thread` |
| `lc` | `logged-chain` |
| `ls` | `logged-sequence` |
| `lb` | `logged-batch` |
| `lp` | `logged-pipe` |
| `ll` | `logged-loop` |
| `reg` | `registry` |
| `pl` | `lookup-path` (must **not** collide with `lp`) |

Historical: `make globals-lp` remains a **hardcoded** target — not the `lp` → `logged-pipe` alias.

After changing `CWT_MAKE_TASKS_SHORTER` or adding actions: `make reinit`.

## Core subjects (examples)

| Subject | Example entry points |
|---------|----------------------|
| `instance` | `init`, `reinit`, `setup`, `start`/`stop`, `chain`, logged wrappers, `reg-*`, `switch-stack-version` |
| `host` | `host-provision`, `host-reg-*`, `host-vitals` |
| `git` | `git-write-hooks`, `git-find-changed-files` |
| `log` / `loop` / `thread` | wraps, status, batch/pipe/sequence |
| `test` | `test-cwt`, `test-cwt-*` |
| `sidecar` | `sidecar-wrap` |

Launch layering: [layers.md](layers.md). Observability paths: [observability.md](observability.md).
