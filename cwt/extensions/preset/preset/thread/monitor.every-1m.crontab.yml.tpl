# Ideal: host thread monitor sweep (stale/reclaim/heal sibling index).
# Materialized by preset-write → cwt/extensions/crontab/thread/monitor.every-1m.crontab.yml
# @see changelog/2026/07/14-thread-log-wrap-retry-pileup-cron.md §3.5b
includes: crontab.defaults
enabled: true
wrap: direct
lock: skip
run: thread-monitor
