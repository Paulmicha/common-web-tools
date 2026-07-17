# CWT layers

Two related meanings of “layers” in CWT. Do not confuse them with the Docker **`compose`** extension (`cwt/extensions/compose`).

1. **Implementation differentiators (1–5)** — where to put state, config, contracts, extensions, and project code.
2. **Launch stack (raw → thread → log wrap)** — how make entry points are stacked at runtime.

---

## Implementation differentiators (1–5)

Prefer the lowest layer that can own the concern.

| # | Layer | Owns / provides | Location | Explanation |
|---|-------|-----------------|----------|-------------|
| **1** | **Data** | On-disk / host facts (may be private or identifying): paths, entity YAML, logs, dumps | `data/…`, host files (e.g. `/etc/hosts`) | **State only** — never business logic |
| **2** | **Global ENV vars** | (A) **readonly globals** — aggregated on `make init` / `reinit`, written to gitignored `data/cwt/global.vars.sh` + `.env`; (B) **calling-scope (“mutable”) vars** — ordinary shell vars that change mid-run (e.g. `DB_*` after `u_db_set`) | Declarations: `env.yml`, `.env-local.yml`, `cwt/**/global.vars.sh`, `scripts/cwt/extend/**/global.vars.sh` | **Configuration & execution context** |
| **3** | **Abstract CWT core entry points** | Abstract actions that are hooks (placeholders) or wrappers with **no** concrete backend | `cwt/<sidecar,log,loop,thread>/wrap.sh`, `cwt/instance/<entry>.sh` | **Contracts** — calling-scope vars, hooks to implement |
| **4** | **CWT core extensions** | Broader abstract actions and/or **minimal** concrete implementations; often disabled by default | `cwt/extensions/<name>` | Abstract e.g. `db`, `gpt`; concrete e.g. `compose`, `mysql`, `ollama` |
| **5** | **Project extend** | Project wiring, remotes, host policy | `scripts/cwt/extend/**`, project YAML | **Overrides / product** — never dump this into core |

```mermaid
flowchart TB
  subgraph L5 [5 Project extend]
    ext["scripts/cwt/extend · project YAML"]
  end
  subgraph L4 [4 Core extensions]
    hooks["compose · mysql · gpt · file_registry · …"]
  end
  subgraph L3 [3 Abstract core entry points]
    api["wraps · instance entries · registry API"]
  end
  subgraph L2 [2 Global ENV vars]
    ro["readonly: data/cwt/global.vars.sh · .env"]
    mut["mutable: DB_* · REMOTE_INSTANCE_* · …"]
  end
  subgraph L1 [1 Data]
    cwt["data/cwt/* derived"]
    domain["data/logs · threads · db-dumps · …"]
  end
  L5 --> L4
  L5 --> L3
  L4 --> L3
  L3 --> L2
  L3 --> L1
  L4 --> L1
  L2 --> L1
```

**Rules of thumb**

1. State on disk → **Layer 1**.
2. Instance config / mid-run retargeting → **Layer 2** (see [globals.md](globals.md)).
3. Contracts (wrap, get/set, token replace) → **Layer 3**.
4. Generic / minimal implementations → **Layer 4**.
5. This machine / product schedules, remotes policy → **Layer 5**.

See also [secrets.md](secrets.md) and [sidecar-wrap.md](sidecar-wrap.md).

---

## Launch stack (raw → thread → log wrap)

Every launch is a stack of at most three layers. Higher layers never invent a second operator — they only wrap the layer below.

| Layer | Role | Typical scripts |
|-------|------|-----------------|
| **1. Raw call** | Run one make entry (or shell) with no join / fan-out | `make <entry>`, script under `cwt/` / `scripts/` |
| **2. Thread level** | Run one or more raw calls with a shell operator | `thread/wrap.sh` (`&`), `sequence.sh` (`&&` / `;`), `batch.sh` (`&` + wait), `pipe.sh` (`\|`) |
| **3. Optional log wrap** | Capture stdout/stderr + structured traces around layer 2 | `cwt/log/wrap.sh` |

```mermaid
flowchart TB
  subgraph L3["Layer 3 — optional log wrap"]
    log["cwt/log/wrap.sh"]
  end
  subgraph L2["Layer 2 — thread level"]
    tw["thread/wrap.sh"]
    seq["thread/sequence.sh"]
    bat["thread/batch.sh"]
    pipe["thread/pipe.sh"]
  end
  subgraph L1["Layer 1 — raw call"]
    make["make entry"]
  end
  log --> tw
  log --> seq
  log --> bat
  log --> pipe
  tw --> make
  seq --> make
  bat --> make
  pipe --> make
```

| Operator | Thread script | Unlogged aliases | + log wrap |
|----------|---------------|------------------|------------|
| `&` (+ wait for multi) | `cwt/thread/batch.sh` | `parallel`, `thread-batch` | `lb`, `logged-batch` |
| `&&` or `;` | `cwt/thread/sequence.sh` | `chain` (`instance/chain.sh`) | `lc` / `ls` |
| `\|` | `cwt/thread/pipe.sh` | `pipe`, `thread-pipe` | `lp`, `logged-pipe` |
| `&` (single supervised) | `cwt/thread/wrap.sh` | thread helpers | `lt`, `logged-thread` |

There is **no** `cwt/chain/` folder. Plain `make chain` → `instance/chain.sh` → `thread/sequence.sh`.

Token prefixes for multi-entry runners: `e:<entry>`, `e:<N>:<entry>`, `a:<arg>`, `join:&&` / `join:;`, `workers:<N>`.

```bash
make lc e:site-cr e:site-composer a:install e:api-cr
# → make site-cr && make site-composer install && make api-cr
```

### Quick chooser

| Need | Use | Layers |
|------|-----|--------|
| Run once, foreground | `make <entry>` | 1 |
| One background job | `make lt e:…` | 3 → 2 → 1 |
| Ordered pipeline, no capture | `make chain` | 2 → 1 |
| Ordered + logs via chain | `make lc` | 3 → chain → sequence |
| Ordered + logs direct | `make ls` | 3 → sequence |
| Concurrent fan-out | `make parallel` / `lb` | 2 or 3 → batch |
| Stdout → stdin | `make pipe` / `lp` | 2 or 3 → pipe |
| Long-running / reboot | `make ll` | 3 → loop wrap → 1 |

Details and paths: [observability.md](observability.md).
