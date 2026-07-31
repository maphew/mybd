# `bd ready` gating audit: what the `is_blocked` recompute structurally cannot express

Bead: mybd-zelnn. Source read at `upstream/main` tip `8bb0d36be` (the bead was
filed against `84431ee5c`; nothing in the files below changed between them).

**Scope of this document.** mybd-zelnn asks for five things. This delivers
acceptance item (1) — the enumeration — and *only* the as-implemented column of
it. Items (2)–(5) require deciding what readiness *should* mean for several
classes, which is an owner call and is deliberately not made here. Every "should
it?" cell below reads **OWNER**. See "What this does not decide" at the end.

## 1. The structure, restated precisely

`bd ready` has exactly three readiness predicates. From
`internal/storage/sqlbuild/ready.go` `BuildReadyWorkWhere`:

```go
whereClauses := []string{
    statusClause,                    // default: status IN ('open','in_progress')
    "(pinned = 0 OR pinned IS NULL)",
    "is_blocked = 0",
}
```

There is no dependency join, no `parent_id`, no `depends_on_external`. Every
other clause in that function is a *user filter* (priority, type, assignee,
labels, defer, parent scope) — none of them is a readiness test.

So the entire dependency semantics of `bd ready` is whatever
`internal/storage/issueops/blocked_state.go` writes into the `is_blocked`
column. That recompute has exactly **three** arms (per table family, mirrored
for `issues`/`dependencies` and `wisps`/`wisp_dependencies`):

| # | Arm | Predicate |
|---|---|---|
| A | blocking | `d.type IN ('blocks','conditional-blocks')` AND target `status NOT IN ('closed','pinned')` |
| B | hierarchy | `d.type = 'parent-child'` AND **`p.is_blocked = 1`** |
| C | fanout gate | `d.type = 'waits-for'` AND the `waitsForGateBlockedSQL` gate expression |

`markBlockedTemplateForIssues` and `unmarkBlockedTemplateForIssues` are exact
logical complements of each other — I checked arm by arm. There is **no**
mark/unmark drift, which is worth recording because it is the first thing one
suspects. The staleness in gh 4138 comes from rows never entering a recompute
batch at all, not from asymmetric arms.

## 2. The gating table (as implemented)

"Reaches the recompute?" means: is there an arm whose `WHERE` can ever match a
row of this class. "Gates ready today?" is the observable consequence.

`bd` stores relationships through three channels: a typed row in
`dependencies`/`wisp_dependencies`; a target column choice on that row
(`depends_on_issue_id` / `depends_on_wisp_id` / `depends_on_external`); and
dotted issue IDs, which encode hierarchy with no row at all.

### 2a. Dependency types (`types.AllDependencyTypes`, 19 built-ins)

| Class | Declared intent | `AffectsReadyWork()` | Reaches recompute | Gates ready today | Should it? |
|---|---|---|---|---|---|
| `blocks` | hard blocker | true | Arm A | **Yes** — while target open | — |
| `conditional-blocks` | "B runs only if A **fails**" | true | Arm A, *identical to `blocks`* | **Yes, but wrong** — see §3.1 | OWNER |
| `parent-child` | hierarchy | true | Arm B | **Partially** — propagates parent's *flag*, not parent's *openness*; see §3.2 | OWNER |
| `waits-for` | fanout gate | true | Arm C | **Yes** — `all-children`/`any-children`, plus `also_blocks` | — |
| `related` | association | false | — | No | OWNER (likely no) |
| `discovered-from` | association | false | — | No | OWNER (likely no) |
| `replies-to` | threading | false | — | No | OWNER (likely no) |
| `relates-to` | knowledge graph | false | — | No | OWNER (likely no) |
| `duplicates` | dedup link | false | — | No | OWNER |
| `supersedes` | version chain | false | — | No | OWNER |
| `authored-by` | entity | false | — | No | OWNER (likely no) |
| `assigned-to` | entity | false | — | No | OWNER (likely no) |
| `approved-by` | entity | false | — | No | OWNER |
| `attests` | entity | false | — | No | OWNER (likely no) |
| `tracks` | convoy, "non-blocking" | false | — | No | — (intent explicit) |
| `until` | "active until target closes" | false | — | No | OWNER |
| `caused-by` | audit trail | false | — | No | OWNER (likely no) |
| `validates` | approval | false | — | No | OWNER |
| `delegated-from` | "completion cascades up" | false | — | No | OWNER — see §3.5 |

