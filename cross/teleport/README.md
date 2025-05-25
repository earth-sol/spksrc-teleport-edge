# Teleport Cross-Compile README

This directory automates downloading, verifying, extracting, building, and staging the open-source Teleport server binary for inclusion in a Synology SPK. It relies on spksrc’s Go cross-compile framework (`spksrc.cross-go.mk`) and the native Go toolchain provided by `native/go`.

---

## Prerequisites

- A **spksrc** checkout with:
  ```
  spksrc/
  ├── cross/teleport/      ← this directory
  ├── native/go/           ← Go toolchain package
  ├── mk/                  ← shared spksrc rules
  └── toolchain/<DSM-version>/  ← DSM toolchains installed
  ```
- Linux host with `bash`, `make`, `tar`, `git`, `svn` or `hg`, and `wget` or `curl`.
- Network access to fetch Teleport source from GitHub.

---

## Directory Layout

```
cross/teleport/
├── Makefile            # orchestrates download → build → stage
├── digests             # checksums for teleport-v$(PKG_VERS).tar.gz
└── work/               # auto-generated: extraction, build, install trees
```

---

## Key Variables

Define or override on the **spksrc root** command line or in `local.mk`:

| Variable        | Meaning                                                                                  |
|-----------------|------------------------------------------------------------------------------------------|
| `PKG_NAME`      | Name of the package (default `teleport`)                                                 |
| `PKG_VERS`      | Upstream Teleport version (default `17.4.7`)                                             |
| `PKG_EXT`       | Archive extension (default `tar.gz`)                                                     |
| `PKG_DIST_SITE` | Base URL for source archives (GitHub tags)                                               |
| `PKG_DIST_NAME` | Generated tag+ext: `v$(PKG_VERS).$(PKG_EXT)`                                              |
| `PKG_DIST_FILE` | Full filename: `$(PKG_NAME)-$(PKG_DIST_NAME)`                                            |
| `PKG_DIR`       | Directory after unpack: `$(PKG_NAME)-$(PKG_VERS)`                                        |
| `GO_SRC_DIR`    | Extraction path: `$(EXTRACT_PATH)/$(PKG_DIR)`                                            |
| `GO_BIN_DIR`    | Build output dir: `$(GO_SRC_DIR)/build`                                                  |
| `CGO_ENABLED`   | Enable cgo (default `1`)                                                                  |
| `GO_LDFLAGS`    | Go linker flags (default `-s -w`)                                                         |

All variables use `?=` so that environment, `local.mk`, or command-line overrides take precedence.

---

## Build Workflow (spksrc best practices)

All commands run from the **spksrc** root directory.

### 1. Bootstrap spksrc

```bash
cd /path/to/spksrc
make setup
```

This generates `local.mk` and selects your default DSM toolchain (e.g. 7.2) under `toolchain/`.

### 2. Build the native Go toolchain

```bash
make native/go
```

This compiles the Go compiler/interpreter that will be used by cross-compile recipes.

### 3. Download and verify Teleport sources

```bash
make cross/teleport depend
```

- Fetches `teleport-v$(PKG_VERS).tar.gz` into `distrib/`.
- Validates checksums against `cross/teleport/digests`.

### 4. Extract sources

```bash
make cross/teleport extract
```

Unpacks into `cross/teleport/work/$(PKG_DIR)`.

### 5. Apply patches (if any)

```bash
make cross/teleport patch
```

None are provided by default; add `.patch` files and list them in the Makefile to modify upstream code.

### 6. Compile Teleport

```bash
make cross/teleport teleport_compile_target
```

Runs `go build` inside the extracted source, producing `work/$(PKG_DIR)/build/teleport` for each target architecture.

### 7. Stage binaries

```bash
make cross/teleport go_install_target
```

Installs the compiled `teleport` binary into `work/install/usr/local/teleport/bin`, preparing it for packaging.

### 8. Clean build artifacts

```bash
make cross/teleport clean
```

Removes `work/`, forcing a full rebuild next time.

### 9. Build for all architectures

```bash
make cross/teleport arch-all
```

Executes download → extract → patch → compile → stage for every supported GOARCH.

---

## Output

- **Compiled binaries** at `cross/teleport/work/$(PKG_DIR)/build/teleport`
- **Staging tree** at `cross/teleport/work/install/usr/local/teleport/bin/teleport`
- **PLIST** generated automatically by spksrc to list installed files

Those staging artifacts are consumed by the SPK Makefile (`spk/teleport/Makefile`) to assemble the final `.spk`.

---

## Troubleshooting

- **Missing Go toolchain**: if `native/go` fails, ensure you have C compiler and related libraries installed (GCC, libc headers).
- **Checksum errors**: after bumping `PKG_VERS`, update `cross/teleport/digests` via:
  ```bash
  make cross/teleport digests
  ```
- **`tr: when not truncating` warnings**: search for `tr 'x' ''` and change to `tr -d 'x'`.

---

## Customization

- **Version bumps**: override `PKG_VERS` on the command line:
  ```bash
  make cross/teleport PKG_VERS=17.5.0 digests arch-all
  ```
- **CGO toggle**: build without cgo via:
  ```bash
  make cross/teleport CGO_ENABLED=0 arch-all
  ```
- **Local overrides**: put any variable assignments in `local.mk` (ignored by Git).

---

## Further Reading

- **spksrc Developer HOW-TO**: https://github.com/SynoCommunity/spksrc/wiki/Developers-HOW-TO  
- **Teleport on GitHub**: https://github.com/gravitational/teleport  
- **spksrc.cross-go.mk**: see `mk/spksrc.cross-go.mk` for the full cross-compile logic  
