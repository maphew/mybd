# Agent session archive research (mybd-8vhy3)

Date: 2026-09-03. Host: framation (Linux). Scope: read-only inventory of this
machine plus vendor docs. Labels: **[measured]** = observed on this machine,
**[docs]** = vendor documentation, **[inferred]** = reasoning from evidence.

## Summary

- Raw transcripts on this machine total about 1.2 GiB across vendors: Claude
  Code 341 MiB (1231 jsonl, 2026-07-23 to 2026-09-02), Codex 534 MiB (910
  rollouts, 2025-10-15 to 2026-09-02), Amp 71 MiB (386 threads, stale since
  2026-04-01), Kilo about 1.5 GiB of task/session state (dormant since June).
- Claude Code history before 2026-07-23 is gone: the default 30-day sweep ran
  until `cleanupPeriodDays` was raised to 730 on 2026-08-24. `history.jsonl`
  proves roughly 2250 prompts from 2025-10 to 2026-07-22 have no transcript.
  AgentsView holds lossy parsed copies of 233 of those sessions (from
  2026-05-03) whose raw files no longer exist; nothing earlier survives.
- Codex has no documented auto-deletion and nothing appears lost, but it is
  mid-migration from jsonl rollouts to SQLite thread history (`codex
  migrate-rollouts`), so the archive must capture both forms.
- Amp threads are server-resident; the local store stopped at 2026-04-01.
  `amp threads list --json` and `amp threads export <id>` exist on PATH and are
  the only path to a local copy. `amp threads raw` is internal-only.
- Recommendation: restic (encrypted, deduplicated) to the already-configured
  rclone `gdrive:` remote, driven by a systemd user timer in the existing
  `scripts/systemd/` pattern, with a Windows twin writing to the same repo.
  Growth is about 1 GiB per machine per year after compression. AgentsView
  stays the analytics layer, not the archive of record.

## Inventory table

