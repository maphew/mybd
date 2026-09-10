# Retained Windows patches: exact state - 2026-09-10

Repository: Beads source, origin maphew/beads, upstream gastownhall/beads. Cleanup preserved these patches; no source test suite was run and no implementation changed.

## Config-only reset: mybd-erj71

Unique uncommitted patch retained unchanged. Original mybd-b8ht records a destructive wrong-target incident. Next step: design review and isolated target-coherence reproduction before deciding whether to revive. Do not run reset against real or global databases.

Full file copies, binary diffs and untracked tests are in tmp/local-work-recovery-20260910.zip. ZIP-entry SHA-256 checks passed for every source file.

    Captured with handoff-exact-state capture_state.py:

    {
      "active_bead": {
        "assignee": null,
        "blocked_by": [],
        "id": "mybd-erj71",
        "owner": "maphew@gmail.com",
        "status": "open",
        "title": "Evaluate retained config-only reset patch before any reuse"
      },
      "base_ref": "upstream/main",
      "base_sha": "a690b0a8c4d1ddc4f0bd9bf767499625dd71bc96",
      "branch": "fix/b8ht-reset-config",
      "changed_paths": [
        "cmd/bd/main.go",
        "cmd/bd/reset.go",
        "cmd/bd/reset_config_test.go",
        "docs/recovery/uninstalling.md"
      ],
      "conflicted": [],
      "dirty": [
        "cmd/bd/main.go",
        "cmd/bd/reset.go",
        "docs/recovery/uninstalling.md"
      ],
      "git_common_dir": "A:\\dev\\mybd\\bd-main\\.git",
      "head_sha": "873e3040bf0f0974f9ebc24e7d11afb4b989c092",
      "in_progress_operations": [],
      "merge_base": "873e3040bf0f0974f9ebc24e7d11afb4b989c092",
      "remote_origin": "https://github.com/maphew/beads.git",
      "repo_root": "A:\\dev\\mybd\\bd-main",
      "repository_identity": "https://github.com/maphew/beads.git",
      "staged": [],
      "untracked": [
        "cmd/bd/reset_config_test.go"
      ],
      "upstream_ahead": 0,
      "upstream_behind": 912,
      "upstream_ref": "upstream/main",
      "worktree": "A:\\dev\\mybd\\.worktrees\\beads\\b8ht-reset-config"
    }

## GNU Make 3.81 host detection: mybd-d44xi

Unique committed patch retained on its clean branch. Next step: determine whether this Make version remains supported, then reproduce host detection in isolation before reviving or retiring. Preserve the existing Amp coauthor attribution. Full commit is in the source recovery bundle.

    {
      "active_bead": {
        "assignee": null,
        "blocked_by": [],
        "id": "mybd-d44xi",
        "owner": "maphew@gmail.com",
        "status": "open",
        "title": "Decide disposition of unique GNU Make 3.81 Windows host-detection patch"
      },
      "base_ref": "upstream/main",
      "base_sha": "a690b0a8c4d1ddc4f0bd9bf767499625dd71bc96",
      "branch": "fix/make-381-host-detection",
      "changed_paths": [],
      "conflicted": [],
      "dirty": [],
      "git_common_dir": "A:\\dev\\mybd\\bd-main\\.git",
      "head_sha": "e250ea4b8b132cc3fd358fd59c8f837c3024386a",
      "in_progress_operations": [],
      "merge_base": "4a76685f90adc5426cf7de0bef706e3eb08a4731",
      "remote_origin": "https://github.com/maphew/beads.git",
      "repo_root": "A:\\dev\\mybd\\bd-main",
      "repository_identity": "https://github.com/maphew/beads.git",
      "staged": [],
      "untracked": [],
      "upstream_ahead": null,
      "upstream_behind": null,
      "upstream_ref": null,
      "worktree": "A:\\dev\\mybd\\.worktrees\\beads\\make-381-host"
    }

## Completed snapshots retired

j97q-history-null: current upstream uses COALESCE for nullable text, superseding this local sql.NullString approach. All tracked/untracked content was archived and verified before removal.

pr-4858-f103632: staged patch SHA-256 CDB4364BB7CE8F825D38F0B9155869469505EF06608A1F1B0AA185793EE7C2FE equals committed range 0cf3b3c..36d9af7. Recovery branches review/pr-4858-f103632 at f103632449e2e208c7d66e7259d946e887bfe187 and review/pr-4858-36d9af7 at 36d9af7351c2aaf2e7790bf6aa1b5e197fd572de remain.

Completed review checkouts pr-3837-review, pr-4284-review and pr-4376-review were removed after finding completed batch/report evidence. Upstream PRs were not modified.
