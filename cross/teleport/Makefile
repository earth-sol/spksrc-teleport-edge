## =============================================================================
## Teleport Cross‐Compile Makefile
## -----------------------------------------------------------------------------
## This Makefile defines how to fetch, verify, and build the Teleport Go
## source for each supported Synology architecture using spksrc’s cross‐compile
## framework. It stages the resulting `teleport` binary into $(STAGING_DIR)/bin.
## =============================================================================

# -----------------------------------------------------------------------------
# 1) Determine directories for this Makefile and the spksrc "mk" library
# -----------------------------------------------------------------------------
# MAKEFILE_PATH: absolute path to this file
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
# MAKEFILE_DIR : directory containing this file
MAKEFILE_DIR  := $(dir   $(MAKEFILE_PATH))
# MKPATH        : path to the shared mk/ directory (spksrc’s core rules)
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# -----------------------------------------------------------------------------
# 3) Package identity & source distribution variables
#    Loaded from environment or .env if set; otherwise fall back to these defaults
#    These drive the download URL, archive name, and staging directory naming.
# -----------------------------------------------------------------------------
PKG_NAME      ?= teleport
PKG_VERS      ?= 17.4.7
PKG_EXT       ?= tar.gz
PKG_DIST_NAME  = v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_FILE  = $(PKG_NAME)-$(PKG_DIST_NAME)
PKG_DIST_SITE ?= https://github.com/gravitational/teleport/archive/refs/tags
PKG_DIR        = $(PKG_NAME)-$(PKG_VERS)

# -----------------------------------------------------------------------------
# 4) Cross‐compile dependencies
# -----------------------------------------------------------------------------
# Ensure Go toolchain is available to build the source.
DEPENDS       = native/go

# -----------------------------------------------------------------------------
# 5) Metadata for build logs & package manifest
# -----------------------------------------------------------------------------
HOMEPAGE      = https://github.com/gravitational/teleport
COMMENT      ?= "Teleport provides simple secure access to SSH servers, Kubernetes clusters, PostgreSQL databases and web apps behind NAT, in any environment."
LICENSE       = AGPL-3.0

# -----------------------------------------------------------------------------
# 6) Architectures we explicitly do NOT support
# -----------------------------------------------------------------------------
UNSUPPORTED_ARCHS = $(PPC_ARCHS) $(ARMv5_ARCHS) $(i686_ARCHS) $(ARMv7L_ARCHS)

# -----------------------------------------------------------------------------
# 7) Define Go source and output paths
# -----------------------------------------------------------------------------
# EXTRACT_PATH   : where spksrc unpacks the archive
# $(PKG_DIR)     : top‐level directory inside the tarball
# GO_SRC_DIR     : full path to the Go module root
# GO_BIN_DIR     : pathglob for the built binaries under build/
GO_SRC_DIR    = $(EXTRACT_PATH)/$(PKG_DIR)
GO_BIN_DIR    = $(GO_SRC_DIR)/build/*

# -----------------------------------------------------------------------------
# 8) Go build environment and ldflags
# -----------------------------------------------------------------------------
CGO_ENABLED   = 1              # enable cgo (required by some Teleport subsystems)
GO_LDFLAGS    = -s -w          # strip symbol table and debug info

# -----------------------------------------------------------------------------
# 9) Define the default compile target
# -----------------------------------------------------------------------------
COMPILE_TARGET = teleport_compile_target

# -----------------------------------------------------------------------------
# 10) Pull in spksrc’s cross‐compile rules for Go
# -----------------------------------------------------------------------------
include $(MKPATH)/spksrc.cross-go.mk

# -----------------------------------------------------------------------------
# Build target: compile and stage the `teleport` server binary
# -----------------------------------------------------------------------------
teleport_compile_target:
	@echo "===> Building Teleport v$(PKG_VERS) for $(GO_ARCH) (GOARM=$(GOARM))"
	$(RUN) sh -c 'cd $(GO_SRC_DIR) && CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=$(GO_ARCH) GOARM=$(GOARM) go build -trimpath -ldflags "$(GO_LDFLAGS)" -o $(STAGING_DIR)/bin/teleport ./lib'
