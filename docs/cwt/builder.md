# Builder

Extension folder: `cwt/extensions/builder/` (formerly `preset`).

Listed in **core** `.cwt_extensions_ignore` by default. Remove `builder` from the project override ignore list to register stub make targets after `make reinit`. Action bodies are still `# TODO` in many places.

## Subjects (stubs)

| Subject | Path | Make (when enabled) |
|---------|------|---------------------|
| blueprint | `builder/blueprint/*.sh` | `blueprint-generate`, `blueprint-status`, … |
| blueprints | `builder/blueprints/list.sh` | `blueprints-list` |
| prototype | `builder/prototype/*.sh` | `prototype-build`, `prototype-test`, … |
| prototypes | `builder/prototypes/list.sh` | `prototypes-list` |
| template | `builder/template/*.sh` | `template-hydrate`, `template-diff`, … |
| templates | `builder/templates/list.sh` + packs | `templates-list` |

### Pack files

```text
cwt/extensions/builder/templates/
  boilerplate/…
  cwt/                 # action.tpl.sh, subject.inc.tpl.sh, action.test.sh
  services/            # app, cache, db, index, vcs
  list.sh
```

## Retired (do not use)

The previous **discover → list → write → improve** workflow under `cwt/extensions/preset/` is **gone**:

- No `make preset-discover` / `preset-list` / `preset-write` / `preset-improve`
- No `u_preset_root` / `preset.opt-inc.sh`

Same “stub subjects + packs” pattern applies to `memory` (`storage-*`, `store-*`) when that extension is enabled.

See also [`cwt/extensions/README.md`](../../cwt/extensions/README.md) and [extensions.md](extensions.md).
