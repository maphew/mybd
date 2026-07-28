# duncan4123 disposition drafts — #4561 / #4736 (mybd-q0ki6)

Status: **DRAFTS — not posted.** Per the debt-of-honor lane these are staged
for maphew to review, edit, and post personally (same class as the mybd-za009
apologies; the author has been waiting on a review reply since ~2026-07-12 and
deserves a human voice, not an agent signature). Facts verified against the PR
timeline on 2026-07-28.

Timeline the drafts rest on:

- 2026-07-05 — maphew reviews #4561, flags harry-miller-trimble's
  plugin-architecture investigation.
- 2026-07-07 — maphew points at #4601 from the #4561 thread.
- 2026-07-10 — #4601 merges ("choose your own storage backend: Postgres /
  MySQL / SQLite behind the Dolt-parity seam"), maphew co-authored.
- ~2026-07-12 — duncan4123 replies to the review; no maintainer response
  since.
- 2026-07-16 — #4847 rolls back the direct PostgreSQL and MySQL adapters.
- 2026-07-18 — #4881 consolidates storage on Dolt.
- #4736 ("Expose configured backend opener") has had zero maintainer contact
  since it was opened.

---

## Draft for gastownhall/beads#4561

> Duncan — you're owed a straight answer, and an apology for the silence
> since your reply. This one's on us.
>
> Here is what actually happened to this design space after your PR: a week
> after you opened it, we landed #4601, which built essentially the same
> core idea (a backend-neutral configured opening path with a provider
> registry). We should have said so here, plainly, at the time — pointing
> you at the PR number without that context wasn't a real answer.
>
> Then, within another week, we reversed course: #4847 rolled back the
> direct Postgres/MySQL adapters and #4881 consolidated storage on Dolt.
> The parity seam looked right in review, but maintaining true behavioral
> parity across backends (versioning semantics, migration behavior, the
> conformance surface) cost more than it bought, and we chose to shrink
> the supported surface rather than ship a second-class backend tier.
>
> So the honest disposition of this PR is: the direction you proposed was
> tried, merged in a parallel implementation, and deliberately rolled
> back — not because your design was wrong, but because we decided the
> project shouldn't carry multiple storage backends at all right now.
> What survives from this space is the longer-term driver-interface
> roadmap (users and agents never touching the DB layer directly). If we
> reopen pluggable backends it will be behind that interface, and your
> registry design is prior art we'd want in that conversation.
>
> I'm closing this rather than leaving you waiting on a review round that
> can no longer land. Thank you for the work and the patience — the
> slow, indirect handling of this one is exactly what we're trying to fix
> in how we run this queue.

## Draft for gastownhall/beads#4736

> Duncan — apologies first: this PR never got any maintainer contact, and
> that's a failure on our side, full stop.
>
> The context (fuller version on #4561): the configured-backend direction
> this exposes was implemented in parallel via #4601, then deliberately
> reversed by #4847/#4881 when we consolidated storage on Dolt. With no
> configured-backend seam left in the tree, there is no longer anything
> for this PR to expose, so I'm closing it as overtaken by that decision
> rather than by anything lacking in the change itself.
>
> If the pluggable-backend question reopens under the driver-interface
> roadmap, the opener you sketched here is the kind of surface we'd be
> designing around, and we'd value your input then.

---

Posting notes for maphew:

- Post #4561 first; #4736's draft references it.
- Both PRs should be closed by *you* after posting (not the patrol, not a
  mechanical close-when-quiet lane) — matches the personal-handling rule from
  the #4376 post-mortem.
- After posting + closing, close bead mybd-q0ki6 with a pointer to the
  comments.
