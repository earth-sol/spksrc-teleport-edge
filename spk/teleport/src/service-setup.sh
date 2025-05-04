#!/bin/sh
#
# Teleport SPK service hooks
# Integrates spksrc’s generic installer and start-stop-status to manage
# install, upgrade, uninstall, backup, and restore on DSM.
#

# Path to the Teleport server binary (built in the cross-compile stage)
TELEPORT="${SYNOPKG_PKGDEST}/bin/teleport"
# Command invoked by the start-stop-status wrapper
SERVICE_COMMAND="${TELEPORT} start -c ${CONF_FILE} --pid-file=${PID_FILE}"
# Run the service in the background
SVC_BACKGROUND=y

# -----------------------------------------------------------------------------
# Pre-install hook
#   Runs before package files are laid down. Return non-zero to abort.
#   On DSM7+, we have no special pre-install requirements.
# -----------------------------------------------------------------------------
service_preinst() {
  echo "noop"
}

# -----------------------------------------------------------------------------
# Post-install hook
#   Generates teleport.yaml from installer inputs and ensures
#   config & data directories exist.
# -----------------------------------------------------------------------------
service_postinst() {
  [ "${SYNOPKG_PKG_STATUS}" != "INSTALL" ] && return

  # 1) Determine config directory
  if [ -n "${config_dir}" ]; then
    CONFIG_DIR="${config_dir}"
  else
    CONFIG_DIR="/var/packages/${SYNOPKG_PKGNAME}/etc"
  fi
  CONF_FILE="${CONFIG_DIR}/teleport.yaml"

  # 2) Determine data directory
  if [ -n "${data_dir}" ]; then
    DATA_DIR="${data_dir}"
  else
    DATA_DIR="${SYNOPKG_PKGVAR}"
  fi

  # 3) Create directories if missing
  mkdir -p "${CONFIG_DIR}" || { echo "ERROR: cannot create ${CONFIG_DIR}"; exit 1; }
  mkdir -p "${DATA_DIR}"   || { echo "ERROR: cannot create ${DATA_DIR}"; exit 1; }

  # 4) Default node_name to hostname if unset
  NODE="${node_name:-$(hostname)}"

  # 5) Write Teleport YAML config
  {
    # --- Core cluster settings ---
    echo "version: v3"
    echo "teleport:"
    echo "  nodename: ${NODE}"
    echo "  data_dir: ${DATA_DIR}"
    echo "  auth_token: ${join_token}"
    if [ -n "${ca_pin}" ]; then
      echo "  ca_pin: ${ca_pin}"
    fi
    echo "  proxy_server: ${proxy_address}"
    echo ""

    # --- SSH Service ---
    echo "ssh_service:"
    if [ "${enable_ssh_service}" = "true" ]; then
      echo "  enabled: true"
      echo "  listen_addr: ${ssh_listen_address:-0.0.0.0:3022}"
      [ -n "${ssh_public_address}" ] && echo "  public_addr: ${ssh_public_address}"
    else
      echo "  enabled: false"
    fi
    echo ""

    # --- Application Service ---
    echo "app_service:"
    echo "  enabled: true"
    echo "  apps:"
    echo "  - name: \"${NODE}-dsm-ui\""
    echo "    uri: \"https://${dsm_ui_address}\""
    echo "    description: \"DSM Control Panel UI\""
    echo "    insecure_skip_verify: true"
    if [ "${enable_dynamic_apps}" = "true" ]; then
      echo "  resources:"
      echo "  - labels:"
      echo "      \"*\": \"*\""
    fi
    echo ""

    # --- Database Service ---
    echo "db_service:"
    if [ "${enable_dynamic_databases}" = "true" ]; then
      echo "  enabled: true"
      echo "  resources:"
      echo "  - labels:"
      echo "      \"*\": \"*\""
    else
      echo "  enabled: false"
    fi
  } > "${CONF_FILE}"
}

# -----------------------------------------------------------------------------
# Pre-upgrade hook
#   Snapshot config & data before replacing files.
# -----------------------------------------------------------------------------
service_preupgrade() {
  service_save
}

# -----------------------------------------------------------------------------
# Post-upgrade hook
#   Restore config & data after the new files are in place.
# -----------------------------------------------------------------------------
service_postupgrade() {
  service_restore
}

# -----------------------------------------------------------------------------
# Pre-uninstall hook
#   No action needed before removal by default.
# -----------------------------------------------------------------------------
service_preuninst() {
  [ "${SYNOPKG_PKG_STATUS}" != "UNINSTALL" ] && return
}

# -----------------------------------------------------------------------------
# Post-uninstall hook
#   Remove config/data if the user chose to purge them.
# -----------------------------------------------------------------------------
service_postuninst() {
  [ "${SYNOPKG_PKG_STATUS}" != "UNINSTALL" ] && return
  if [ "${remove_config_data}" = "true" ]; then
    rm -rf "${config_dir:-/var/packages/${SYNOPKG_PKGNAME}/etc}"
    rm -rf "${data_dir:-${SYNOPKG_PKGVAR}}"
  fi
}

# -----------------------------------------------------------------------------
# Backup hook (service_save)
#   Creates a timestamped tarball of both config and data.
# -----------------------------------------------------------------------------
service_save() {
  LOG="/var/log/packages/${SYNOPKG_PKGNAME}.log"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backing up Teleport config & data" >> "$LOG"
  BDIR="${SYNOPKG_PKGVAR}/backup"
  mkdir -p "$BDIR"
  tar czf "${BDIR}/teleport-backup-$(date +%Y%m%d%H%M%S).tgz" \
      -C "$(dirname "$CONF_FILE")" "$(basename "$CONF_FILE")" \
      -C "$DATA_DIR" .
}

# -----------------------------------------------------------------------------
# Restore hook (service_restore)
#   Extracts the most recent backup tarball.
# -----------------------------------------------------------------------------
service_restore() {
  LOG="/var/log/packages/${SYNOPKG_PKGNAME}.log"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restoring Teleport Edge config & data" >> "$LOG"
  BACKUP=$(ls -1t "${SYNOPKG_PKGVAR}/backup"/teleport-backup-*.tgz 2>/dev/null | head -1)
  [ -f "$BACKUP" ] && tar xzf "$BACKUP" -C /
}

# End of service-setup.sh
