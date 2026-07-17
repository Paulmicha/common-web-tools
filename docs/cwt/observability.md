# Observability

Passive contracts: how to launch, where to look, how log wrappers emit audit trails. Launch layer tables: [layers.md](layers.md).

## Log wrappers

```text
make lt e:<entry>   → log/wrap → thread/wrap          → make <entry>
make ll e:<entry>   → log/wrap → loop/wrap (systemd)  → make <entry>
make lc e:1:… e:2:… → log/wrap → instance/chain → thread/sequence
make ls e:1:… e:2:… → log/wrap → thread/sequence
make lb e:… e:…     → log/wrap → thread/batch
make lp …           → log/wrap → thread/pipe
```

Plain `make chain` → `instance/chain` → `thread/sequence` (no `cwt/chain/`).
`parallel` / `thread-batch` and `pipe` / `thread-pipe` skip log/wrap.

## Paths

| Path | Role |
|------|------|
| `data/logs/<entry>.txt` | Flat stdout/stderr stream |
| `data/logs/<entry>.changelog.txt` | Launch audit lines (also see [changelog-wrap.md](changelog-wrap.md)) |
| `data/threads/<entry>.yml` | Lifecycle (pid, status, owner, attempts) |
| `data/threads/<entry>.lock` | flock pile-up lock |
| `data/logs/<kind>/$emitter/$receiver/YYYY/MM/DD/…` | Structured wrap traces |
| `data/cwt/loop/` | Loop unit registry (generated / local) |

## Commands

```bash
make lt e:<entry>
make ll e:<entry> [args…]
make lc e:1:a e:2:b
make ls e:1:a e:2:b
make lb e:a e:b
make lp e:a e:b
make thread-list
make thread-status e:<entry>
make loop-status
make log-rotate
make log-rotate e:<entry>
```

## Retry + pile-up

- Inner retry: `CWT_WRAP_RETRY_MAX` / `CWT_WRAP_RETRY_DELAY` (default off).
- Same entry: flock skip if PID alive; stale reclaim via `kill -0` fail.
- Cross-entry parallel stays free (`thread-batch`, `lb`).

## Sudo + noninteractive

- Wrappers never call `sudo`; EUID inherited from outer `sudo make …`.
- Wrapped children get stdin `/dev/null` and `CWT_WRAP_NONINTERACTIVE=1`.
- `@requires interactive` / `@requires sudoing` (without root) refuse wrap.

## Emitter / receiver

`$emitter` = launcher kind (`manual`, `cron`, `lt`, `ll`, `chain`, `parallel`, …).  
`$receiver` = target entry or join label.  
Exports: `CWT_WRAP_EMITTER`, `CWT_WRAP_RECEIVER`, `CWT_WRAP_KIND`.

## Chooser

| Need | Use |
|------|-----|
| One background job | `make lt e:…` |
| Long-running / restart | `make ll e:…` |
| Ordered pipeline | `make chain` / `lc` / `ls` |
| Concurrent fan-out | `make lb` |
| Stdout → stdin | `make pipe` / `lp` |
