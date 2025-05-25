## =============================================================================
## Teleport SPK Makefile
## =============================================================================

# 1) Locate this Makefile and the spksrc mk directory
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# 2) Package metadata and defaults
SPK_NAME     ?= teleport
SPK_VERS     ?= 17.4.7
SPK_REV      ?= 2
DISPLAY_NAME ?= Teleport
DESCRIPTION  ?= Teleport provides secure SSH, Application, and Database access on DSM
CHANGELOG    ?= Broad updates across multiple upstream
MAINTAINER   ?= earth-sol

# 3) Icon, license, and SPK extension
SPK_ICON     := src/teleport.png
LICENSE      := AGPL-3.0
PKG_EXT      ?= spk

# 4) Runtime dependency on the cross-built binary
DEPENDS      := cross/teleport

# 5) Service control configuration
SERVICE_USER  := auto
SERVICE_SETUP := src/service-setup.sh
STARTABLE     := yes

# 6) Installer wizard directory
WIZARDS_DIR   := conf

# 7) Include the generic spksrc SPK build rules
include $(MKPATH)/spksrc.spk.mk