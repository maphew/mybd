# Issue sweep — theme:sync-remote (solo-sweep run 10, 2026-08-01)

Theme population has collapsed since the 2026-07-26 strategy report: 17 stubs
then, **3 open `tri:claim` stubs now** (`bd list -l theme:sync-remote
--status=open`). Three more are `tri:defer` and out of a `tri:claim` sweep's
scope: mybd-rj9ow (gh 3702, Linear status mapping), mybd-9mxx6 (gh 3299, S3
checksum WARN spam), mybd-7p9i6 (gh 3619, `bd flatten` ancestry). Nothing was
left unreached; the 12-stub cap never bound.

All three open stubs were swept before (two on 07-30, one adjudicated 07-31).
This run is therefore a **re-verification pass**, and every disposition is
unchanged. What it did turn up is one stalled PR nobody is watching and one
stale dep edge a previous sweep proposed fixing but nobody executed.

## Dispositions

| Stub | Upstream | Proposed | Evidence (verified live 2026-08-01) |
|------|----------|----------|--------------------------------------|
| mybd-g1sl | gh 5080 — federation sync ignores add-peer credentials | **keep-open** | Fix PR 5085 `state=open, merged=false, merged_at=null`. Bug still present at `upstream/main`: `internal/storage/embeddeddolt/version_control.go:441-443`, `remoteAuthUser()` is still `return os.Getenv("DOLT_REMOTE_USER")`. |
| mybd-guvk | gh 4861 — init remote-history guard false-positives | **keep-open** | Fix PR 5136 `state=open, merged=false`, head `a77e197e6`, untouched since 07-29. Bug still present: `cmd/bd/init.go:777-778` still hardcodes `earlyRemoteHasDoltData = true` for `initSyncRemoteConfigured`, no probe. |
| mybd-co9w9 | gh 3594 — DOLT_BACKUP leaks client paths to remote servers | **keep-open** | Fix PR 3595 `state=open, draft=true, merged=false` — but **force-pushed today** at 18:03 to `3ec9caa81`. Narrowed scope still broken: `cmd/bd/backup_dolt.go:69` still calls `resolveDoltBackupURL(rawPath)`, and `clientServerShareFilesystem` appears nowhere in that file. |

Zero closes. All three are gated on contributor PRs that exist, are referenced,
and are **not merged** — the exact shape the strategy report's 30% false-positive
rate came from.

## Root-cause map

**A. Client-local auth never reaches the peer** (mybd-g1sl). `remoteAuthUser()`
resolves through `DOLT_REMOTE_USER` only; the credentials `add-peer` encrypts
and stores are never consulted. PR 5085 fixes the federation path and is
**approved**. arcaven has since stacked four more PRs answering the review
follow-ups — 5207 (routes `bd sync --remote` and `bd dolt push|pull --remote`
through `withPeerAuth`), 5214 (actionable decrypt-failure error), 5215 (warn
when a stored peer suppresses an ambient `DOLT_REMOTE_PASSWORD`), 5216
(`setFederationCredentials` env clobber). All open, all already carry PR-review
beads (mybd-cemdo, mybd-73bmm, mybd-fv4wv, mybd-ln5p1, mybd-qmi2v). **gh 5080
must not be closed on 5085 alone** — without 5207 the same bug survives in the
non-federation verbs.

**B. Guard assumes instead of probing** (mybd-guvk). `sync.remote` being set is
treated as proof of remote history; the adjacent explicit branch does call
`gitRemoteHasDoltDataRef`. PR 5136 fixes it, idle three days with a
maintainer-authored hermetic-test commit already on the branch — that usually
means it is waiting on a maintainer decision, not on the contributor.

**C. Client filesystem assumed shared with server** (mybd-co9w9). Two of three
paths were fixed upstream (3568, 4236, per the 07-31 adjudication — not
re-verified this run); the explicit `bd backup init|add|sync` path still hands a
client-absolute `file://` URL to `CALL DOLT_BACKUP` on a remote server.

