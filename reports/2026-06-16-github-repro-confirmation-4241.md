Independently reproduced against current `bd`:

- Binary: `bd version 1.0.5 (Homebrew)`
- Host: Linux
- Isolation: temporary HOME and two scratch Git repos under `/tmp`

Recipe used:

1. Created a caller Git repo with no `beads.role` configured.
2. Created a separate target Git repo, configured `git config beads.role maintainer`, initialized beads, and created an epic plus child issue.
3. From the caller repo, ran:

   ```sh
   bd -C "$target" list --parent "$root" --all --limit 1
   ```

4. From the target repo, ran the equivalent command without `-C`.

Observed result:

```text
warning: beads.role not configured (#2950).
  Fix: git config beads.role maintainer
  Or:  git config beads.role contributor
```

The warning appeared only for the `bd -C "$target"` invocation from the unrelated caller repo. Running the same list command from inside the target repo produced no warning.

_codex-gpt-5.5-medium on behalf of matt wilkie_