| Vendor | Path | Count | Size | Oldest | Newest | Retention policy and source |
|---|---|---|---|---|---|---|
| Claude Code | `~/.claude/projects/*/<session>.jsonl` [measured] | 295 sessions | 132 MiB (mybd alone) | 2026-07-23 (mtime) | 2026-09-02 | Deleted when older than `cleanupPeriodDays`; default 30, min 1, `0` rejected [docs: claude-directory]. Set to 730 here on 2026-08-24 [measured]. Last sweep 2026-08-31 (`.last-cleanup`) |
| Claude Code | `~/.claude/projects/*/<session>/subagents/*.jsonl` [measured] | 936 files in 110 session dirs | ~160 MiB (mybd) | 2026-07-23 | 2026-09-02 | "removed with the parent session transcript when it ages out" [docs] |
| Claude Code | `~/.claude/history.jsonl` [measured] | 2557 prompts | 12.4 MiB | 2025-10-30 | 2026-09-01 | Listed under "Kept until you delete them"; not in the sweep [docs]. Prompts only, no responses |
| Claude Code | `~/.claude/file-history/` [measured] | 696 files | 17 MiB | 2026-07-23 | 2026-08-24 | In the sweep; also capped at 100 checkpoints [docs] |
| Claude Code | `~/.claude/sessions/`, `session-env/`, `shell-snapshots/`, `usage-data/`, `telemetry/` [measured] | small | <2 MiB total | | | Live-process metadata and caches, not transcripts. `shell-snapshots/` and `backups/` are in the sweep since v2.1.117 [docs via GH issue 51779] |
| Codex CLI | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` [measured] | 910 | 534 MiB | 2025-10-15 | 2026-09-02 | No retention setting documented for rollouts [docs: config reference has only `history.persistence` and `history.max_bytes`, which govern `history.jsonl`]. Max single file 11.5 MiB |
| Codex CLI | `~/.codex/history.jsonl` [measured] | 700 lines | 142 KiB | 2025-10-23 | 2026-08-24 | `history.persistence = save-all|none`, `history.max_bytes` drops oldest [docs]. Stopped growing 2026-08-24 while sessions continue [measured]; superseded by SQLite [inferred] |
| Codex CLI | `~/.codex/state_5.sqlite` (threads table, 910 rows), `thread_history_1.sqlite` (83 turns, 3870 items) [measured] | | 4 MiB, 25 MiB | | 2026-09-02 | Undocumented. `codex migrate-rollouts` moves "legacy local sessions to paginated thread history" [measured: `--help`]. Archive both DBs via `.backup` |
| Codex CLI | `~/.codex/logs_2.sqlite` [measured] | 15442 rows | 493 MiB | 2026-08-20 | 2026-09-02 | Diagnostic logs, 13 days only. Exclude from archive [inferred] |
| Codex CLI | `~/.codex/archived_sessions/` | 0 | 0 | | | Created by `codex archive`; not used here [measured] |
| Amp | `~/.local/share/amp/threads/*.json` [measured] | 386 | 71 MiB | 2025-07-18 | 2026-04-01 | Local store stale; threads live on ampcode.com. Docs give no bulk export or retention period for live threads; only "deleted within 30 days" of explicit deletion [subagent, inferred from search] |
| Amp | `~/.local/share/amp/history.jsonl`, `~/.cache/amp/logs/cli.log*` [measured] | 1090 prompts; 3 log files | 0.5 MiB; 30 MiB | logs 2026-08-18 | 2026-09-02 | Prompt text without timestamps; logs rotate at 10 MiB, about two weeks of coverage |
| Kilo CLI | `~/.local/share/kilo/kilo.db` + `storage/{session,message,part}` [measured] | 170 sessions, 4188 messages, 8429 files | 129 MiB + 109 MiB | 2026-02-06 | 2026-06-16 | Kilo has an "Auto Cleanup" settings page (per-type age retention) [docs title only, not fetched]. Already staged per-minute by `agentsview-stage-export` [measured] |
| Kilo VS Code ext | `~/.config/Code/User/globalStorage/kilocode.kilo-code/tasks/<id>/` [measured] | 510 tasks | 1.2 GiB (includes checkpoints) | 2025-07-31 | 2026-03-15 | Same Auto Cleanup risk. `api_conversation_history.json` + `ui_messages.json` per task [measured] |
| Kilo legacy CLI | `~/.kilocode/cli/global` [measured] | 51 json | 144 MiB | 2025-10-15 | 2026-02-06 | Unknown; dormant |
| OpenCode | `~/.local/share/opencode/opencode.db` [measured] | 0 sessions | 250 KiB | | | Nothing to archive |
| Gemini / Antigravity | `~/.gemini/antigravity/{brain,conversations}` [measured] | 86 files | 11 MiB | 2025-11-21 | 2025-11-21 | Gemini CLI docs: `~/.gemini/tmp/<hash>/chats/`, 30-day default [docs, mirror domain]. No `tmp/chats` here; unused since 2026-03 |
| Copilot / Windsurf | `globalStorage/github.copilot-chat`, `~/.windsurf` [measured] | 1 chat session | 11 MiB / 1.1 GiB (app binaries) | 2025-03-08 | | Negligible; Windsurf dir is the app, not transcripts |
| AgentsView (derived) | `~/.agentsview/sessions.db` [measured] | 3236 sessions, 137892 messages | 994 MiB | 2025-03-08 | 2026-09-03 | Parsed, lossy (48 MiB of message content total). Hub/spoke over Tailscale to a Fly.io hub already configured; artifact sync unused (0 publications) |

Windows desktop (`matt-desktop`) and cloud sessions cannot be inventoried from
here. Needed: on Windows, the same du/find pass over `%USERPROFILE%\.claude`,
`%USERPROFILE%\.codex`, `%APPDATA%\Code\User\globalStorage\kilocode.kilo-code`,
`%LOCALAPPDATA%\kilo` and its `cleanupPeriodDays` value. For cloud: whether
claude.ai/code and Codex cloud tasks expose transcript downloads at all (not
documented in the pages read); the local `~/.claude/session-env/` and
`sessions/*.json` bridge files reference cloud sessions but hold no content.

## What is already lost

- **Claude Code, 2025-10-30 to 2026-07-22** [measured + inferred]:
  `history.jsonl` has 6+15+1335+421+250+225 prompts for Oct/Nov 2025 and
  Mar to Jun 2026, plus early July, yet the oldest transcript is 2026-07-23.
  2026-07-23 is exactly 32 days before `settings.json` was changed on
  2026-08-24, matching the 30-day default sweep. March 2026 (1335 prompts) was
  the heaviest month on record and is entirely gone.
- **Partial recovery**: AgentsView indexed 233 Claude sessions dated
  2026-05-03 to 2026-07-22 whose `file_path` no longer exists on disk. It
  retains 6078 messages (6.1 MiB) and 5072 tool-call rows. That is parsed
  content, not raw jsonl; large tool results and subagent detail are reduced.
  It is the only surviving copy and lives in a live SQLite file with no backup.
- **Amp after 2026-04-01**: no local copy at all. Threads are on the server;
  AgentsView indexed 306 of the 386 local files and nothing newer.
- **Codex**: nothing evidently lost. All 910 threads in `state_5.sqlite`
  resolve to files on disk. The Nov 2025 to Jan 2026 gap matches zero
  `history.jsonl` entries (not used, not deleted). `history.jsonl` itself went
  quiet on 2026-08-24, so prompt-level history now exists only in SQLite.
- **Subagent transcripts**: none lost since 2026-07-23, but they age out with
  the parent, so the same 30-day loss applied before that.

## Archive design comparison

Measured growth [measured]: Claude 148 MiB in Aug 2026 (subagents included),
Codex 115 to 140 MiB per active month, Amp exports maybe 10 MiB per month,
Kilo dormant. Raw total about 3 to 3.5 GiB per year per active machine.
zstd -3 gives 3.9x on Claude jsonl and 5.3x on Codex rollouts [measured], so
about 0.8 to 1 GiB per machine-year compressed; restic dedup lowers that
further because Claude appends to the same jsonl across days.

| | (a) Private git repo, nightly compressed snapshots | (b) restic to synced disk (rclone `gdrive:` or `~/OneDrive`) | (c) systemd user timer |
|---|---|---|---|
| Role | Store + transport | Store + transport | Scheduler only; orthogonal, needed by both (a) and (b) |
| Fit for data | Poor: jsonl files change for days (git stores a new blob per change unless committed as append-only per-session `.zst`); GitHub soft limit 5 GiB per repo; 100 MiB file limit is safe today (max 11.5 MiB) | Good: content-defined chunking dedups appended files; snapshots are cheap; encrypted at rest; `restic forget` policy is explicit | n/a |
| Secrets | Plaintext tokens in a hosted repo. GitHub push protection may block or auto-revoke `ghp_`, `sk-ant-` patterns; redaction becomes a hard prerequisite | Encrypted repo; redaction can happen at read time for report generation, not at capture | n/a |
| Multi-machine | Easy (Windows pushes too), but merges of binary snapshots are awkward | Easy: one repo, per-host snapshots, restic runs on Windows; `gdrive:` and OneDrive are already configured here [measured] | Windows twin = Task Scheduler + PowerShell wrapper |
| Cost | Free | Free within existing Google Drive / OneDrive quota; ~2 GiB per year for two machines | Free |
| Existing precedent | Reports are git-tracked here, but not binary bulk | `restic`, `rsync`, `rclone`, `zstd`, `sqlite3` all present [measured] | `scripts/systemd/index-babysit.*` + `scripts/install-index-babysit`; `agentsview-stage-export.timer` (per-minute rsync staging) |
| Restore/reporting | `git clone` then decompress | `restic restore` or `restic mount` into a read-only tree; AgentsView can read that tree (or an S3 raw root in `<machine>/raw/{claude,codex}` layout) [docs: agentsview configuration.md] | n/a |

AgentsView artifact sync is a fourth option worth naming: it already has a
Fly.io hub and a Tailscale spoke on this machine, and it supports raw source
snapshots. It is not the archive of record because its content is parsed and
reduced (the lost-era sessions show 6 MiB retained from what was likely over
100 MiB raw), its raw artifacts are "optional" and parser-dependent, and the
live DB has no backup of its own.

## Recommendation

Use (b) + (c): restic to `gdrive:` via rclone (fallback: a folder under
`~/OneDrive`, which is live-syncing; Dropbox appears idle since 2026-01), run
nightly by a systemd user timer built from the `index-babysit` template. One
repository, per-host snapshots tagged `host=framation|matt-desktop`.

Sources per snapshot (a `scripts/session-archive` script stages then backs up):

- `~/.claude/projects/` (session jsonl, `subagents/`, `tool-results/`,
  `memory/`), `~/.claude/history.jsonl`, `~/.claude/file-history/`.
- `~/.codex/sessions/`, `~/.codex/archived_sessions/`, `~/.codex/history.jsonl`,
  plus `sqlite3 .backup` copies of `state_5.sqlite` and `thread_history_1.sqlite`
  (never copy a live WAL DB). Exclude `logs_2.sqlite`, `cache/`, `plugins/`.
- Amp: `~/.local/share/amp/threads/`, `history.jsonl`, and a staging dir filled
  by `amp threads list --json --limit N` diffed against the previous list, then
  `amp threads export <T-id>` for new or modified threads.
- Kilo: reuse `~/.agentsview/export-staging/kilo/` (already a consistent
  backup) plus the VS Code `kilocode.kilo-code/tasks/` tree minus `checkpoints/`.
- `~/.agentsview/sessions.db` via `.backup` (carries the only copy of the
  May-July 2026 Claude sessions).

Secret handling: restic encryption covers storage. Transcripts are known to
contain live values: 4 Claude jsonl files hold `CLAUDE_CODE_MESSAGING_TOKEN`
(exported into every Bash tool subprocess here), 1 holds an `sk-ant-` key, and
3 Codex rollouts hold `ghp_`/`github_pat_` tokens [measured, counts only].
AgentsView's own scanner flagged 3 findings. Do redaction at materialization
time (a `scripts/transcript-redact` filter applied when extracting report
inputs), keyed on env var names seen locally (`CLAUDE_CODE_MESSAGING_TOKEN`,
`STARSHIP_SESSION_KEY`) and token prefixes (`sk-ant-`, `ghp_`, `github_pat_`,
`AKIA`, `Bearer `). Keep the restic password outside the repo and outside
transcripts (systemd `LoadCredential`, not an env var, so the next agent's env
dump does not leak it into the next transcript). Rotate the three exposed
GitHub tokens regardless of archive choice.

Retention policy in restic: `--keep-daily 30 --keep-weekly 26 --keep-monthly
unlimited`; never prune data older than the newest year-in-review. Set
`cleanupPeriodDays` to 730 on the Windows machine too (verify first).

## Next steps

1. Stop the bleeding: `restic init` on `rclone:gdrive:agent-archive`, take a
   first manual snapshot of the source list above from this machine, and back
   up `~/.agentsview/sessions.db` the same day.
2. Verify Windows state: run the inventory pass on matt-desktop (paths, counts,
   date ranges, `cleanupPeriodDays`), record results as a comment on the bead.
3. Write `scripts/session-archive` (staging, sqlite `.backup`, excludes, restic
   backup with host tag, log to `~/.local/state/session-archive/`), with a
   `--dry-run` that prints the file list and sizes.
4. Add `scripts/systemd/session-archive.{service,timer}` (nightly, `Persistent=true`,
   `LoadCredential=restic-password`) and `scripts/install-session-archive`
   cloned from `install-index-babysit`; smoke test in `scripts/test-session-archive`.
5. Amp capture: `scripts/amp-thread-mirror` that diffs `amp threads list --json`
   against the last run and exports new or modified threads into staging;
   confirm export payload includes subagent messages (`raw` is internal-only).
6. Codex migration handling: run `codex migrate-rollouts` without `--apply` to
   see what is eligible; decide whether the archive keeps rollouts, SQLite, or
   both; record the decision in bd memory.
7. Write `scripts/transcript-redact` (stream filter) and test it against the 8
   known-hit files by count of remaining matches, not by printing content.
8. Rotate the exposed tokens (3 GitHub PATs, 1 Anthropic key) and confirm the
   messaging token is per-session and short-lived (if not, file upstream).
9. Windows twin: PowerShell wrapper + Task Scheduler entry pointing at the same
   restic repo; confirm restic and rclone on that host.
10. Point AgentsView at a restored or S3-style raw root of the archive so
    quarterly reports can use `agentsview export digest` across both machines;
    decide whether to enable artifact sync as the analytics transport.
11. Cloud sessions: determine what claude.ai/code and Codex cloud expose
    (download, API, or nothing) and document the gap in the year-in-review
    template.
12. `bd remember` the retention facts (Claude 30-day default, loss window
    2025-10 to 2026-07-22, restic repo location) so the cold-start path sees them.

## Sources

- Claude Code `.claude` directory reference (retention sweep, paths):
  https://code.claude.com/docs/en/claude-directory
- Claude Code settings reference (`cleanupPeriodDays`, `desktopSessionCleanupPeriodDays`):
  https://code.claude.com/docs/en/settings-reference
- Claude Code data usage (30-day default): https://code.claude.com/docs/en/data-usage
- Claude Code sessions (transcript location): https://code.claude.com/docs/en/sessions
- Claude Code GH issues on sweep scope and `0` behaviour:
  https://github.com/anthropics/claude-code/issues/51779 ,
  https://github.com/anthropics/claude-code/issues/23710
- Codex config reference (`history.persistence`, `history.max_bytes`):
  https://learn.chatgpt.com/docs/config-file/config-reference (redirect target of
  https://developers.openai.com/codex/config-reference)
- Codex config schema: https://github.com/openai/codex/blob/main/codex-rs/core/config.schema.json
- Codex session lifecycle (community, rollout and archive paths):
  https://codex.danielvaughan.com/2026/06/05/codex-cli-session-lifecycle-archive-resume-fork-compact-management/
- Amp manual and CLI: https://ampcode.com/manual , https://ampcode.com/docs/cli
- Kilo Code auto cleanup: https://kilo.ai/docs/getting-started/settings/auto-cleanup ;
  legacy file locations: https://github.com/Kilo-Org/kilocode-legacy/blob/main/docs/legacy-ides/getting-started/file-locations.md
- OpenCode storage (community): https://blog.whtsky.me/tech/2026/garbage-collecting-opencodes-2.4-gb-session-database/
- Gemini CLI session management (mirror domain): https://geminicli.com/docs/cli/session-management/
- AgentsView artifact sync and S3 raw roots (local checkout of maphew/agentsview):
  `~/dev/agentsview/docs/artifact-sync.md`, `~/dev/agentsview/docs/configuration.md`
- Local precedents: `scripts/systemd/index-babysit.{service,timer}`,
  `scripts/install-index-babysit`, `~/.local/libexec/agentsview-stage-export`
