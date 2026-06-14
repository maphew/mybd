---
description: Initialize external synced beads stealth mode for the current project
---

Initialize beads in stealth mode for the current project using the generic helper script.

Run from the current working directory unless the user supplied a project path in `$ARGUMENTS`.

Use this command shape:

```bash
/var/home/matt/dev/mybd/scripts/bd-stealth-init $ARGUMENTS
```

After it completes, report the project path, external beads repository, `BEADS_DIR`, whether a remote is configured, and whether sync ran.
