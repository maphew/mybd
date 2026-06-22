# Dolt Git Remote Sync Stall in mybd

Date: 2026-06-22

Bead: mybd-l6ms

## Summary

`bd dolt pull` stalls because the underlying Dolt Git-remote fetch path stalls. The existing `A:\dev\mybd\.beads\embeddeddolt\mybd` store is not the trigger: a fresh `dolt clone --depth 1 git+https://github.com/maphew/mybd.git` also stalls, and so does a clone from a local `file://` mirror created by plain Git.

Plain Git can reach and fetch the same GitHub repo and `refs/dolt/data` quickly. The failure layer is Dolt's Git-remote data pull/import pipeline.

## Environment

- Windows host: `MATT-DESKTOP`
- Coordination repo: `A:\dev\mybd`
- Active beads DB: `.beads\embeddeddolt\mybd`
- `bd`: `c:\users\matt\.local\bin\bd.exe`, `bd version 1.0.5 (6a3f515ce)`
- Windows Dolt: `C:\Users\Matt\scoop\shims\dolt.exe`, `dolt version 2.1.8`
- WSL Dolt: `/home/linuxbrew/.linuxbrew/bin/dolt`, `dolt version 2.1.8`
- Current upstream Dolt release checked with `gh release view --repo dolthub/dolt`: `v2.1.8`, published `2026-06-17T16:46:51Z`

## Baseline

`scripts/check-beads-config` passed:

```text
beads config ok: active database mybd (442 issues)
```

Local Dolt status inside `.beads\embeddeddolt\mybd`:

```text
On branch main
Your branch is ahead of 'origin/main' by 3 commits.
  (use "dolt push" to publish your local commits)
```

Schema migration max:

```text
MAX(version) = 49
```

Remote:

```text
origin git+https://github.com/maphew/mybd.git
refs/dolt/data = a65e18b6015917b7d0c1cc8ace640c36741df905
```

## Reproductions

### `bd dolt pull`

Command:

```powershell
bd dolt pull
```

Result after 30 second watchdog:

```json
{
  "command": "bd dolt pull",
  "exe": "c:\\users\\matt\\.local\\bin\\bd.exe",
  "version": "bd version 1.0.5 (6a3f515ce)",
  "cwd": "A:\\dev\\mybd",
  "timeout_seconds": 30,
  "elapsed_seconds": 30.305,
  "exited": false,
  "stdout": "Pulling from Dolt remote...\n",
  "process_tree": [
    {
      "Name": "bd.exe",
      "CommandLine": "\"C:\\users\\matt\\.local\\bin\\bd.exe\" dolt pull"
    }
  ]
}
```

### Direct Windows `dolt fetch origin`

Command:

```powershell
dolt fetch origin
```

Working directory:

```text
A:\dev\mybd\.beads\embeddeddolt\mybd
```

Result after 30 second watchdog:

```json
{
  "command": "dolt fetch origin",
  "exe": "C:\\Users\\Matt\\scoop\\shims\\dolt.exe",
  "version": "dolt version 2.1.8",
  "timeout_seconds": 30,
  "elapsed_seconds": 30.374,
  "exited": false,
  "stdout": "- Fetching...",
  "process_tree": [
    {
      "Name": "dolt.exe",
      "CommandLine": "\"C:\\Users\\Matt\\scoop\\shims\\dolt.exe\" fetch origin"
    },
    {
      "Name": "dolt.exe",
      "CommandLine": "\"C:\\Users\\Matt\\scoop\\apps\\dolt\\current\\bin\\dolt.exe\"  fetch origin"
    }
  ]
}
```

### Fresh Windows clone from GitHub

Command:

```powershell
dolt clone --depth 1 git+https://github.com/maphew/mybd.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-clone-test
```

Result after 30 second watchdog:

```json
{
  "version": "dolt version 2.1.8",
  "elapsed_seconds": 30.485,
  "exited": false,
  "stdout": "cloning git+https://github.com/maphew/mybd.git\n"
}
```

### Fresh Windows clone from a local Git mirror

Plain Git first completed:

