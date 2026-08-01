# Autonomous `bd ready` sweep, 2026-08-01

Session brief: work the ready queue autonomously until dry or genuinely blocked;
check every candidate against existing branches/PRs before claiming; worktree +
branch + tests + PR per task; do not merge, do not decide product questions, do
not touch history.

The queue did not go dry and could not have.

## Correction, added before this report landed: I surveyed a truncated queue

I wrote most of this having triaged "the 100 ready beads." **`bd ready` silently
caps its output at 100.** The real figure is 362:

| command | result |
|---|---:|
| `bd ready --json` | 100 |
| `bd ready --limit 0 --json` | **362** (P1: 61, P2: 203, P3: 95, P4: 3) |

I found this only because a parallel session hit it independently today, opened
maphew/mybd#27, and I read their report while checking whether our PR titles
collided. They had already filed it upstream as gastownhall/beads#5102, and
`mybd-5vf6r` records two earlier sessions making the same mistake on 07-26/27.
That makes at least four of us, which is the actual argument for the fix: the
cap is invisible to exactly the consumers who cannot notice it, since #3243's
prior art is tty-gated and every agent reads the piped or `--json` path.

What this does and does not invalidate:

- **The 97 verdicts below stand.** Those beads were triaged on their merits.
- **The framing does not.** The first 100 rows are essentially the whole P1
  band, and P1 in this repo is overwhelmingly owner-decision work, upstream
  campaigns, and PR-shepherding tails. So "three quarters of the queue is not
  actionable" is a true statement about *P1*, not about the queue.
- **203 P2 beads were never surveyed by me at all** — and per the parallel
  session, that band is where the contained, self-contained code tasks live;
  two of their three tasks came from beyond row 100.

I have left the original section below as written, retitled, rather than
quietly restating it — the mistake is the more useful artifact.

## The P1 band is not 100 items of work

Triaged all 100 rows that `bd ready` returned — which, per the correction
above, is the P1 band and not the queue — across eight parallel agents, each required to check for
covering work by path (`git log --all --since=5.days -- <path>`), by branch
subject, and by upstream PR state before calling anything actionable. 97
verdicts came back (three agents dropped one bead each — `mybd-lfos`,
`mybd-l60g`, `mybd-ae0n` — they remain untriaged and are noted below):