### 2b. Other storable relationship channels

| Class | Storable? | Reaches recompute | Gates ready today | Should it? |
|---|---|---|---|---|
| `depends_on_external` target (e.g. `external:proj:capability`) | Yes — first-class column, `ck_dep_one_target` | **No arm joins it** | **No** | OWNER — gh 4769 |
| Dotted-ID hierarchy with **no** `parent-child` row | Yes — and `bd` relies on it; see §3.3 | No | **No** | OWNER — gh 5036 |
| Custom dependency type (any string ≤50 chars — `IsValid()`) | Yes | No | **No**, silently | OWNER — see §3.4 |
| Wisp twins (`wisp_dependencies` → `issues` and vice versa) | Yes | Arms A/B/C are mirrored across both tables | Yes, same semantics | — |

## 3. The five structural gaps

### 3.1 `conditional-blocks` has no outcome dimension (not previously filed)

`conditional-blocks` means "B runs only if A **fails**" (`internal/types/types.go:1023`,
and `cmd/bd/mol_bond.go:567` "Conditional: use conditional-blocks (B runs only
if A fails)"). Arm A treats it byte-identically to `blocks`:

```sql
AND (d.type = 'blocks' OR d.type = 'conditional-blocks')
AND t.status <> 'closed' AND t.status <> 'pinned'
```

So B becomes ready as soon as A closes — **whether A succeeded or failed**. The
correct semantics needs A's *outcome*, and `is_blocked` is a boolean with no
place to put it. A molecule's failure branch therefore goes ready on the success
path too. This is the cleanest example of the bead's thesis: it is not a wrong
arm, it is a dimension the column cannot hold.

I did not find an existing upstream issue for this. It should be filed
regardless of how the larger question is decided.

### 3.2 The hierarchy arm propagates the wrong predicate (gh 5036)

Arm B keys on `p.is_blocked = 1`. It propagates the parent's *blocked flag*, so
a child of an **open, unblocked, incomplete** parent is ready. Meanwhile
`cmd/bd/dep.go:197` refuses an explicit blocking edge to your own dotted parent:

> `cannot add dependency: %s is already a child of %s. Children inherit
> dependency on parent completion via hierarchy. Adding an explicit dependency
> would create a deadlock`

The CLI forbids expressing the constraint on the grounds that it is implicit,
and the recompute does not implement it. Both statements cannot be true. This is
gh 5036 / mybd-y06g, and the error message is the sharpest single piece of
evidence for it.

### 3.3 Dotted-ID hierarchy is a real channel the recompute never reads

Arm B reads `dependencies` rows only. That dotted children can exist *without*
such a row is not speculation — `ready.go`'s own parent-scope filter is written
around exactly that case:

```go
fmt.Sprintf("(id LIKE CONCAT(?, '.%%') AND id NOT IN (SELECT issue_id FROM %s WHERE type = 'parent-child'))", tables.Dependencies)
```

That clause exists to catch dotted descendants that have no `parent-child` row.
So `bd`'s *filtering* path knows about row-less hierarchy and its *readiness*
path does not.

### 3.4 Custom dependency types fail open, silently

`DependencyType.IsValid()` accepts any non-empty string up to 50 characters, and
`AllDependencyTypes`/`WellKnownDependencyTypes` are advisory. A custom type is
storable, is rendered by `bd dep tree`, and can never gate ready — with no
warning at write time. Whatever is decided for the built-ins, the fail-open
default for unknown types is worth an explicit ruling.

