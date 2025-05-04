## =============================================================================
## Teleport SPK Makefile
## -----------------------------------------------------------------------------
## This Makefile orchestrates the packaging of the Teleport SPK:
##   - Loads shared metadata from teleport.env and applies local overrides
##   - Declares dependency on the cross-compiled Teleport binary
##   - Configures service control (start/stop/status) via spksrc’s hooks
##   - Includes the installer wizard definitions and DSM privilege settings
## =============================================================================

# -----------------------------------------------------------------------------
# 1) Locate this Makefile and spksrc’s "mk" library
#    MAKEFILE_PATH: absolute path to this Makefile
#    MAKEFILE_DIR : directory containing this file
#    MKPATH        : path to the core spksrc mk/ directory
# -----------------------------------------------------------------------------
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir   $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# -----------------------------------------------------------------------------
# 3) Package metadata (from .env or environment, with defaults)
#    - SPK_NAME, SPK_VERS, SPK_REV: package identity and versioning
#    - DISPLAY_NAME, DESCRIPTION, CHANGELOG, MAINTAINER: UI and documentation
# -----------------------------------------------------------------------------
SPK_NAME     ?= teleport
SPK_VERS     ?= 17.4.7
SPK_REV      ?= 2
DISPLAY_NAME ?= "Teleport"
DESCRIPTION  ?= "Teleport provides simple secure access to SSH servers, Kubernetes clusters, PostgreSQL databases and web apps behind NAT, in any environment."
CHANGELOG    ?= "Broad updates across multiple upstream"
MAINTAINER   ?= earth-sol

# -----------------------------------------------------------------------------
# 4) Icon, license, and extension
#    - SPK_ICON: path to the package icon
#    - LICENSE : SPDX license identifier
#    - PKG_EXT : file extension for archives (from .env/env, with defaults)
# -----------------------------------------------------------------------------
SPK_ICON     = src/teleport.png
LICENSE      = AGPL-3.0
PKG_EXT     ?= tar.gz

# -----------------------------------------------------------------------------
# 5) Runtime dependency on the cross-compiled Teleport binary
#    DEPENDS ensures cross/teleport is built before packaging
# -----------------------------------------------------------------------------
DEPENDS      = cross/teleport

# -----------------------------------------------------------------------------
# 6) Service control configuration
#    - SERVICE_USER  : identity under which Teleport runs (root for privileged ports)
#    - SERVICE_SETUP : path to the service-setup.sh hooks
#    - STARTABLE     : enable generation of start/stop/status scripts
# -----------------------------------------------------------------------------
SERVICE_USER  = root
SERVICE_SETUP = src/service-setup.sh
STARTABLE     = yes

# -----------------------------------------------------------------------------
# 7) Installer wizard directory
#    WIZARDS_DIR points spksrc at the conf/install_uifile JSON definitions
# -----------------------------------------------------------------------------
WIZARDS_DIR   = conf

# -----------------------------------------------------------------------------
# 8) Include the spksrc SPK build rules to assemble the final .spk
# -----------------------------------------------------------------------------
include $(MKPATH)/spksrc.spk.mk
