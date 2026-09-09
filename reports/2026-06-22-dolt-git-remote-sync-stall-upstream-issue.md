## Summary

`dolt clone --depth 1` from a public GitHub-backed Dolt Git remote stalls indefinitely with Dolt `2.1.8`. This also blocks `dolt fetch origin` and a wrapper command, `bd dolt pull`, in the original repo.

The minimized public repro is:

```bash
dolt clone --depth 1 git+https://github.com/maphew/mybd.git mybd-clone
```

## Environment

- Dolt release: `2.1.8`
- Latest release check: `gh release view --repo dolthub/dolt` returned `v2.1.8`, published `2026-06-17T16:46:51Z`
- Windows binary: `C:\Users\Matt\scoop\apps\dolt\current\bin\dolt.exe`
- Windows shim: `C:\Users\Matt\scoop\shims\dolt.exe`
- WSL binary: `/home/linuxbrew/.linuxbrew/bin/dolt`
- Repo: `git+https://github.com/maphew/mybd.git`
- Dolt data ref: `refs/dolt/data = a65e18b6015917b7d0c1cc8ace640c36741df905`

## What Happens

On Windows:

```powershell
dolt clone --depth 1 git+https://github.com/maphew/mybd.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-clone-test
```

After a 30 second watchdog:

```json
{
  "version": "dolt version 2.1.8",
  "elapsed_seconds": 30.485,
  "exited": false,
  "stdout": "cloning git+https://github.com/maphew/mybd.git"
}
```

Direct fetch from an existing clone also stalls:

```powershell
dolt fetch origin
```

After a 30 second watchdog:

```json
{
  "version": "dolt version 2.1.8",
  "elapsed_seconds": 30.374,
  "exited": false,
  "stdout": "- Fetching..."
}
```

The same data also stalls when cloned from a local Git mirror, so this does not appear to be GitHub network/auth:

```powershell
git clone --mirror https://github.com/maphew/mybd.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-bare.git
dolt clone --depth 1 git+file:///C:/Users/Matt/AppData/Local/Temp/mybd-l6ms-bare.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-local-dolt-clone
```

Plain Git mirror succeeded; Dolt clone from the local mirror did not exit after 30 seconds.

WSL Dolt `2.1.8` also stalls:

```bash
timeout 60s dolt clone --depth 1 git+https://github.com/maphew/mybd.git mybd-clone
```

Output:

```text
stdout:
cloning git+https://github.com/maphew/mybd.git
stderr:
clone failed; terminated signal received
real 60.01
user 51.83
sys 7.36
```

The high user CPU time suggests the process is busy in Dolt-side processing rather than blocked on a network read.

## Controls

Plain Git/GitHub access is responsive:

```powershell
git ls-remote https://github.com/maphew/mybd.git HEAD refs/heads/main
gh repo view maphew/mybd --json nameWithOwner,visibility,defaultBranchRef,url
```

Plain Git can fetch the Dolt data ref in under 5 seconds:

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

## SIGQUIT Stack Excerpt

I sent SIGQUIT to the WSL Dolt process after about 15 seconds. Goroutine 1 is waiting in the puller:

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

## Expected

The clone/fetch should complete, or fail with a bounded error if the data ref is malformed.

## Actual

The command remains active until killed. On Windows it repeatedly prints the fetch spinner. On WSL it consumed almost the full 60 seconds as user CPU before `timeout` terminated it.

_codex-unknown-model-unknown-reasoning on behalf of matt wilkie_