```powershell
git clone --mirror https://github.com/maphew/mybd.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-bare.git
```

Then Dolt stalled:

```powershell
dolt clone --depth 1 git+file:///C:/Users/Matt/AppData/Local/Temp/mybd-l6ms-bare.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-local-dolt-clone
```

Result after 30 second watchdog:

```json
{
  "git_mirror": "ok",
  "version": "dolt version 2.1.8",
  "elapsed_seconds": 30.214,
  "exited": false,
  "stdout": "cloning git+file:///C:/Users/Matt/AppData/Local/Temp/mybd-l6ms-bare.git\n"
}
```

### WSL clone

Command:

```bash
timeout 60s dolt clone --depth 1 git+https://github.com/maphew/mybd.git mybd-clone
```

Result:

```text
stdout:
cloning git+https://github.com/maphew/mybd.git
stderr:
clone failed; terminated signal received
real 60.01
user 51.83
sys 7.36
```

The high user CPU time suggests a busy Dolt-side pull/import path, not a blocked network read.

## Controls

Plain Git/GitHub access succeeds:

```powershell
git ls-remote https://github.com/maphew/mybd.git HEAD refs/heads/main
gh repo view maphew/mybd --json nameWithOwner,visibility,defaultBranchRef,url
```

Plain Git can fetch the Dolt data ref:

```powershell
git init
git fetch --depth=1 https://github.com/maphew/mybd.git refs/dolt/data:refs/remotes/origin/dolt-data
git count-objects -vH
```

Result:

```text
a65e18b6015917b7d0c1cc8ace640c36741df905
in-pack: 121
packs: 1
size-pack: 22.33 MiB
```

## Stack Excerpt

A WSL SIGQUIT stack during the stalled clone shows goroutine 1 waiting in `Puller.Pull`:

```text
golang.org/x/sync/errgroup.(*Group).Wait
github.com/dolthub/dolt/go/store/datas/pull.(*Puller).Pull
github.com/dolthub/dolt/go/libraries/doltcore/doltdb.pullHash
github.com/dolthub/dolt/go/libraries/doltcore/env/actions.fetchRefSpecsWithDepth
github.com/dolthub/dolt/go/libraries/doltcore/env/actions.ShallowFetchRefSpec
github.com/dolthub/dolt/go/libraries/doltcore/env/actions.shallowCloneDataPull
github.com/dolthub/dolt/go/libraries/doltcore/env/actions.CloneRemote
github.com/dolthub/dolt/go/cmd/dolt/commands.clone
```

The tail includes workers in:

```text
github.com/dolthub/dolt/go/store/datas/pull.(*PullTableFileWriter).uploadFilesAndAccumulateUpdates
github.com/dolthub/dolt/go/store/datas/pull.(*PullTableFileWriter).addChunkThread
github.com/dolthub/dolt/go/store/nbs.(*BufferedFileByteSink).backgroundWrite
```

## Safe Workaround

Until Dolt Git-remote fetch is fixed for this data ref:

- Do not run unbounded `bd dolt pull`, `bd dolt push`, `dolt fetch`, `dolt pull`, `dolt push`, or `dolt clone` against `git+https://github.com/maphew/mybd.git`.
- Before and after any bounded attempt, confirm there are no lingering processes:

```powershell
pslist bd
pslist dolt
```

- If a bounded attempt hangs, kill the process set:

```powershell
pskill bd
pskill dolt
```

- Plain `git ls-remote` and `git fetch refs/dolt/data` are safe diagnostics only. Do not use Git plumbing to manually mutate `.dolt` state.
- It is safe to skip remote bead sync only for read-only sessions or when explicitly handing off that `bd dolt push` is blocked by the upstream Dolt issue. Local bead state changes will otherwise remain stranded on this machine.

## Conclusion

This is not caused by stale `bd`, stale local schema, GitHub auth, or the existing local `.beads` database. It reproduces from a fresh clone and from a local Git mirror with Dolt `2.1.8`. The minimized upstream repro is:

```bash
dolt clone --depth 1 git+https://github.com/maphew/mybd.git mybd-clone
```

