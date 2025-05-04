```markdown
# Teleport Cross‐Compile Package

This directory contains the **spksrc** cross‐compile rules and support files for building the Teleport Go server binary for Synology NAS (multiple architectures). It produces a standalone `teleport` executable that will later be packaged into the SPK.

---

## Table of Contents

1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Directory Layout](#directory-layout)  
4. [Environment Configuration](#environment-configuration)  
5. [Version & Sources](#version--sources)  
6. [Digests & Verification](#digests--verification)  
7. [Building for Architectures](#building-for-architectures)  
8. [PLIST](#plist)  
9. [Cleaning & Maintenance](#cleaning--maintenance)  
10. [Troubleshooting](#troubleshooting)  
11. [Contributing](#contributing)  

---

## Overview

The `cross/teleport-edge` subdirectory defines how to:

- Download the Teleport source archive (`teleport-v$(SPK_VERS).tar.gz`).  
- Verify its integrity against checksums in `digests`.  
- Cross‐compile the Go code for each target Synology CPU/OS using `spksrc.cross-go.mk`.  
- Stage the resulting `teleport` binary under `$(STAGING_DIR)/bin/teleport`.  

Once built, these binaries are picked up by the `spk/teleport` packaging step.

---

## Prerequisites

- **spksrc checkout** with the `mk/` directory at the same level as `cross/` and `spk/`.  
- **Go toolchain** installed in the host environment (`go` binary in `PATH`).  
- **Make** (GNU Make) and **bash** support.  
- **Internet access** (to fetch GitHub tarball) or a local mirror of `teleport-v$(SPK_VERS).tar.gz`.

---

## Directory Layout

```
cross/teleport-edge/
├── Makefile         # Cross-build instructions
├── digests          # SHA1, SHA256, MD5 sums for source archives
├── PLIST            # Files to stage into the binary package
└── README.md        # This document
```

- **Makefile**  
  Implements steps 1–2 of the spksrc workflow: environment loading, metadata definition, and inclusion of `spksrc.cross-go.mk`.  
- **digests**  
  Contains checksums for the Teleport source tarball. Required for spksrc to verify downloads.  
- **PLIST**  
  Lists which files (e.g. `bin/teleport`) to retain in the staging area before packaging.  

---

## Environment Configuration

Two levels of configuration are supported via `.env` files:

1. **Global defaults** in `../../teleport.env`:
   ```env
   SPK_NAME=teleport
   SPK_VERS=17.4.7
   SPK_REV=2
   PKG_EXT=tar.gz
   MAINTAINER=earth-sol
   DESCRIPTION="Teleport provides secure SSH, App, and Database access..."
   DISPLAY_NAME=Teleport Edge
   CHANGELOG="\"Initial build\""
   PKG_DIST_SITE=https://github.com/gravitational/teleport/archive/refs/tags
   ```
2. **Local overrides** in `cross/teleport-edge/.env` (optional):
   ```env
   SPK_VERS=17.4.8
   ```
   
The Makefile loads `ENV_ROOT` first (using `?=` assignments) so that environment‐exported variables are not overridden, then applies `ENV_LOCAL` overrides unless they were passed via the shell.

---

## Version & Sources

- **`PKG_VERS`** controls which GitHub tag is used (e.g. `v17.4.7`).  
- **`PKG_DIST_SITE`** must point to a URL where `$(PKG_NAME)-v$(PKG_VERS).$(PKG_EXT)` can be downloaded.  
- **`PKG_DIST_NAME`** and **`PKG_DIST_FILE`** derive the archive name and local filename.

---

## Digests & Verification

1. After bumping `PKG_VERS`, run:
   ```bash
   cd cross/teleport-edge
   make digests
   ```
   This will:
   - Download the new tarball
   - Compute SHA1, SHA256, and MD5
   - Update `digests` accordingly

2. **Commit** the updated `digests` file before building.

---

## Building for Architectures

To build for a single architecture (e.g. `arch-x64-7.2`):

```bash
cd cross/teleport-edge
make arch-x64-7.2
```

To build for all supported architectures:

```bash
cd cross/teleport-edge
make arch-all
```

Successful builds will place `bin/teleport` under each architecture’s staging directory.

---

## PLIST

Ensure `PLIST` contains only the files you want in the final SPK:

```
bin:bin/teleport
```

- `bin:` prefix indicates the destination path within the SPK (`/usr/local/bin/teleport`).  
- Any entries not present in staging will cause the build to error.

---

## Cleaning & Maintenance

- **Clean a single arch**:
  ```bash
  make clean-arch-x64-7.2
  ```
- **Prune all work directories**:
  ```bash
  make clean-all
  ```
- **Re-run digests** (if needed):
  ```bash
  make digests
  ```

---

## Troubleshooting

- **Checksum mismatch**: Verify `digests` matches the actual tarball.  
- **Missing Go binary**: Ensure `go version` is available and satisfies Teleport’s requirements (Go 1.20+).  
- **Cross-compile failures**: Confirm `native/go` dependency installed via spksrc’s `bootstrap` rules.

---

## Contributing

- **Update `digests`** via `make digests`.  
- **Run full build**: `make arch-all`.  
- **Verify** staging binaries and PLIST.  
- **Submit PR** with changes to `Makefile`, `digests`, and `PLIST` as needed.
