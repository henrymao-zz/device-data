# device-data

Debian packaging of SONiC device configuration data, sourced from the
[sonic-buildimage](https://github.com/sonic-net/sonic-buildimage) `202405`
branch (`device/` directory).

## Build & upload

A `Makefile` drives the full workflow: fetching upstream, building the
source package, and uploading to the PPA.

| Target   | Description                                                        |
| -------- | ----------------------------------------------------------------- |
| `make`   | Alias for `build upload`.                                          |
| `fetch`  | Sparse-clone `device/` from the upstream `202405` branch.          |
| `prepare`| Flatten `device/<vendor>/<platform>` -> `device/<platform>` into `build/`. |
| `build`  | Create the `.orig.tar.xz` and run `debuild -S`.                    |
| `upload` | `dput` the signed source package to the PPA.                       |
| `clean`  | Remove `build/`, `device/`, and temp dirs.                         |

### Quick start

```bash
make            # build + upload to the PPA
make build      # build only, no upload
make clean
```

### Configuration

Defaults live at the top of the `Makefile`:

- `BRANCH`        — upstream branch (`202405`)
- `PPA`           — target PPA (`ppa:henrymao/ubuntu-nos`)
- `GPG_KEY`       — signing key id
- `RELEASE`       — target Ubuntu series (defaults to `lsb_release -cs`)

Override on the command line, e.g. `make RELEASE=noble`.

## Install path

The package installs all device data to `/usr/share/sonic/device/<platform>/`.