A and C are the same underlying mistake at two layers: **a remote operation
assuming the client's local environment applies to the server.** Not filed as a
design bead — the two concrete fixes are already in flight, and an abstract
parent would just be a third thing to read.

## New beads

- **mybd-d90m7 (P1)** — gh 5085 has **no CI at all** on its current head.
  `check-runs` on `e87e5cbe3` returns one `skipped` run; combined status is
  `pending` with zero statuses; the speculative merge sha has zero runs. The
  previous head `8744d81db` had **30 runs, all success**. The 07-31 rebase that
  was meant to turn CI green instead removed it, ~29h ago. pr-babysit cannot
  merge a checkless PR, and the contributor's "full suite is green" comment
  describes a *local* run — so this reads mergeable and is not. Suspected
  org-fork workflow-approval gate (ArcavenAE); unverified, a read-only token
  cannot see Actions approval state.
- **mybd-42cf6 (P3)** — watch gh 3595. It is the fix for mybd-co9w9's live
  scope, it moved today, and **no bd bead referenced it** (repo-wide scan for
  "3595" hits only mybd-co9w9 and the deferred mybd-iihf). That is lane policy
  working as documented — the detector queues drafts when they flip to ready —
  but the effect is that today's rework produced no signal in bd.

## Also noticed

- **mybd-zq0dj is untriaged.** gh 5213 (arcaven, 2026-08-01) — `add-peer` upsert
  silently clears a stored sovereignty tier when `--sovereignty` is omitted. It
  is mirrored into bd but carries **no `tri:` and no `theme:` label**, so it is
  invisible to this theme's inventory. Squarely sync-remote. The next `/triage`
  run should catch it; flagged in case it does not.
- **mybd-g1sl's only dep edge still points at a CLOSED bead** (mybd-irb5m). A
  closed blocker does not block, so the stub surfaces in `bd ready` as
  independently actionable while its fix is in another lane's flight path. The
  07-30 sweep proposed re-gating it; that was never executed, while the
  equivalent fix *was* applied to mybd-guvk on 08-01. Proposed edge:
  `bd dep add mybd-g1sl mybd-cemdo`, then drop the mybd-irb5m edge.
- The tri:stale drift on mybd-g1sl (issue comment 2026-07-31T19:42) is arcaven
  correcting a paste error in the original repro fold, not a resolution.

## Confidence and caveats

- **High confidence** on all three "not merged" claims. Each was read from
  `pulls/<n>` this run with `merged=false, merged_at=null`. PR 5085's
  `merge_commit_sha` is populated (`a5e078880`) — that is GitHub's speculative
  test-merge sha on an open PR and is *not* evidence of a merge. This trap was
  flagged by the 07-30 sweep and still holds.
- **High confidence** on all three code-still-broken claims: read from
  `upstream/main` via `solo-recon show`, not from the working tree. Line numbers
  drifted from earlier sweeps (e.g. `init.go` ~728 → 777) because main moved,
  not because the code changed.
- **Unverified, stated as such:** the 07-31 adjudication's claim that PRs 3568
  and 4236 fixed the auto-backup and push/pull paths. I re-verified only that
  the *remaining* scope is still broken.
- **Unverified cause** for mybd-d90m7: the org-fork workflow-approval theory
  fits the evidence but a read-only token cannot confirm it, and `[code]smith`
  reporting `skipped` rather than `action_required` is a loose end. The *facts*
  (30 checks then, 1 skipped now) are solid; the *explanation* is a guess.
- No blocks hit: bd and the GitHub API were both reachable, no rate limiting.
  Two `solo-bd` calls were rejected for reserved-label strings ("review-needed",
  "human") appearing in prose and were reworded — worth knowing that the guard
  matches note text, not just labels.
- One self-correction: a note on mybd-co9w9 cites bead ID `mybd-hqwyi`, written
  before the bead existed. The real ID is **mybd-42cf6**; a correcting note is
  appended to that stub.

_claude-opus-5-high on behalf of maphew_
