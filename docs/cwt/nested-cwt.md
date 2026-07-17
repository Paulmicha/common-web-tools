# Nested CWT

Optional extension `nested_cwt` for listing nested CWT project instances and running commands in a **virgin env** inside them. Core-ignored by default — remove `nested_cwt` from `.cwt_extensions_ignore` to enable.

```mermaid
flowchart TD
  parent["Parent shell<br/>CWT_BS_FLAG + globals"] --> nest["nested-cwt-exec ref …"]
  nest --> envi["env -i allowlist"]
  envi --> child["Child bash<br/>cd child docroot"]
  child --> cbs[". cwt/bootstrap.sh<br/>own globals + cache"]
  cbs --> cmd["make entry / raw cmd"]
  parent -.->|no leak| child
```

| Action | Path | Make |
|--------|------|------|
| List / map layouts | `cwt/extensions/nested_cwt/nested_cwt/list.sh` | `make nested-cwt-list [ref]` |
| Virgin-env exec | `cwt/extensions/nested_cwt/nested_cwt/exec.sh` | `make nested-cwt-exec <ref> e:<entry>` |

`ref` is a short id from the instance folder name. On name collisions, qualify with parent folders. Absolute paths still work.

| Form after `<ref>` | Behavior |
|--------------------|----------|
| `<make-entry>` / `e:<make-entry>` | Nested `make <entry> …` (`e:` when calling via `make`) |
| Path-like (`/`, `./`, `../`, ends `.sh`, …) | Raw in child — no make wrap |
| `-- <cmd…>` | Explicit raw command |

```bash
make nested-cwt-list
make nested-cwt-exec <ref> e:reinit
make nested-cwt-exec <ref> -- git status
```

Shared helpers: `nested_cwt.opt-inc.sh` (lazy via bootstrap phase 90). Prefer nested exec over sourcing another instance’s `global.vars.sh` in the parent shell.

Related recursion elsewhere (bounded):

- Hook variant subsequences — `u_str_subsequences` ([hooks.md](hooks.md))
- Token replacement — `u_str_convert_tokens` (max depth guard)

SoT: `cwt/extensions/nested_cwt/`, [`cwt/extensions/README.md`](../../cwt/extensions/README.md).
