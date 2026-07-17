# Bootstrap

Every CWT action starts with:

```bash
. cwt/bootstrap.sh
```

Must run from `$PROJECT_DOCROOT`. Bootstrap loads utilities, globals, primitives (subjects/actions/extensions), eager includes, hooks, then **lazy** caller helpers.

Orchestrator: `cwt/bootstrap.sh` → numbered phases in `cwt/bootstrap/*.bootstrap-inc.sh`. Phase files are core bootstrap only — they are not subjects and are not registered into `CWT_INC`.

```mermaid
flowchart TD
  src[". cwt/bootstrap.sh"] --> flag{"CWT_BS_FLAG == 1?"}
  flag -->|no| p10["10-shell"]
  p10 --> p20["20-utilities"]
  p20 --> p30["30-globals"]
  p30 --> p40["40-primitives"]
  p40 --> p50["50-pre-hooks"]
  p50 --> p60["60-includes CWT_INC"]
  p60 --> p70["70-bootstrap-hook"]
  p70 --> setFlag["CWT_BS_FLAG=1"]
  flag -->|yes| skip["skip 10–70"]
  setFlag --> p90["90-caller-opt-inc"]
  skip --> p90
  p90 --> subjectOpt["subject.opt-inc.sh"]
  subjectOpt --> actionOpt["action.opt-inc.sh"]
```

## Once vs every time

| Scope | Flag / phase | Behavior |
|-------|--------------|----------|
| Heavy bootstrap | `CWT_BS_FLAG=1` after first run | Phases **10–70** run **once** per shell |
| Caller opt-inc | phase **90** | Runs on **every** `. cwt/bootstrap.sh` |

Interactive / bare `. cwt/bootstrap.sh` with no caller → phase 90 is a no-op.

## Phase map

```text
10-shell          shopt expand_aliases
20-utilities      shell, cwt, global, hook, autoload, fs, array, string, yaml
30-globals        data/cwt/global.vars.sh  (skip if CWT_BS_SKIP_GLOBALS=1)
40-primitives     cache or u_cwt_extend → CWT_SUBJECTS, CWT_ACTIONS, CWT_INC, …
50-pre-hooks      hook cwt/pre_bootstrap + cwt/alias
60-includes       source each path in CWT_INC (override-aware)
70-bootstrap-hook hook cwt/bootstrap
90-caller-opt-inc <subject>.opt-inc.sh then <action>.opt-inc.sh for the caller
```

## Eager vs lazy includes

| Kind | Pattern | When loaded |
|------|---------|-------------|
| **Eager** | `$subject/$subject.inc.sh`, extension `*.inc.sh` | Phase 60 via `CWT_INC` (once per shell) |
| **Lazy (caller)** | `$subject/$subject.opt-inc.sh`, `$subject/$action.opt-inc.sh` | Phase 90 when that subject/action sourced bootstrap |
| **Lazy (implementer)** | colocated `*.opt-inc.sh` next to a matched `*.hook.sh` | Seeded into the same `hook.${key}.sh` cache **before** hook bodies |

Overrides: `u_autoload_override` → `scripts/cwt/override/…`.

Typical eager includes (depends on enabled extensions): `cwt/git/git.inc.sh`, `cwt/host/host.inc.sh`, `cwt/instance/instance.inc.sh`, `cwt/test/test.inc.sh`, `cwt/make/make.inc.sh`, `cwt/thread/thread.inc.sh`, `cwt/extensions/file_registry/file_registry.inc.sh`.

## Primitives cache

Phase 40 prefers `data/cwt/cache/cwt.sh`. Miss → `u_cwt_extend` then write cache.

```bash
make cwt-cache-clear
make reinit
```

After changing extension ignore lists or adding subjects under `scripts/cwt/extend/`, clear cache / reinit so primitives match disk.

## Nested / virgin env

`nested-cwt-exec` starts a **new** bash with `env -i` in the child docroot. That child runs its own bootstrap. Parent `CWT_BS_FLAG` does not apply there. See [nested-cwt.md](nested-cwt.md).

## Gotchas

- `CWT_BS_SKIP_GLOBALS=1` — utilities + primitives without written globals (init/debug).
- Do not `source` another instance’s `global.vars.sh` into the parent shell; use nested exec.
- Aliases must be defined by phase 50 (`cwt`/`alias` hook) **before** phase 60 includes.

SoT: `cwt/bootstrap.sh`, `cwt/bootstrap/`.
