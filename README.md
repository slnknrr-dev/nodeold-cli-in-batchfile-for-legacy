# nodeold

[Русская версия](README_RU.md)

A single-file Windows batch launcher for legacy Node.js versions.
Drop `nodeold.cmd` next to old code and run it. The right Node.js is downloaded on first use, with no installer, no admin rights and no global changes.

```bat
nodeold app.js
```

On first run this downloads Node.js 5.12.0 (x86), unpacks it to `C:\ProgramData\nodeold.cli\5x86` and runs `app.js`. Later runs start Node.js right away.

Useful for quickly checking or running old code, and for automated setup on old machines.

## Naming

The version is picked from the **file name**. Copy or rename `nodeold.cmd`:

```
node[<v>[x<arch>]|old[<bits>]][-<util>].cmd
```

| Part | Values | Meaning |
|---|---|---|
| `<v>` | `wxp` | Node.js 5.12.0, the last for Windows XP |
| | `w7` | Node.js 13.14.0, the last for Windows 7 |
| | `w8` | Node.js 18.20.8, the last for Windows 8.1 |
| | `<n>` | the latest Node.js `<n>.x`, `n >= 4` |
| `x<arch>` | `x64`, `x86` | bitness; by default the native one |
| `old[<bits>]` | `old`, `old32`, `old64` | Node.js 5.12.0, **x86 by default** |
| *(nothing)* | `node` | the newest version already installed, see below |
| `-<util>` | any | run a tool instead of `node` (see below) |

Plain `node.cmd` (and `node-npm.cmd`, `node-<util>.cmd`) downloads nothing: it runs the newest major version already in `NODEOLD_HOME` with the native bitness (or `NODEOLD_ARCH`). For example, with `5x86`, `13x86` and `21x64` installed on a 64-bit system, `node` runs 21; with `NODEOLD_ARCH=x86` it runs 13. If nothing suitable is installed, it reports an error.

Examples:

| File name | Runs |
|---|---|
| `nodeold.cmd` | Node.js 5.12.0 x86 |
| `node.cmd` | the newest installed version, native bitness |
| `nodeold64.cmd` | Node.js 5.12.0 x64 |
| `nodewxp.cmd` | Node.js 5.12.0, native bitness |
| `nodew7.cmd`, `nodew7x86.cmd` | Node.js 13.14.0, native / x86 |
| `nodew8.cmd` | Node.js 18.20.8 |
| `node16.cmd`, `node22x64.cmd` | the latest 16.x / 22.x x64 |
| `nodew7-npm.cmd` | npm of Node.js 13.14.0 |
| `node16-eslint.cmd` | `eslint` from `node_modules\.bin` on Node.js 16 |

For `node<n>`, the exact version is resolved from `latest-v<n>.x/SHASUMS256.txt` on the mirror at install time. Versions 5, 13 and 18 are final releases and are pinned.

## Utilities: `-<util>`

```bat
nodew7-npm install
nodew7-eslint src
nodeold-gulp build
```

- `<util>` is looked up the way Node.js resolves modules: `node_modules\.bin\<util>.cmd` (or `.bat`) in the current directory, then in each parent directory, then in the Node.js directory.
- `npm` is the exception: `-npm` always runs the npm bundled with that Node.js.
- The selected Node.js directory is put first in `PATH`, so tools and child processes use the same `node`.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `NODEOLD_HOME` | `C:\ProgramData\nodeold.cli` | Where Node.js versions are stored |
| `NODEOLD_MIRROR` | `https://nodejs.org/dist` | Download mirror, same layout as nodejs.org/dist |
| `NODEOLD_ARCH` | — | `x86` or `x64`, used when the file name has no bitness |

Bitness priority: file name, then `NODEOLD_ARCH`, then x86 for `old`, then the native one.

## How it works

1. Looks for `%NODEOLD_HOME%\<major><arch>\node.exe`, for example `5x86` or `13x64`.
2. If it is missing, downloads `node-v<version>-<arch>.msi` with `curl`, or with `bitsadmin` if `curl` is missing or fails.
3. Unpacks the `.msi` with `msiexec /a` (administrative extract). Nothing is installed or registered.
4. Runs `node.exe` (or the utility) with all arguments and returns its exit code.

Only built-in `cmd` features and Windows tools are used, so it works from Windows XP onward.

## Notes

- **Windows XP / Windows 7 and HTTPS.** nodejs.org requires TLS 1.2, which XP does not support, and Windows 7 supports only with updates. If the download fails, set `NODEOLD_MIRROR` to a plain `http://` mirror, or put the Node.js files into `%NODEOLD_HOME%\<major><arch>` yourself.
- **`bitsadmin`** is not built into Windows XP (it ships with the Support Tools). There you need `curl` or a manual download.
- **Node.js 5 x64 on modern Windows.** On recent Windows 11 builds `node.exe` 5.12.0 x64 crashes as soon as it runs any JavaScript (`0xC0000005`); `--help` and `-v` still work. The x86 build works, which is why `nodeold` uses x86 by default.
- **No x86 builds for new versions.** Node.js 23 and later have no 32-bit Windows builds, so `node24x86` reports an error.
- Install directories are named `5x86`, `13x64`, `18x64`, and so on. Delete one to force a fresh download.

## License

[MIT](LICENSE) © 2026 Yury Slinkin
