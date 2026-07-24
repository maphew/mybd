Follow-up from the affected repo:

I ran the requested local-authoritative rewrite for the existing clone:

```powershell
bd dolt push --force
```

Result:

```text
Pushing to Dolt remote...
Push complete.
```

That completed in about 63 seconds and changed remote `refs/dolt/data`:

```text
before: a65e18b6015917b7d0c1cc8ace640c36741df905
after:  a260d364ad2b628757d879c1ee31dd0835554b1c
```

After that, the existing local clone can sync again:

```text
bd dolt pull  -> exit 0, Pull complete, about 29s
bd dolt push  -> exit 0, Push complete, about 27s
```

A later normal `bd dolt push` for a notes update also completed and advanced
`refs/dolt/data` to `cb890fa28a81e67a878a2ed8b60e7c7cdf2a8b29`.

Important limitation: a fresh clone still hangs:

```powershell
dolt clone --depth 1 git+https://github.com/maphew/mybd.git C:\Users\Matt\AppData\Local\Temp\mybd-l6ms-repaired-clone-test
```

That did not exit after a 120 second watchdog:

```json
{
  "elapsed_seconds": 120.023,
  "exited": false,
  "stdout": "cloning git+https://github.com/maphew/mybd.git"
}
```

So force-pushing from the local authoritative clone repaired routine sync for that existing clone, but did not repair the minimized fresh-clone repro. This still looks like a Dolt clone/import bug, possibly sensitive to the data shape in `refs/dolt/data`.

_codex-unknown-model-unknown-reasoning on behalf of matt wilkie_
