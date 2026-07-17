# Sidecar wrap

Layer-3 contract for durable CRUD history sidecars. Script: [`cwt/sidecar/wrap.sh`](../../cwt/sidecar/wrap.sh).

**Status:** header / SoT paths are documented in the script; the shared wrap **body is still TODO** (`# TODO` in the file). Log already maintains an ad-hoc `.sidecar.txt` sidecar in places; other writers are expected to migrate to this shared wrap when implemented.

## Intended primary → sidecar map

| Primary | Sidecar |
|---------|---------|
| `data/logs/<item>.txt` | `data/logs/<item>.sidecar.txt` |
| `data/loops/<item>.yml` | `data/loops/<item>.sidecar.txt` |
| `data/threads/<item>.yml` | `data/threads/<item>.sidecar.txt` |
| `data/cronjobs/<item>.txt` | `data/cronjobs/<item>.sidecar.txt` |
| `data/<memory_store>/<entity>.yml` | `data/<memory_store>/<entity>.sidecar.txt` |
| `/etc/hosts` | `/etc/hosts.sidecar.txt` |

Volatile / rolling windows (planned, e.g. GPT traces) may keep several `*.NN.last_*.sidecar.txt` sidecars — see the script header.

Caller slug (planned): path + args, underscore-separated, truncated (~64 chars).

## Make

When the action is registered: `make sidecar-wrap` → `cwt/sidecar/wrap.sh`.

## Related

- [layers.md](layers.md) (implementation layers 1–5)
- [observability.md](observability.md) (log / thread paths today)
- `cwt/log/rotate.sh` — size-rotate for flat logs; sidecars should be rotated similarly when wrap is fully wired
