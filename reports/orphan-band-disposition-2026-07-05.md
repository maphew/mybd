# Orphan-band disposition decision - 2026-07-05 (bead mybd-ufzk)

The shed-vs-salvage decision on the 54 still-open PRs from the former "orphaned" band
(inventory: [orphaned-pr-inventory-2026-07-05.md](orphaned-pr-inventory-2026-07-05.md), premise
corrected by [reroot-investigation-2026-07-05.md](reroot-investigation-2026-07-05.md): these are
ordinary stale PRs, 411-1006 commits behind, all with valid merge-bases).

## Decision: salvage the band. Zero new closes.

Of the original 70, 13 were closed-with-credit on 2026-07-05, #3786 has since **merged on its
own**, and #3838 closed in favor of reimplementation #4579. All 54 still open carry live,
verified contributor value. A fresh 54-agent thread-state triage (this session) found **no new
close candidates**: the one agent recommendation to close (#3922) was an artifact of the void
re-root framing and was overridden to absorb.

Disposition is by queue:

| Queue | Count | Meaning |
|---|---|---|
| A - merge now (demoted to fix-merge chain, see below) | 3 | MERGEABLE, green CI, favorable posted verdict - but local stacked validation found semantic drift; land serially via branch updates (mybd-8chd.11) |
| B - maintainer absorb | 44 | fix-merge on the contributor branch (maintainerCanModify) or cherry-pick with Co-authored-by; includes 1 reimplement-fresh (#3774) and 1 sequenced-behind-#4034 (#4035) |
| C - contributor rebase | 1 | author demonstrably active; offer the rebase before absorbing |
| D - await deadline 2026-07-19 | 4 | unanswered maintainer ask; absorb or close after the deadline |
| E - owner decision | 2 | genuine design calls, routed to a human bead |

Plus #3803, already dispositioned: closes with credit when maphew's reimplementation #4580
(open, MERGEABLE) merges - tracked by mybd-r0n1.

## Execution structure (epic mybd-8chd)

| Bead | Cluster | PRs |
|---|---|---|
| mybd-8chd.1 | Windows test-hardening | #3797 #3801 #3802 #3806 #3812 |
| mybd-8chd.2 | Linear sync | #3759 #3772 #3776(C) #3789 #3930 #4119 |
| mybd-8chd.3 | dolt/storage | #3548 #3563 #3564 #3618 #3875 #4022 #4034(+#4035) #4095 #4104 #4133; D: #3837 #4029 |
| mybd-8chd.4 | CLI/UX | #3694 #3744 #4030 #4057 #4058 #4129; #3774 reimplement; D: #3777 |
| mybd-8chd.5 | formula | #4081 then close #4056 with credit; #3781; D: #3874 |
| mybd-8chd.6 | docs + nix | #3913 #3922 #4101 #3910 #4054 |
| mybd-8chd.7 | tests-infra | #3904 #3987 #4100 |
| mybd-8chd.8 | telemetry pair | #3858 then #3859 |
| mybd-8chd.9 | doctor + graph-viewer | #3758 #4117 |
| mybd-8chd.10 | owner decisions (human) | #3612, #3876 |
| mybd-8chd.11 | Queue A serial fix-merge chain | #3734 then #3770 then #3771 |

#3640 stays with pre-existing bead mybd-abd; #3803 with mybd-r0n1.

## Queue A outcome (this session)

Local stacked-merge validation (all three touch `cmd/bd/close.go`) **vetoed the blind merges**
and demoted Queue A to a serial fix-merge chain, now tracked by mybd-8chd.11:

- **#3734**: merges textually clean, but the build breaks against current main - upstream
  commit `0c0039b02` added `cmd/bd/close_proxied_server.go` after the PR's base, and it still
  calls the 3-arg `validateIssueClosable` that the PR widens to 4 args. GitHub's MERGEABLE flag
  and green (May-era) CI hide this entirely. Action this session: maintainer branch-update +
  call-site fix pushed to quad341's branch (maintainerCanModify) - merge commit `7589c68` plus
  fix `109773084`, build + targeted Close/validation tests green locally, explanation comment
  posted and signed. Merge (squash) when the refreshed CI is green.
- **#3770 / #3771**: merge cleanly and introduce no breakage of their own, but inherit #3734's
  break when stacked and share the same stale base. They follow serially after #3734 lands,
  each with a branch update + local validation first.
- Baseline sanity: clean `upstream/main` (c4e51986b) builds fine with the same flags, so the
  breakage is purely merge-induced.

**Band-wide lesson**: for PRs 400-1000 commits behind, MERGEABLE + green CI is necessary but
not sufficient - every absorb in epic mybd-8chd gets a local merge-build-test gate before any
upstream action.

## Notable per-PR facts surfaced by the triage

- **#3786 merged upstream on 2026-07-05** without any local action - evidence that the band is
  live and rebaseable, exactly as the corrected premise predicts.
- **#4056 vs #4081**: same fix (Formula `Intent` field). #4081 is quad341's cherry-pick of
  Dev-KVN's #4056 and is MERGEABLE with green CI. The #4056 thread contains fake/retracted bot
  supersession comments (one admits it was "posted in error by an automated agent"); the
  disposition ignores that noise. Land #4081, then close #4056 crediting Dev-KVN.
- **#4035**'s disputed REQUEST-CHANGES review was formally retracted by its poster (quad341) as
  an unauthorized automated post; the real gate is sequencing behind stacked #4034.
- **#3876** is self-blocked by its author on the cross-repo design decision
  gastownhall/gascity#2947 (on_complete vs Gas City drain primitive).
- **#3612** is blocked on maphew's own 2026-05-10 design question: do cross-rig dependency
  placeholders leak orchestration-layer concepts into beads core? (Charter: route orchestration
  policy outside core.)
- Six kevglynn PRs benefit from an active, responsive author (full repros supplied same-day or
  within days on #3771 #3772 #3774 #3776 #3744-adjacent asks); #3776 is the one where asking for
  a rebase is cheaper than absorbing.
- The 2026-06-16 codex repro-request sweep misfired on some feature-style PRs (#4056, #4035):
  templated bug-repro asks that don't apply to the content. Those asks were treated as noise,
  not as open gates.

## Full disposition matrix (54 PRs)

| PR | Author | Queue | Disposition | Cluster | Rationale (trimmed) |
|---|---|---|---|---|---|
| [#3734](https://github.com/gastownhall/beads/pull/3734) | quad341 | A-merge-now | merge-now | cli-ux | Real authority-check bug (silent data loss on bd close when actor mismatches assignee), already verified absent from main, green CI, maintainer verdict explicitly recommends merge, |
| [#3770](https://github.com/gastownhall/beads/pull/3770) | idvorkin-ai-tools | A-merge-now | merge-now | other | Maintainer (maphew) posted explicit merge verdict with full technical verification on 2026-07-05; all CI green; small, well-scoped fix for documented daily-impact bug; no open asks |
| [#3771](https://github.com/gastownhall/beads/pull/3771) | kevglynn | A-merge-now | merge-now | cli-ux | Small, self-contained UX safety fix with all CI green, inventory high-confidence assessment, contributor responsive to maintainer's repro request, and linked issue #3681 still open |
| [#4035](https://github.com/gastownhall/beads/pull/4035) | Ethee | B-absorb-after-4034 | escalate | dolt-storage | No authoritative maintainer verdict exists (the one retracted review was disavowed as unauthorized, and maphew's 2026-06-16 comment reads as a generic repro request rather than a d |
| [#3548](https://github.com/gastownhall/beads/pull/3548) | kingfly55 | B-maintainer-absorb | cherry-pick | dolt-storage | Inventory rates this a small, self-contained, test-backed primitive worth reimplementing rather than merging the orphan branch (which is now CONFLICTING with ~400-1000 commits of d |
| [#3563](https://github.com/gastownhall/beads/pull/3563) | shaunc | B-maintainer-absorb | cherry-pick | dolt-storage | Real dolt-storage fix for host-config server-mode inference not present on main; PR is orphan branch (no common ancestor). Maintainer directs cherry-pick via fresh reimplementation |
| [#3564](https://github.com/gastownhall/beads/pull/3564) | shaunc | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Positive maintainer verdict on a small, well-tested fix (enrich port-conflict error messages with docker/external-server hint). PR is mergeable and maintainer can modify. Requires  |
| [#3618](https://github.com/gastownhall/beads/pull/3618) | quad341 | B-maintainer-absorb | cherry-pick | dolt-storage | Orphan PR (no merge-base) with reviewed, valid fix for prefix-list convergence between clean-databases and firewall. Maintainer verdict posted same day directs cherry-pick (reimple |
| [#3640](https://github.com/gastownhall/beads/pull/3640) | kevglynn | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | Small, validated permission-repair fix (2 files) addressing open issue #3593. Mergeable with all CI passing. Author responsive with detailed repro. Maintainer can efficiently rebas |
| [#3694](https://github.com/gastownhall/beads/pull/3694) | abnersajr | B-maintainer-absorb | cherry-pick | cli-ux | Valuable, fully-tested unclaim command absent from main; PR is an orphan branch (no merge-base) from history rewrite, so cherry-pick/reimplement is the only viable path. Maintainer |
| [#3744](https://github.com/gastownhall/beads/pull/3744) | scotthamilton77 | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | Valid bug fix (molReadyGatedCmd missing --gated flag) confirmed by responsive contributor. Maintainer can rebase, regenerate docs (routine fixup for the flag addition), and merge.  |
| [#3758](https://github.com/gastownhall/beads/pull/3758) | daniel-jasinski | B-maintainer-absorb | maintainer-rebase-merge | doctor | Small, valuable change (salvage-feature: embedded mode support for bd doctor checks) with green CI and modest conflict scope, but author inactive 19+ days and maintainers seek repr |
| [#3759](https://github.com/gastownhall/beads/pull/3759) | aphexcx | B-maintainer-absorb | cherry-pick | linear-sync | Feature is genuine, well-tested, and absent from main. Orphaned by May 2026 history rewrite but maintainer analysis confirms 5 core files apply cleanly. Conflicts confined to gener |
| [#3772](https://github.com/gastownhall/beads/pull/3772) | kevglynn | B-maintainer-absorb | maintainer-rebase-merge | linear-sync | Inventory classifies this as a small, self-contained, still-needed fix for #3754; contributor already answered the maintainer's repro request in full but the branch is ~400-1000 co |
| [#3781](https://github.com/gastownhall/beads/pull/3781) | jjgarzella | B-maintainer-absorb | maintainer-rebase-merge | formula | Substantive, wanted feature with maintainer-approved design and passing CI; contributor inactive 2+ months; maintainer has refined and verified; rebase work is minimal given code i |
| [#3789](https://github.com/gastownhall/beads/pull/3789) | jmdaly | B-maintainer-absorb | cherry-pick | linear-sync | Maintainer has already triaged and confirmed the fix is real and correct (Jira UTC-timezone bug still live on main). Explicit verdict recommends cherry-picking or reimplementing th |
| [#3797](https://github.com/gastownhall/beads/pull/3797) | seanmartinsmith | B-maintainer-absorb | cherry-pick | windows-tests | Maintainer completed triage with explicit cherry-pick verdict on 2026-07-05. Test-only fix for Windows path canonicalization is small, well-diagnosed, has passing CI, and patch app |
| [#3801](https://github.com/gastownhall/beads/pull/3801) | seanmartinsmith | B-maintainer-absorb | cherry-pick | windows-tests | Maintainer verdict (2026-07-05) confirms real bug still live on main, recommends cherry-pick due to orphan history and file path changes (from internal/storage/db/server to interna |
| [#3802](https://github.com/gastownhall/beads/pull/3802) | seanmartinsmith | B-maintainer-absorb | cherry-pick | windows-tests | Small, well-tested Windows-specific test skip; orphan branch status requires cherry-pick or reimplement rather than direct merge. Maintainer explicitly recommended cherry-pick. Fix |
| [#3806](https://github.com/gastownhall/beads/pull/3806) | seanmartinsmith | B-maintainer-absorb | maintainer-rebase-merge | windows-tests | Valuable, small (5 test-only guards), favorable posted verdict, all CI green. Requires maintainer-performed rebase --onto (orphan branch). Contributor appears inactive post-verdict |
| [#3812](https://github.com/gastownhall/beads/pull/3812) | seanmartinsmith | B-maintainer-absorb | cherry-pick | tests-infra | Maintainer's explicit directive (2026-07-05): cherry-pick the three test changes to a new main-rooted PR. Code is sound and requires no modifications; contributor responsively answ |
| [#3858](https://github.com/gastownhall/beads/pull/3858) | GraemeF | B-maintainer-absorb | maintainer-rebase-merge | telemetry | Small, self-contained fix for real telemetry instrumentation bug still present on main. All CI passes. Contributor inactive 56+ days, but fix is valuable and maintainer-modifiable  |
| [#3859](https://github.com/gastownhall/beads/pull/3859) | GraemeF | B-maintainer-absorb | maintainer-rebase-merge | telemetry | Inventory confirms feature is absent on main and still valid (PR 2 of 3 in a telemetry OTel-env-vars series, sibling #3858 still open); no maintainer has triaged it and it now show |
| [#3875](https://github.com/gastownhall/beads/pull/3875) | jjgarzella | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Small self-contained fix for dep-type collision deduplication in cook.go's dependency handling; inventory confirms still absent from main and issue #3783 remains open. All CI passe |
| [#3904](https://github.com/gastownhall/beads/pull/3904) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | tests-infra | Small test-only consolidation (+5 LOC) with full green CI, mergeable state, and maintainer modify permission. No maintainer review or concerns posted. Stale (47 days, 411+ commits  |
| [#3910](https://github.com/gastownhall/beads/pull/3910) | harry-miller-trimble | B-maintainer-absorb | maintainer-rebase-merge | nix | Small, self-contained nix overlay feature with core-contributor approval and passing CI; conflicts require rebase but contributor (inactive since May 12) has authorized maintainer  |
| [#3913](https://github.com/gastownhall/beads/pull/3913) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | docs | Small docs-only PR (CONTRIBUTING_PR_GUIDELINES.md, 58 lines) from maintainer author quad341, mergeable with all CI green and no unresolved maintainer asks; should be rebased and me |
| [#3922](https://github.com/gastownhall/beads/pull/3922) | boardthatpowder | B-maintainer-absorb | maintainer-rebase-merge | docs | Valid documentation addition for a real tool (BeadSpec with OpenSpec integration) but 54 days stale on orphaned branch. Inventory classifies as salvage-reimplement, not mergeable-a |
| [#3930](https://github.com/gastownhall/beads/pull/3930) | aphexcx | B-maintainer-absorb | maintainer-rebase-merge | linear-sync | Feature-complete parent-reconciliation logic (9 unit tests, multi-team support) classified salvage-feature per 2026-07-05 inventory; confirmed absent from upstream/main; PR has mer |
| [#3987](https://github.com/gastownhall/beads/pull/3987) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | tests-infra | One-line timeout fix with full CI coverage and positive author review; maintainer can rebase and land decision made against unresponsive contributor (19 days silent after 2026-06-1 |
| [#4022](https://github.com/gastownhall/beads/pull/4022) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Small, approved change with explicit maintainer "merge-as-is" verdict and passing CI. Only blocker is technical conflict from May 2026 re-root (ordinary stale PR ~400+ commits behi |
| [#4030](https://github.com/gastownhall/beads/pull/4030) | shiminshen | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | Trivially correct help-text-only fix (two lines in cmd/bd/human.go), already positively reviewed, mergeable, maintainer can modify, and inventory classifies as small + cheap to lan |
| [#4034](https://github.com/gastownhall/beads/pull/4034) | Ethee | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Feature is valuable per inventory (high confidence, fixes blocking deadlock via dependency CTE) and contributor unresponsive for 19+ days. Merge conflicts present but maintainerCan |
| [#4054](https://github.com/gastownhall/beads/pull/4054) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | nix | Valuable release-prep feature (bd preflight --fix for vendorHash auto-correction and version sync) with all 41 CI checks passing and favorable author review; stale 45+ days (last a |
| [#4056](https://github.com/gastownhall/beads/pull/4056) | Dev-KVN | B-maintainer-absorb | maintainer-rebase-merge | formula | The PR is small, self-contained, MERGEABLE, and the only credible maintainer touchpoint (maphew, 2026-06-16) is a generic repro request that doesn't fit this feature-style change a |
| [#4057](https://github.com/gastownhall/beads/pull/4057) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | Approved one-line change with complete CI passing and clear maintainer verdict. Mergeable status CONFLICTING requires rebase onto re-rooted main, but code quality is settled and th |
| [#4058](https://github.com/gastownhall/beads/pull/4058) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | PR has explicit maintainer approval with all CI passing. Conflicts exist only due to re-root; the substance was already approved as merge-ready. Small, self-contained change (wire  |
| [#4081](https://github.com/gastownhall/beads/pull/4081) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | formula | PR is MERGEABLE with green CI and maintainerCanModify=true, and the inventory rates it high-confidence "salvage-small" (small, self-contained, still needed, closes #4056 cherry-pic |
| [#4095](https://github.com/gastownhall/beads/pull/4095) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Confirmed bug fix for FIFO starvation in work claiming (newest issues claimed first instead of oldest, starving older tasks). Small self-contained fix touching sqlbuild ORDER BY ac |
| [#4100](https://github.com/gastownhall/beads/pull/4100) | quad341 | B-maintainer-absorb | maintainer-rebase-merge | tests-infra | Small test-isolation fix with all CI passing, addresses real bug still present on main per 2026-07-05 inventory, contributor (Claude agents) inactive since creation, maintainer has |
| [#4101](https://github.com/gastownhall/beads/pull/4101) | prmichaelsen | B-maintainer-absorb | cherry-pick | docs | PR adds valid docs (RELATED_PROJECTS.md with scry entry, distinct from COMMUNITY_TOOLS) but is orphaned by re-root. Inventory identifies identical content in dangling commit 4ca114 |
| [#4104](https://github.com/gastownhall/beads/pull/4104) | fishgills | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Small valid perf fix (2 files) addressing open issue #4102 via errgroup parallelization; needs rebase due to staleness but maintainer can resolve conflicts since maintainerCanModif |
| [#4117](https://github.com/gastownhall/beads/pull/4117) | A3Ackerman | B-maintainer-absorb | maintainer-rebase-merge | graph-viewer | Small 54-line single-file fix (scope CSS to #graph, add fitToView) with code-verified bug confirmation; inventory classified as worth landing post-rebase; contributor inactive 20 d |
| [#4119](https://github.com/gastownhall/beads/pull/4119) | A3Ackerman | B-maintainer-absorb | maintainer-rebase-merge | linear-sync | Small (160-line), clean, well-tested feature adding opt-in linear.outbound_state_map for Linear push-side state disambiguation. Inventory (2026-07-05, high confidence) verified abs |
| [#4129](https://github.com/gastownhall/beads/pull/4129) | Zireael | B-maintainer-absorb | maintainer-rebase-merge | cli-ux | Valuable small fix (CLI help text sync + new bd types --sections flag) confirmed needed per 2026-07-05 inventory. Contributor was responsive in June but inactive 18+ days. Maintain |
| [#4133](https://github.com/gastownhall/beads/pull/4133) | Zireael | B-maintainer-absorb | maintainer-rebase-merge | dolt-storage | Inventory rates this a small, self-contained, non-superseded fix (med confidence) for an open crash issue (#4132); PR is CONFLICTING and needs a rebase, and while the contributor r |
| [#3774](https://github.com/gastownhall/beads/pull/3774) | kevglynn | B-reimplement-fresh | escalate | cli-ux | Repro was requested and fully supplied by the contributor with no maintainer follow-up, so this isn't a stale/unresponsive case for close-with-credit or contributor-rebase; but the |
| [#3776](https://github.com/gastownhall/beads/pull/3776) | kevglynn | C-contributor-rebase | contributor-rebase | linear-sync | Feature-class PR adds Linear label-push support (GetTeamLabels + label_type_map inversion + labelIds resolution) fixing unfixed bug #3753; all tests pass with green CI; maintainer' |
| [#3777](https://github.com/gastownhall/beads/pull/3777) | iuyua9 | D-await-deadline | contributor-rebase | cli-ux | Small, self-contained fix to honor deferred filters in ready-list queries (inventory: "still valid"). Contributor is responsive (pushed follow-up in May) but hasn't yet answered Ju |
| [#3837](https://github.com/gastownhall/beads/pull/3837) | ckumar1 | D-await-deadline | hold | dolt-storage | Thread has two unresolved maintainer asks (coffeegoddd's 2026-05-10/11 repro/design questions about hard-coding dolt auth error strings vs a new `bd remote auth check` command, and |
| [#3874](https://github.com/gastownhall/beads/pull/3874) | jjgarzella | D-await-deadline | hold | formula | Inventory validates the fix as sound and still needed (looksLikeFormulaName gate remains on main), all CI passes, but maintainer's explicit repro request from 2026-06-16 remains un |
| [#4029](https://github.com/gastownhall/beads/pull/4029) | quad341 | D-await-deadline | hold | dolt-storage | CI is fully green and the fix looks small/self-contained per inventory and self-reviews, but the maintainer's explicit repro request is still unanswered by the contributor and merg |
| [#3612](https://github.com/gastownhall/beads/pull/3612) | gt-rm-0306 | E-owner-decision | escalate | dolt-storage | Real correctness fix for cross-rig dependency visibility that passes all tests, but maintainer's unresolved design question about architectural layering (whether multi-rig/gastown  |
| [#3876](https://github.com/gastownhall/beads/pull/3876) | jjgarzella | E-owner-decision | escalate | formula | CI is green and mergeable=CONFLICTING is just rebase drift, but the author himself has blocked merge on an unresolved cross-repo design decision (on_complete vs Gas City drain) tra |

## Method

- Fresh state: one batched GraphQL query over all 57 inventory PRs (state, mergeability,
  latest activity) - caught #3786 MERGED.
- Thread triage: 54-agent workflow fan-out (haiku for routine threads, sonnet for the 8
  med-confidence rows, the escalate pair, and the #4056/#4081 duplicate pair), read-only,
  explicitly barred from re-reviewing code (the content review is complete per mybd-y7u0 /
  mybd-w15y / the inventory). Adversarial verify stage armed for close-with-credit
  recommendations; the single close rec (#3922) was instead overridden on inspection, so no
  closes were verified or executed.
- Caveat: a few rationale cells in the matrix still echo the void "orphan branch / no
  merge-base" framing the triage agents read in older thread comments. The operative fields are
  Queue and Disposition; "cherry-pick" and "maintainer-rebase-merge" both mean maintainer
  absorb, and the actual mechanics (rebase vs cherry-pick) get decided per PR at execution time.
- 54/54 agents returned structured rows, zero errors. Subagent usage ~1.78M total tokens
  (haiku-dominant); the workflow's own output-token spend stayed within the session's 200k
  default target.
- Queue A merges gated by `bd-main/scripts/pr-preflight.sh` plus local stacked-merge
  validation (all three touch `cmd/bd/close.go`, so they were merge-tested in sequence in a
  scratch worktree before any upstream action).

## Follow-through

- Execute clusters via epic mybd-8chd (children .1-.11). First action: merge #3734 once its
  refreshed CI is green (.11), then cheapest-first: tests-infra (.7), Windows (.1),
  docs+nix (.6).
- D-queue deadline 2026-07-19: #3837 #4029 #3777 #3874 - absorb or close after.
- mybd-ufzk closes with this report: the *decision* is made; remaining work is execution,
  tracked by mybd-8chd.
