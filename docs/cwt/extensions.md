# Extensions

Any folder in `cwt/extensions/` is a CWT extension (not their subfolders). Project-specific code uses the same shape under `scripts/cwt/extend/`.

## Enable / disable

Core ships [`cwt/extensions/.cwt_extensions_ignore`](../../cwt/extensions/.cwt_extensions_ignore) (default exclusions). Override by copying to `scripts/cwt/override/.cwt_extensions_ignore` and editing (one folder name per line to disable; delete the line to enable). An empty override file means “enable all extensions”.

If present, these take precedence (in order):

1. `scripts/cwt/override/.${PROVISION_USING}.cwt_extensions_ignore`
2. `scripts/cwt/override/.${INSTANCE_DOMAIN}.cwt_extensions_ignore`
3. `scripts/cwt/override/.cwt_extensions_ignore`

With the stock core ignore list, **`file_registry`** is typically the only bundled extension left enabled (everything else is listed). Confirm on your instance after `make reinit`.

## Overrides

If a counterpart exists under `scripts/cwt/override/`, it replaces the original (`cwt/` → `scripts/cwt/override/`). Convenience: ignore file at `scripts/cwt/override/.cwt_extensions_ignore` (not under `override/extensions/`).

See [`scripts/cwt/override/README.md`](../../scripts/cwt/override/README.md) and [`scripts/cwt/extend/README.md`](../../scripts/cwt/extend/README.md).

## Extension conventions

- After init, any `make.mk` inside an enabled extension folder is included via `CWT_MAKE_INC`.
- Any `global.vars.sh` is aggregated during instance init.
- Includes: eager `*.inc.sh` vs lazy `*.opt-inc.sh` — see [bootstrap.md](bootstrap.md) and [`cwt/extensions/README.md`](../../cwt/extensions/README.md).

## Optional extension families (brief)

| Extension(s) | Role |
|--------------|------|
| `compose` | Docker Compose stack ops (renamed from `docker-compose`; hook dual-compat still accepts both tokens) |
| `db` / `mysql` / `pgsql` | Abstract DB + drivers |
| `drupalwt` / `drupalwt_d4d` / `drush` | Drupal tooling |
| `builder` / `memory` | Stub template / storage APIs — [builder.md](builder.md) |
| `cognition` / `transcription` | observe/recognize stubs; ASR `transcribe` |
| `gpt` / `ollama` | LLM abstracts + Ollama hooks |
| `nested_cwt` | Virgin-env nested instances — [nested-cwt.md](nested-cwt.md) |
| `remote*` / `remote_traefik` | SSH sync, DB dumps, Traefik |
| `crontab` / `hosts_file` / `software` | Host jobs, `/etc/hosts`, packages |
| `file_registry` | Default registry backend (usually enabled) |
| `git_crypt` | Opt-in encryption hooks (stub / ignored by default) |

Per-extension notes: [`cwt/extensions/README.md`](../../cwt/extensions/README.md). Drupal getting started: [`cwt/extensions/drupalwt/README.md`](../../cwt/extensions/drupalwt/README.md).
