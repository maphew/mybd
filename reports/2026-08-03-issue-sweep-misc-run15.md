# Issue sweep — theme:misc (solo-sweep run 15)

2026-08-03. Unattended lane. Dispositions are **proposals**; nothing was
published, closed, labeled upstream, or committed beyond this file.

## Population: the theme is drained

`theme:misc` has **one** open `tri:claim` stub, not the 22 in the strategy
report's table. That table is design-time; the 2026-07-26 reclassify pass
already folded misc down (report: "22 → 1: 18 cli-ux, 1 deps-ready, 1
migration-schema, 1 → test-ci"). This run swept the survivor. Scope allowance
was 12 stubs; the theme supplied 1, so nothing was left unreached.

Backlog context: 94 open `tri:claim` stubs remain overall.

## Dispositions

| Stub | Upstream | P | Proposed | Evidence |
|---|---|---|---|---|
| mybd-iwgn6 | [gastownhall/beads#2883](https://github.com/gastownhall/beads/issues/2883) — Full-text search including comments | P2 | **flesh-out** | Verified still unfixed at `upstream/main` b4c637c1c. Timeline has no fix commit or linked PR; `sqlbuild/filter.go` still matches only title/description/notes/external_ref, and the comments table is joined solely for the `comment_count` projection. Scope, implementation constraint, acceptance criteria, and one open design question written to the bead. |

Disposition counts: flesh-out 1, close 0, consolidate 0, keep-open 0.

## Root-cause map

One stub, so no consolidation group. The finding worth carrying forward is a
design constraint rather than a cluster:

**`bd search` has no comment-text predicate, and the obvious implementation is
wrong.** `SearchCountsSQL` (internal/storage/sqlbuild/counts.go) carries an
explicit invariant in its doc comment: the WHERE fragment may reference "only
main-table columns (or correlated subqueries against labels/deps/comments keyed
by id)", never the six projected aggregate aliases — because #4480 (21822ad72)
moved the WHERE inside a derived table so the joins drive off an already-narrowed
set. So a comment search must be a correlated `EXISTS (SELECT 1 FROM <comments>
c WHERE c.issue_id = i.id AND LOWER(c.text) LIKE ?)`. A predicate on `cc.cnt`,
or a widened join, either errors on an out-of-scope column or fans out rows.

Second, smaller trap on the same work: `cmd/bd/search_proxied_server.go` reads
the three existing `*-contains` flags onto the filter separately (~lines 53-56,
89-97). A new flag added only to the embedded path silently no-ops under a
shared server — the failure mode is "search returns nothing and looks correct".

Two commits look like fixes and are not: **#4799** (merge `3ecbf5bc9`,
"support search + 11 more commands in proxied-server mode") is transport
plumbing, and **#4480 / `21822ad72`** is a query-shape optimization. Both touch
search; neither touches comment matching. gastownhall/beads#177 ("Comments are
invisible to `show` and `edit`") is closed but is a display surface, not search.

**No new engineering bead filed.** The stub survives alone and now carries its
own repro, code paths, acceptance criteria, and open question — a second bead
would be a duplicate. The one design decision I deliberately did *not* make is
recorded on the bead: whether bare `bd search <text>` should widen to include
comments by default (the issue title implies yes; every other non-title field in
this CLI is opt-in, and widening changes result sets for every caller, agents
included). My recommendation on the bead is opt-in flag first, default-widening
as a separate call. That one is the owner's.

## Side observation (not on any list)

One open `tri:claim` stub carries **no** `theme:` label at all: `mybd-uiiu`
(gh-4380, P1, aux row re-key migration crash). It is not a raw stub any more —
per the `agent-batch-current` memory it has a staged, verify-passed, human-gated
fix — but it is invisible to every `bd list -l theme:*` sweep, including this
one. That is live evidence for **mybd-habn8** ("Add theme-labeling of new
tri:claim stubs to the /triage procedure"), which is already open; I filed
nothing new. Worth noting that theme sweeps silently under-count by however many
such stubs exist.

Operationally: **theme:misc is exhausted.** The next solo-sweep run needs a
different theme, or it will re-sweep this same bead. Per the strategy report's
ordering, the unswept bulk is `cli-ux` (runs 12-14 have been working it),
`server-mode` (34, coordinate with epic mybd-psxg), and `sync-remote`.

## Confidence and caveats

- **High confidence the issue is unfixed.** Two independent lines agree: the
  full timeline enumeration for #2883 contains no commit reference, no linked
  PR, and no fix event; and the source at `upstream/main` still lacks any
  comment-text predicate. The strategy report's 30%-false-positive failure mode
  is about *claiming a fix landed* — here I am claiming the opposite, and the
  disposition is keep-open-and-improve, so a wrong call costs an unnecessary
  read, not a closed live issue.
- **Source claims are read at `upstream/main` b4c637c1c** (fetched for this
  run). Two `grep` calls ran against the `bd-main` working tree, but only to
  locate *filenames*; every quoted line and every content claim was re-read via
  `solo-recon show beads upstream/main:…`.
- **I did not execute anything.** This lane has no build or run verb, so
  "`bd search` does not match comment text" rests on source reading plus the
  maintainer's own 2026-06-17 reproduction on 1.0.5, not on a run against
  current main. If the owner wants runtime confirmation before acting, that is
  a two-minute check and I could not do it.
- The proposed `EXISTS` shape and acceptance criteria are **design proposals
  from reading**, not a validated patch. In particular I did not verify the
  comments table's column names beyond `issue_id` / `text` (taken from the
  reporter's working SQL and the counts join), and I did not check whether the
  backend-agnostic conformance suite has a natural home for a comment-search
  case.
- Nothing was blocked. `solo-recon` refused one un-encoded `search/issues`
  endpoint form; retrying with the required `is:issue` qualifier worked. One
  `solo-bd note` was rejected for exceeding 4000 chars and was trimmed — the
  trimmed version retains all evidence, dropping only restated narration.
