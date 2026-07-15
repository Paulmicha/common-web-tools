# Ideal: nightly size-based rotate of data/logs/*.txt via make log-rotate.
# Materialized by preset-write → cwt/extensions/crontab/log/rotate.at-03h00.crontab.yml
# @see changelog/2026/07/14-thread-log-wrap-retry-pileup-cron.md §3.5a
includes: crontab.defaults
enabled: true
wrap: direct
lock: skip
