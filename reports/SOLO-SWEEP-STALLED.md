# solo-sweep lane STALLED

- **when:** 2026-07-30T05:36:55Z
- **run:** 2
- **theme:** concurrency
- **reason:** HEAD moved during the run; nothing committed

The lane has stopped and will not fire again until re-armed.
Nothing was committed for the failed run.

- investigate: `/var/home/matt/.local/state/mybd/solo-sweep/transcripts/2026-07-30-concurrency-run2.log`
- resume: `scripts/install-solo-sweep --days N`
- stand down: `scripts/install-solo-sweep --disarm`