### 3.5 `delegated-from` documents a cascade nothing implements

Its comment says "Work delegated from parent; completion cascades up". No arm
joins it and `AffectsReadyWork()` returns false for it. Either the comment
overstates or the implementation is missing; both are cheap to fix once decided.

### 3.6 Correction to the bead's account of gh 3887

mybd-zelnn says grandchildren are missed because "propagation is one level per
recompute rather than a transitive walk". That is not quite the mechanism.
`RecomputeIsBlockedInTx` **does** iterate to a fixpoint:

```go
for {
    var changed int64
    ... // issues pass, wisps pass
    if changed == 0 { return nil }
}
```

The real limit is *batch membership*: every pass restricts to `i.id IN (<ids>)`,
the caller-supplied set. A grandchild that is not in that set is never
considered, no matter how many iterations run. So the fix is not "walk
transitively" but "close the ID set over descendants before recomputing" — a
materially different change, and the same mechanism explains gh 4138 (rows
migration left at `is_blocked=0` self-heal only if something later happens to
recompute them).

## 4. Four hardcoded blocking-type lists that can drift

The set "which types block" is written out independently in at least four
places. Nothing keeps them consistent:

| Location | List | Used for |
|---|---|---|
| `issueops/blocked_state.go` arms A–C | blocks, conditional-blocks, parent-child, waits-for | **the actual gate** |
| `types.go` `AffectsReadyWork()` | same four | display, import, swarm — **not the ready path** |
| `issueops/blocked.go:29` | blocks, waits-for, conditional-blocks | `bd blocked` |
| `cmd/bd/doctor/validation.go:428` | blocks, conditional-blocks, waits-for | deadlock check |

Note `AffectsReadyWork()` — the function whose name asserts it is the authority
on this question — is called from `list_format.go`, `import_shared.go`,
`swarm.go`, `graph_apply.go` and `domain/issue.go`, and from **nowhere on the
ready path**. It is a claimed contract with no enforcement. If the denormalized
bit is kept, deriving these lists from one constant is the cheapest available
guard against the next instance of this bug family.

## 5. What this does not decide

Left open for the owner, in the order they need answering:

1. **Denormalized bit or live join?** §3.1 (outcome dimension) and gh 3877
   (perf, "re-evaluate using the `ready_issues` view") are the same question
   from two sides. Every row marked OWNER above is cheap under a join and needs
   a new column or a new arm under the bit.
2. **What does hierarchy mean?** Until §3.2 is settled, `bd dep add`'s error
   message and the recompute contradict each other and gh 5036 cannot be
   dispositioned either way.
3. **Should `depends_on_external` gate?** gh 4769; open implementation PR
   gh 4753 is unmerged with changes-requested.
4. **Fail-open or fail-loud for custom types?** §3.4.
5. **The eleven association/entity/reference types.** Most are obviously
   non-gating; `until`, `validates`, `approved-by`, `duplicates`, `supersedes`
   and `delegated-from` are not obvious and should get an explicit ruling rather
   than inheriting one.

Only once (1) and (2) are answered can acceptance items (2)–(5) of mybd-zelnn —
the help-text reconciliation, per-class regression tests, upstream dispositions,
and the drift doctor check — be written without guessing.

## 6. Follow-ups filed

- mybd-jrbuu — `conditional-blocks` outcome gap (§3.1); no upstream issue exists, needs one.
- mybd-zg2dj — custom-type fail-open (§3.4); needs a ruling.
- mybd-exkxx — `delegated-from` comment/implementation mismatch (§3.5); needs a ruling.
- mybd-0zfum — correction to gh 3887's stated mechanism (§3.6); should be posted
  upstream so the eventual fix targets batch closure, not a transitive walk.

_claude-opus-5-medium on behalf of maphew_
