# homebrew-core `beads` formula bump — prep for v1.1.0 (#4533)

Prepared 2026-07-03. Fire **at v1.1.0 stable promotion**, as part of the
`mybd-qb0c` un-gate checklist. Do not run before the stable tag exists (the
tarball + sha256 do not exist until then).

## Current state (Homebrew/homebrew-core `Formula/b/beads.rb`)

Stale on two axes:

```ruby
homepage "https://github.com/steveyegge/beads"                                  # old repo
url      "https://github.com/steveyegge/beads/archive/refs/tags/v1.0.5.tar.gz"  # old repo + gated version
```

- **Repo path** still points at `steveyegge/beads`; active development is
  `gastownhall/beads`. This is the `brew info beads` "old repo path" in #4533.
- **Version** is `v1.0.5` — the release that was gated and pulled over #4259.
  homebrew-core is serving a version we deliberately withheld.

## Target state (after v1.1.0 stable)

```ruby
homepage "https://github.com/gastownhall/beads"
url      "https://github.com/gastownhall/beads/archive/refs/tags/v1.1.0.tar.gz"
# sha256 recomputed from the v1.1.0 source tarball
```

Confirm the canonical homepage at promotion (repo may present under a
different org display name); `gastownhall/beads` is the current source of
truth.

## How to fire (at promotion)

homebrew-core requires the standard bump flow, not a hand-edited PR:

```bash
brew bump-formula-pr \
  --url="https://github.com/gastownhall/beads/archive/refs/tags/v1.1.0.tar.gz" \
  beads
```

`bump-formula-pr` recomputes `sha256`, opens the PR against
Homebrew/homebrew-core, and runs their CI. If the `homepage` also needs
updating (it does), either pass it through the bump or follow up with a
one-line homepage edit in the same PR — homebrew-core reviewers accept a
homepage correction alongside a version bump when the repo moved.

## Checklist coupling

Part of the retargeted un-gate sequence (`mybd-qb0c`, `mybd-86as`):

1. Tag + publish `v1.1.0` stable, mark it Latest.
2. `brew bump-formula-pr` (this doc).
3. Deprecate npm `@beads/bd@1.0.5` (see #4559).
4. Unpin and close #4259 referencing the merged fix #4266.