| verdict | count | what it means |
|---|---:|---|
| OWNER_GATED | 45 | needs a human product/policy call, or an outward-facing act toward a third party (close/decline someone's PR, post upstream, adopt-or-not), or an environment we do not have |
| TOO_BIG | 26 | real engineering, but epic-sized or design-first |
| COVERED | 11 | already has a branch, an open PR, or another in-progress bead |
| STALE | 9 | premise claimed already resolved; needs closing, not doing |
| ACTIONABLE | 6 | self-contained change implementable in one sitting |

**Roughly three quarters of the P1 band is not ready in the sense a fresh agent
assumes**, and 45 of the 100 are waiting on one person. That is a queue-shape
problem rather than a backlog-size problem: an agent that surveys P1 and
concludes "there is no actionable autonomous work here" is drawing a locally
correct conclusion. Combined with the truncation above, the two failures
compound — the cap hands you the band least likely to contain actionable work,
and then tells you it is the whole queue.

The `ready-lanes` split already addresses volume; this is a different axis —
*disposition*. `mybd-e9ipq` (in progress) converts prose/label human-gating into
first-class gates, which would take these out of `bd ready` entirely.

## Adversarial verification changed 5 of 9 answers

The 9 STALE claims were each handed to an independent verifier told to **refute**
them, with the repo's own measured ~30% false-positive rate on "fixed upstream"
recon quoted at them.

**4 confirmed, 5 refuted — a 56% refutation rate.** Had the triage pass been
trusted directly, five beads describing live bugs would have been closed.

The refutations are worth reading as a class, because they failed in five
different ways and only one would have been caught by checking that the cited
commit exists:

- **`mybd-ghh34`** — cited fix `bb455959d` is genuinely on `upstream/main`, but
  it is an ancestor of the *reporter's own binary*, so "the fix predates the
  report" was evidence **against** staleness. It also fixes the wrong store:
  the tolerance lives on `(*DoltStore).CommitWithConfig`, while bootstrap always
  gets `(*EmbeddedDoltStore)`, which has none. The reported error string
  reconstructs byte-for-byte through the embedded path and *not* the server path
  — which is independent proof of which store the reporter hit. **This one is a
  live, root-caused, unfixed bug**; split out as `mybd-p9a1o` (P1).
- **`mybd-lvss`** — the subtlest. The supporting evidence was commit
  `4ae4a81c4`, whose subject named `#4356`. That commit is **not** on
  `upstream/main`: it is the pre-squash commit, and the squashed merge title
  that landed dropped the reference. PR #5190 closes `#5033` only, and its body
  says "Same root cause as #4356" — deliberately not "Fixes". `#4356` has an
  independent second-fleet confirmation from 2026-07-26.
- **`mybd-o4wzj`** — cited commit real and on main, but the entire fix is gated
  behind two environment variables (`shouldPersistResolvedPortFile`), so it
  addresses a different trigger than the one reported.
- **`mybd-vvhu`** — cited PRs merged, but #4893 fixes a TOCTOU in the
  `is_blocked` *guard*, not write durability; the CAS in #4911 is opt-in and
  `cmd/bd/close.go:156` does not use it.
- **`mybd-ztve`** — half true. One acceptance criterion is met; the actual
  integrity concern is not.

All five refutations are recorded on the beads themselves, with the specific
counter-evidence, so the next session does not re-derive them.

The 4 confirmed closes: `mybd-ltbf2`, `mybd-98c3`, `mybd-xwgrd`, `mybd-3tch4`.
Two carry corrections to their own premise — `mybd-98c3` was **not** a flake (a
5s deadline widened to 60s in #5039), and `mybd-xwgrd`'s upstream issue is
unclosed rather than unfixed (both reproductions ran on v1.0.4, predating the
v1.0.5 fix). Closing `mybd-3tch4` would have dropped three live items on the
floor, so `mybd-f5mz7` was filed first.

No upstream GitHub issue was closed. Those are outward-facing and left to the owner.

## Shipped

Four PRs, each with tests, none merged.

**maphew/mybd#28 — `reap-test-debris` lane** (`mybd-avwqg` part b). Twice this
host accumulated ~10h-old `dolt sql-server` processes holding ~4 GB of tmpfs,
which here is RAM. Nothing on the machine could ever have reaped them, and that
is structural: the parent-death guard is deliberately unarmed for `cmd/bd`, and
`SweepOrphanedTestServers` only reaps a live server whose cwd is under a root
the *caller* vouches for — a later run gets a fresh random root, so a previous
run's orphans match nothing. The lane vouches for a root the test suite alone
creates.

Adversarial review of that script found a **blocker I had written in**: it
spared a live run's *server* at 4h and then handed that run's temp tree to
`clean-test-tmp.sh`, whose own floor is 30 minutes — 8x looser. Sparing the
process and deleting its working directory is worse than doing nothing, because
the suite then fails in a way nobody can attribute. Also found: the lane scanned
`/tmp` only, while `verify-next` redirects the suite's `TMPDIR` to
`/var/tmp/verify-gotmp` — so it would have missed the host's main *unattended*
producer of the very debris it exists for. That directory holds leftovers today.
Eleven findings in total, all fixed; suite went 19 → 32 cases.

**maphew/mybd#29 — single-babysitter designation** (`mybd-jgxt`). The
"designate Linux, do not port" decision was made 2026-07-24 and never carried
out. `pr-handoff` warned about an inactive `pr-babysit.timer` on hosts that have
no `systemctl` at all; and the designation created a sync gap nothing closed —
a handoff enqueued elsewhere was invisible to the patrol until a human pulled,
which is the manual step the pattern exists to remove. Adds a guarded
`bd dolt pull` inside the flock the pass already holds. Six new hermetic cases,
verified to fail against the pre-change scripts.

**maphew/mybd#30 — `.gitignore` gate lock.** One line plus one. `bd`'s
workspacegate writes `.beads.gate.lock` beside `.beads`, and `bd doctor` lists
`*.gate.lock*` for that reason; this repo's `.gitignore` predates it, so the
lock has sat untracked in `git status` since 2026-07-31.

**gastownhall/beads — prepared-DML migration hygiene** (`mybd-p8i3`).
`cli_migrations.go` documented the Dolt CLI batch-path limitation as being about
"some prepared ALTER TABLE statements"; per dolthub/dolt#11345 it applies to any
prepared DML. Broadens the comment and adds Check E to
`check-migration-hygiene.sh`.

Three rounds of cross-vendor (Codex) review, each finding something the last did
not, and all three were real:

1. The check **rejected the very pattern its own failure message recommends** —
   0059's `INSERT INTO __bd_0059_*` stand-in writes would have been flagged.
2. It scanned `.down.sql`, which can never meet this bug (only `*.up.sql` is
   embedded into the bundle).
3. The resulting stand-in exemption then checked only the *first* DML target, so
   `SET @sql = IF(cond, '<stand-in write>', '<real write>')` was waved through
   on the strength of the branch that was not the problem. Reproduced before
   fixing.

Round 3 is the one worth remembering: it is a false negative *created by* the
fix for round 1, in a shape reachable by combining the recommended pattern with
an ordinary one. A single review pass would have shipped it.

One further correction, mine rather than the reviewer's: seven shipped migrations
already use the flagged idiom. That is not a latent bug and the docs now say why
— a shipped migration is frozen, and on the only path the check concerns (the
fresh-schema bundle, i.e. an empty database) a data backfill is a no-op whether
or not the prepared write lands. Without that paragraph the obvious reviewer
question ("then why don't the existing ones fail?") has no answer in the tree.

## Deliberately not done

- **`mybd-jrbuu`** (conditional-blocks gating) — triaged ACTIONABLE, and the
  triage agent argued its `human-decision` label should be reconsidered. It is
  still labelled `human-decision`, and conditional-blocks semantics is a product
  question. Left alone. If the owner agrees the semantics were already settled,
  the implementation is well-specified and small.
- **`mybd-2w2kx`** (per-repo `issue_prefix` in shared-server mode) — a real
  divergence, but "which prefix wins" is a contract decision, and the triage
  confidence was medium.
- **`mybd-n8an7`** (absorb slices from PR 4682) — absorbing a third party's
  work with attribution is an outward-facing maintainer act.
- **The 45 OWNER_GATED and 26 TOO_BIG beads**, by definition.

## Loose ends for the next session

0. **Survey the P2 band.** 203 ready P2 beads have had no triage pass from this
   session, and the parallel session's evidence is that this is where the
   actionable code work is. Use `bd ready --limit 0`, never a bare `bd ready`.
1. `mybd-p9a1o` (P1) is the most valuable thing this session produced and no PR
   exists for it. It is root-caused to a specific line with byte-for-byte error
   reconstruction; the only open question is a semantics call between two fix
   shapes, recorded in the bead's design field.
2. `mybd-lfos`, `mybd-l60g`, `mybd-ae0n` were dropped by the triage fan-out and
   have no verdict.
3. `feat/lane-unit-drift` (another session's, bead `mybd-fbr7z`, pushed) is
   still unlanded. Checked for interaction with the new lane: its detector
   reports an uninstalled opt-in unit as `absent`, not drift, so
   `reap-test-debris.timer` will not generate a standing false warning.
4. The `reap-test-debris` timer is **not installed**. `scripts/install-reap-test-debris`
   is opt-in, matching `install-verify-babysit`.
5. 45 beads carry `solo-sweep:proposed` and are waiting on `mybd-lvzry`. Given a
   56% refutation rate on nine hand-picked claims this session, that batch
   should not be bulk-accepted.

## What I noticed that is not on any list

**Two beads tracked the same PR from opposite ends and neither knew.** `mybd-tgdx`
(issue side) and `mybd-isc6` (PR side) both cover gastownhall/beads#4449, both
carry a prior session's note saying so, and both are still open and still
separately ready. Prose noticing is not deduplication.

**The queue's oldest items are its most-touched.** Several P1 beads carry four or
five dated investigation notes across as many sessions and remain open, because
every session that reaches them correctly concludes the remaining step is the
owner's. Each re-investigation costs a full recon pass. A `blocked-on-owner`
state that removed them from `bd ready` would save more agent budget than any
speedup, and `mybd-e9ipq` (in progress) appears to be exactly that work.

**`main` moved twice underneath this session** — once mid-triage, once while a
worktree was being created — both from a parallel session landing directly. The
convention held; noting it as evidence that "assume you are not working alone"
is a live constraint here, not a slogan.

---

_Report by claude-opus-5-high on behalf of maphew._

_Per AGENTS.md this report would normally land direct to `main` rather than via
PR; the session brief said not to merge, so it is on a branch._
