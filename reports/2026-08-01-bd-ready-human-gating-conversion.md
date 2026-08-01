# `bd ready` was 387 items and roughly 52 of them were not claimable

2026-08-01 · bead mybd-e9ipq

## The complaint

`bd ready` is full of human-gated items, so they are not actually ready.

## What was actually true

The queue was honest about *dependencies* and silent about everything else.
`bd ready` listed 387 issues. Composition at the start of the session:

| Slice | Count | Claimable by an agent? |
|---|---|---|
| Human-decision labels | 36 | No |
| Triage stubs (`tri:claim`) | 87 | No — inbox, not work |
| `solo-sweep:proposed` | 40 | No — explicitly owner judgment |
| `tri:needs-info` / `tri:stale` | 30 | No |
| `review-needed` | 28 | Yes (patrol lane feeds it) |
| Epics (containers) | 6 | No |
| Remainder | 207 | Mostly yes; ~16 gated only in prose |

Two distinct defects, and the second is the one that mattered:

1. **Human-gating was written in three spellings and nothing read any of them.**
   `tri:human` (22), `human` (14), `human-decision` (3). No consumer filtered on
   them for readiness purposes, so they were documentation, not control.

2. **bd has a first-class gating primitive and we had used it zero times.**
   `bd gate list` returned *"No gates found."* `bd ready` is documented to
   exclude `blocked`, `deferred`, and `hooked` issues — the queue would have
   been honest by construction if the gates had existed.

A third, smaller shape: ~16 beads recorded their gate only in prose, e.g.
`mybd-fezwm` ("if halaprix does not reply by 2026-08-04"), `mybd-dodi9`
(title literally begins `OWNER DECISION:`), `mybd-buds` ("gated on 2 bug
fixes"). AGENTS.md's cold-start self-ask already covers this case — *"Does any
bead say 'after / gated-on / once X lands' in prose but lack a dependency
edge?"* — so the prompt existed and the encoding simply did not follow it.

## What was done

52 candidates (36 label-gated + 16 prose-gated) were dumped to JSON once and
classified by 8 parallel agents, with every non-trivial proposal put through an
adversarial verifier instructed to refute. bd was never called from inside the
workflow, which kept bd/Dolt serial as this repo requires; all mutations were
applied afterwards from the orchestrator, one at a time.

Verdicts: 27 `none`, 23 `gate-human`, 1 `dep-edge`, 1 `defer-until`.

Applied: **23 human gates** (`bd gate create --type=human --blocks <id>`) and
**1 defer** (`mybd-fezwm --until=2026-08-04`, which now returns to the queue by
itself on the deadline it had been describing in prose).

`bd ready`: **387 → 360.** Gate beads do not leak into the queue.

## Three things the process got wrong, and one it got right

**The verify pass earned its keep.** It overturned real proposals, not just
rubber-stamped them: `mybd-p9f0` gate→none (the "decision" quoted was the
generic triage-stub boilerplate present in *every* `tri:` stub — gating on it
would have gated the entire triage backlog), `mybd-mznh` dep-edge→none (the
cited bead was a consolidation parent, not a blocker, and the bead carries its
own runnable repro).

**The classifier told me to drop 21 labels. That would have broken two lanes.**
Every conversion proposal came back with `drop_label: true`, on the reasoning
that a gate makes the label redundant. It is not redundant — three live
consumers read it:

- `scripts/solo-sweep:251-252` **excludes** `human`/`tri:human` from the
  unattended lane's candidate pool
- `scripts/tri-daily:91` counts open `tri:human` as the standing owner nag
- `scripts/solo-bd:34` protects the labels from lane writes

Dropping them would have simultaneously broken the nag counter and pointed
solo-sweep *at* the human-gated beads. No labels were removed. **Labels are
triage provenance; gates are the filter.** They are not the same axis and
collapsing them is a mistake that looks like tidying.

**The agents could not see bd state, and it cost one conversion.** The single
`dep-edge` proposal (`mybd-sc70` → `mybd-rqqa2`) was verified as correct by an
adversarial pass that checked the blocker id "literally appears in the text" —
which it does. But `mybd-rqqa2` is **closed**, so the edge would have been a
no-op. Feeding agents a JSON dump is what kept bd serial, and it is also
precisely what blinded them to the live status of every id they reasoned about.
The check "does this id appear in the text" is not the check that matters; "is
this id open" is, and no agent in the run could perform it. `mybd-sc70` got a
note instead of an edge.

**Under-gating was chosen deliberately and it shows.** The classifier was told
to prefer `none` when uncertain, because a false gate hides real work
indefinitely while a false `none` costs one agent a wasted look. 15 beads with
human-family labels remain in `bd ready` as a result, and at least two of them
(`mybd-7kcg` "Decide list-path projection surface", `mybd-8t40o` P4 "The
philosophical foundation for what you're building") read as genuine
under-gating rather than stale labels. This is the intended direction of error,
not an accident — but it is unfinished, and it is filed rather than hidden.

## What is left

- **mybd-0nhi5** — the 15 stale-label-or-under-gated beads above.
- **mybd-porx8** — triage stubs (87 `tri:claim` + 22 `needs-info` + 8 `stale`,
  the single largest slice of the queue) sit in `bd ready` because "open with no
  blockers" is true of them. They are not gated; they are un-triaged. Open
  question: should a triage stub be `status=open` at all?
- **mybd-yw7pm** — 6 epics appear beside their own children; 4 have open
  children (`mybd-xmx7` has 9). Workaround `bd ready --exclude-type epic`.
  Separately: `mybd-9i93` and `mybd-t8l8` have zero open children and are
  probably closable.
- **mybd-sc70** — consolidation target closed; needs one look to decide whether
  it is done or genuinely ready.

The `--exclude-label` bandage floated at the start of the session was
deliberately **not** adopted. It would have made the *view* honest while leaving
the *data* wrong, and every other consumer — `bd ready --claim`, the patrol
lanes, any cold agent that just runs `bd ready` — would have kept seeing 387.

## Convention going forward

Stored as bd memory `human-gating-uses-bd-gates` (surfaced at `bd prime`, which
is on the cold-start path; this report is not).

| Situation | Encoding |
|---|---|
| Needs the owner's call | `bd gate create --type=human --blocks <id> -r "<the decision>"` |
| Date / reply deadline | `bd defer <id> --until=YYYY-MM-DD` (auto-returns) |
| Waiting on a PR | `bd gate create --type=gh:pr --blocks <id> --await-id=N` |
| "after X lands" | `bd dep add <id> <blocker>` |

`bd gate check` auto-resolves the timer and PR kinds; `bd ready --gated` surfaces
molecules whose gate just closed. That is the whole point of moving off labels:
a gate reopens itself, a label never does.
