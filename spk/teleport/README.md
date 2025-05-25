```markdown
# Teleport SPK

This directory contains everything needed to package the open-source Teleport server agent into a Synology `.spk`. The resulting package installs on DSM 7.2 (and later), turning your NAS into a Teleport node with SSH reverse-tunnel, Application proxy, and Database proxy services—all managed via DSM’s Package Center.

---

## Table of Contents

1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Directory Layout](#directory-layout)  
4. [Building the SPK](#building-the-spk)  
5. [Testing Locally](#testing-locally)  
6. [Installer Wizard](#installer-wizard)  
7. [Configuration & Data Paths](#configuration--data-paths)  
8. [Service Hooks](#service-hooks)  
9. [Upgrade & Backup](#upgrade--backup)  
10. [Uninstall Options](#uninstall-options)  
11. [Best Practices](#best-practices)  
12. [Customization & Overrides](#customization--overrides)  
13. [CI/CD Integration](#cicd-integration)  
14. [Further Reading](#further-reading)  

---

## Overview

The Teleport SPK bundles the **Teleport server binary** (built via `cross/teleport`) and integrates it with DSM’s packaging framework. It provides:

- **SSH Service**  
  Runs Teleport’s SSH server on your NAS and maintains an outbound reverse tunnel to your trusted Proxy.

- **Application Service**  
  Exposes the DSM Control Panel UI and can dynamically register cluster-defined web apps.

- **Database Service**  
  Optionally imports all Teleport-managed database endpoints for secure access.

- **Full lifecycle management**  
  Install, start, stop, restart, in-place upgrade, backup/restore, and uninstall (with optional data retention).

---

## Prerequisites

- A **spksrc** checkout with:
  ```
  spksrc/
  ├── cross/teleport/      ← cross-compile rules and Go build
  ├── spk/teleport/        ← this directory
  └── mk/                  ← shared spksrc rules
  ```
- A working **Go** toolchain under `native/go`.  
- DSM 7.2 or later installed on your Synology NAS.  
- A valid Teleport cluster with publicly-trusted TLS certs (so you can skip CA pin).

---

## Directory Layout

```
spk/teleport/
├── Makefile               # SPK packaging rules
├── conf/
│   ├── install_uifile     # JSON definition of the installer wizard
│   └── privilege          # DSM permission settings (runs as root)
├── src/
│   ├── service-setup.sh   # install/upgrade/uninstall/backup hooks
│   └── teleport.sc        # optional firewall rule definitions
└── README.md              # (you are here)
```

---

## Building the SPK

Run all commands from the **spksrc root**:

1. **Bootstrap spksrc**  
   ```bash
   cd /path/to/spksrc
   make setup
   ```
2. **Cross-compile Teleport**  
   ```bash
   make -C cross/teleport arch-all
   ```
3. **Package into .spk**  
   ```bash
   make -C spk/teleport
   ```
4. The resulting `.spk` lives under `spk/teleport/output/`, ready for DSM.

---

## Testing Locally

Before uploading to DSM:

- **Install the SPK** on a test NAS using Package Center’s *Manual Install*.  
- **Enable verbose logs** by setting `LOG_LEVEL=debug` in the wizard to troubleshoot startup issues.  
- **Verify services**:
  ```bash
  synopkg status teleport
  tail -f /var/log/packages/teleport.log
  ```
- **Test SSH**:
  ```bash
  ssh -p 3022 <node_name>@<proxy_address>
  ```

---

## Installer Wizard

Collects configuration via DSM’s UI (defined in `conf/install_uifile`):

1. **Cluster settings**  
   - `node_name`  
   - `proxy_address` (e.g. `teleport.example.com:443`)  
   - `join_token`  
   - Optional `ca_pin` (leave blank to trust system CAs)

2. **DSM UI & SSH Service**  
   - `dsm_ui_address` (e.g. `localhost:5001`)  
   - `enable_ssh_service`  
   - `ssh_listen_address`  
   - `ssh_public_address`

3. **Storage paths**  
   - `config_dir`  
   - `data_dir`

4. **Dynamic resources**  
   - `enable_dynamic_apps`  
   - `enable_dynamic_databases`

5. **Cleanup**  
   - `remove_config_data`

Wizard variables map directly into `service-setup.sh`.

---

## Configuration & Data Paths

- **`teleport.yaml`** is generated to:
  - `${config_dir}` if set, otherwise `/var/packages/teleport/etc/teleport.yaml`.
- **Data directory**:
  - `${data_dir}` if set, otherwise the package var folder.
- Both paths are auto-created at install time.

---

## Service Hooks

`src/service-setup.sh` implements:

- **service_preinst**: no-op on DSM7+  
- **service_postinst**: writes `teleport.yaml` and creates dirs  
- **service_preupgrade** / **service_postupgrade**: backup & restore  
- **service_preuninst** / **service_postuninst**: optional cleanup  
- **service_save** / **service_restore**: tarball backup under `${SYNOPKG_PKGVAR}/backup`

---

## Upgrade & Backup

- **In-place upgrades** preserve all settings and data.  
- **Reinstall with data**: uninstall without “Remove data” then install.  
- **Full purge**: check “Remove configuration and data” in DSM.  
- **Backups**: manually invoke `synopkg backup teleport` if supported.

---

## Uninstall Options

DSM’s Package Center “Remove configuration and data” checkbox or wizard’s `remove_config_data` flag allows full cleanup of custom paths.

---

## Best Practices

- **Keep variables in Makefiles** with `?=` defaults; avoid inline `.env` parsing.  
- **Use `local.mk`** for site-specific overrides, never commit it.  
- **Split cross vs. SPK logic**: `cross/` only defines `PKG_*`; `spk/` only defines `SPK_*`.  
- **Test each DSM rebuild** in a VM or secondary NAS before production.  
- **Use semantic versioning**: bump `SPK_REV` for packaging tweaks without upstream changes.  
- **Automate checksum updates** by running `make digests` in `cross/teleport` when upgrading Teleport.

---

## Customization & Overrides

- **Command-line overrides**:
  ```bash
  make -C cross/teleport PKG_VERS=17.5.0 arch-all
  make -C spk/teleport SPK_REV=3
  ```
- **local.mk** overrides (ignored by Git):
  ```makefile
  PKG_VERS = 17.5.0
  SPK_REV  = 3
  ```
- **Wizard tweaks**: modify `conf/install_uifile` and adjust `service-setup.sh` accordingly.

---

## CI/CD Integration

- **Lint your Makefiles**:
  ```bash
  make -C cross/teleport -n
  make -C spk/teleport    -n
  ```
- **Automate builds** in your CI pipeline:
  ```bash
  git checkout release-17.5.0
  make setup
  make native/go cross/teleport arch-all spk/teleport
  ```
- **Archive artifacts**: store `.spk` and `digests` as build outputs for reproducibility.

---

## Further Reading

- SynoCommunity spksrc **Developer HOW-TO**  
- Teleport **Configuration Reference**: https://goteleport.com/docs/reference/config  
- spksrc.cross-go.mk & spksrc.spk.mk for advanced packaging hooks  
```