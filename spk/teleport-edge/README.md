# Teleport Edge SPK

This directory contains everything needed to package the Teleport server agent into a Synology `.spk`. Once built, the resulting package can be installed on DSM 7.2 (and later) to turn your NAS into a Teleport node—with SSH, Application, and Database proxy capabilities—and full lifecycle hooks.

---

## Table of Contents

1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Directory Layout](#directory-layout)  
4. [Building the SPK](#building-the-spk)  
5. [Installer Wizard](#installer-wizard)  
6. [Configuration & Data Paths](#configuration--data-paths)  
7. [Service Hooks](#service-hooks)  
8. [Upgrade & Backup](#upgrade--backup)  
9. [Uninstall Options](#uninstall-options)  
10. [Permissions & Privileges](#permissions--privileges)  
11. [Firewall Considerations](#firewall-considerations)  
12. [Customization & Maintenance](#customization--maintenance)  
13. [Further Reading](#further-reading)  

---

## Overview

The Teleport Edge SPK bundles the **Teleport server binary** (compiled via `cross/teleport-edge`) and integrates it with Synology DSM. It provides:

- **SSH Service** with built-in reverse-tunnel support  
- **Application Service** exposing the DSM Control Panel UI plus optional dynamic app registration  
- **Database Service** with optional dynamic database registration  
- **Full lifecycle**: install, start/stop/restart, in-place upgrade, backup/restore, and uninstall (with optional data retention)  

---

## Prerequisites

- A working **spksrc** checkout with:
  ```
  spksrc/
  ├── cross/teleport-edge/  # builds the Teleport server binary
  ├── spk/teleport-edge/    # this directory
  └── mk/                   # spksrc core rules
  ```
- **Go** toolchain available for the cross-compile stage  
- Internet access (or local mirror) to fetch the Teleport source tarball  
- Synology DSM 7.2 (or later) for package installation  

---

## Directory Layout

```
spk/teleport-edge/
├── Makefile            # SPK packaging rules
├── conf/
│   ├── install_uifile  # JSON installer wizard definition
│   └── privilege       # DSM privilege settings
├── src/
│   └── service-setup.sh  # install/upgrade/uninstall/backup hooks
└── README.md           # (you are here)
```

---

## Building the SPK

1. **Cross-compile** the Teleport server binary:
   ```bash
   cd spksrc/cross/teleport-edge
   make digests         # regenerate checksums if updating version
   make arch-all        # build for all target architectures
   ```
2. **Package** into a `.spk`:
   ```bash
   cd spksrc/spk/teleport-edge
   make                 # invokes spksrc.spk.mk to assemble the SPK
   ```
3. The built `output/teleport-edge-<version>.spk` can then be uploaded to DSM via Package Center.

---

## Installer Wizard

During installation, DSM presents a multi-step wizard (defined in `conf/install_uifile`):

1. **Cluster Settings**  
   - **Node name** (`node_name`)  
   - **Proxy address** (`proxy_address`)  
   - **Join token** (`join_token`)  
   - **CA pin (optional)** (`ca_pin`)  

2. **DSM UI & SSH Service**  
   - **DSM UI address** (`dsm_ui_address`)  
   - **Enable SSH service** (`enable_ssh_service`)  
   - **SSH listen address** (`ssh_listen_address`)  
   - **SSH public address** (`ssh_public_address`)  

3. **Configuration & Data Paths**  
   - **Config directory** (`config_dir`)  
   - **Data directory** (`data_dir`)  

4. **Dynamic Resource Discovery**  
   - **Enable dynamic app registration** (`enable_dynamic_apps`)  
   - **Enable dynamic database registration** (`enable_dynamic_databases`)  

5. **Cleanup Options**  
   - **Remove config & data on uninstall** (`remove_config_data`)  

All of these keys are exported into `service-setup.sh` and drive the generated `teleport.yaml`.

---

## Configuration & Data Paths

- **`teleport.yaml`** is written to:
  - the user-specified **`config_dir`**, or  
  - `/var/packages/${SPK_NAME}/etc/teleport.yaml` by default  
- **Data** is stored under:
  - the user-specified **`data_dir`**, or  
  - `${SYNOPKG_PKGVAR}` by default  
- Both directories are created automatically if they don’t already exist.

---

## Service Hooks

The `src/service-setup.sh` script handles every lifecycle event:

- **service_preinst**: pre-install sanity check (no-op on DSM7+)  
- **service_postinst**: writes `teleport.yaml`, sets up SSH, App & DB services  
- **service_preupgrade** / **service_postupgrade**: backup and restore config/data  
- **service_preuninst** / **service_postuninst**: cleanup based on `remove_config_data`  
- **service_save** / **service_restore**: manual backup/restore under `${SYNOPKG_PKGVAR}/backup`

---

## Upgrade & Backup

- **In-place upgrades** preserve all configuration and data automatically.  
- **Full uninstall/reinstall** honors the “Remove config & data” option in the wizard or the DSM remove-data checkbox.  
- Backups are timestamped tarballs of both `teleport.yaml` and the data directory.

---

## Uninstall Options

DSM’s Package Center offers a “Remove configuration and data” checkbox. The wizard’s **`remove_config_data`** setting provides additional control over custom paths.

---

## Permissions & Privileges

The `conf/privilege` file configures all hooks and the Teleport daemon to run as **root**, which is required to bind privileged ports (SSH, HTTPS).

---

## Firewall Considerations

Teleport agents use **outbound** reverse tunnels to the Proxy—**no inbound firewall rules** are required on the NAS for cluster connectivity.

---

## Customization & Maintenance

- **Bump version**: update `teleport-edge.env`, run `make digests` in `cross/teleport-edge`, then rebuild.  
- **Adjust wizard**: edit `conf/install_uifile` to add or rename installer fields and update `service-setup.sh` accordingly.  
- **Modify service behavior**: update `src/service-setup.sh` hooks.  
- **Change package contents**: edit `spk/teleport-edge/Makefile` or add scripts under `src/`.

---

## Further Reading

- SynoCommunity spksrc **Developer HOW-TO** guide  
- Teleport **Configuration Reference**: https://goteleport.com/docs/reference/config  
- Teleport **Dynamic Registration** docs (Apps & Databases)  
- Teleport **SSH Service** & **Reverse Tunnel** design  
