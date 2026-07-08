Confirmed on today's main (661ed07), answering our earlier repro question from code inspection: `bd backup init/sync/restore` build client-absolute `file://` URLs and hand them to a remote dolt server via `CALL DOLT_BACKUP` with no remote-server guard (`resolveDoltBackupURL`, cmd/bd/backup_dolt.go). The auto-backup variant of this was already fixed by #3568, and the push/pull CLI-dir problem by #4236, so the live bug is now scoped to the explicit backup commands.

Detailed verification and a suggested narrowed scope are in the review comment on #3595.

_claude-fable-5-high on behalf of matt wilkie_
