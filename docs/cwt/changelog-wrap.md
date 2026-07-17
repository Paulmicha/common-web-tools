# Changelog wrap

Layer-3 contract for durable CRUD history sidecars. Script: [`cwt/changelog/wrap.sh`](../../cwt/changelog/wrap.sh).

**Status:** header / SoT paths are documented in the script; the shared wrap **body is still TODO** (`# TODO` in the file). Log already maintains an ad-hoc `.changelog.txt` sidecar in places; other writers are expected to migrate to this shared wrap when implemented.

## Intended primary → sidecar map

| Primary | Sidecar |
|---------|---------|
| `data/logs/<item>.txt` | `data/logs/<item>.changelog.txt` |
| `data/loops/<item>.yml` | `data/loops/<item>.changelog.txt` |
| `data/threads/<item>.yml` | `data/threads/<item>.changelog.txt` |
| `data/cronjobs/<item>.txt` | `data/cronjobs/<item>.changelog.txt` |
| `data/<memory_store>/<entity>.yml` | `data/<memory_store>/<entity>.changelog.txt` |
| `/etc/hosts` | `/etc/hosts.changelog.txt` |

Volatile / rolling windows (planned, e.g. GPT traces) may keep several `*.NN.last_*.changelog.txt` sidecars — see the script header.

Caller slug (planned): path + args, underscore-separated, truncated (~64 chars).

## Make

When the action is registered: `make changelog-wrap` → `cwt/changelog/wrap.sh`.

## Related

- [layers.md](layers.md) (implementation layers 1–5)
- [observability.md](observability.md) (log / thread paths today)
- `cwt/log/rotate.sh` — size-rotate for flat logs; changelog sidecars should be rotated similarly when wrap is fully wired
