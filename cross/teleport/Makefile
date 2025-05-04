## =============================================================================
## Teleport Cross-Compile Makefile
## =============================================================================

# 1) Derive this Makefile’s directory and the shared spksrc mk directory
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# 2) Teleport source‐archive identity and download settings
PKG_NAME      ?= teleport
PKG_VERS      ?= 17.4.7
PKG_EXT       ?= tar.gz
PKG_DIST_SITE ?= https://github.com/gravitational/teleport/archive/refs/tags
PKG_DIST_NAME ?= v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_FILE ?= $(PKG_NAME)-$(PKG_DIST_NAME)
PKG_DIR       ?= $(PKG_NAME)-$(PKG_VERS)

# 3) Build dependency: ensure Go toolchain is built first
DEPENDS       := native/go

# 4) Upstream metadata for Teleport
HOMEPAGE      := https://github.com/gravitational/teleport
COMMENT       := Teleport provides secure SSH, application, and database proxy
LICENSE       := AGPL-3.0

# 5) Teleport does not support these architectures
UNSUPPORTED_ARCHS := $(PPC_ARCHS) $(ARMv5_ARCHS) $(i686_ARCHS) $(ARMv7L_ARCHS)

# 6) Paths for source extraction and build output
GO_SRC_DIR    = $(EXTRACT_PATH)/$(PKG_DIR)
GO_BIN_DIR    := $(GO_SRC_DIR)/build

# 7) Go build environment variables
CGO_ENABLED   := 1
GO_LDFLAGS    := -s -w

# 8) Tell spksrc.cross-go.mk which target to invoke
COMPILE_TARGET := teleport_compile_target

# 9) Pull in spksrc’s Go cross‐compile framework
include $(MKPATH)/spksrc.cross-go.mk

# 10) Default goal: build the Go toolchain if needed, then Teleport end-to-end
.DEFAULT_GOAL := all

# 11) Path to the native/go package for building Go
NATIVE_GO_DIR := $(realpath $(MAKEFILE_DIR)/../../native/go)

# 12) Top-level workflow: build Go → fetch+verify → extract → patch → compile → stage
all: native_go download checksum extract patch teleport_compile_target go_install_target

# 13) Build the native Go toolchain if not already
native_go:
	$(MAKE) -C $(NATIVE_GO_DIR)

# 14) Compile Teleport OSS with Community UI assets
teleport_compile_target:
	@echo "===> Building Teleport v$(PKG_VERS) (OSS) for $(GO_ARCH)" ; $(RUN) sh -c 'cd $(GO_SRC_DIR) && mkdir -p build && for bin in teleport teleport-update tsh tctl tbot; do echo " ... building $$bin"; CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=$(GO_ARCH) go build -trimpath -ldflags "$(GO_LDFLAGS)" -o build/$$bin ./tool/$$bin; done'

## 15) Stage step: install each OSS binary into the staging area
go_install_target:
	@echo "===> Installing Teleport OSS binaries" ; \
	install -m755 -d $(STAGING_INSTALL_PREFIX)/bin ; \
	for bin in teleport teleport-update tsh tctl tbot; do \
	  install -m755 $(GO_SRC_DIR)/build/$$bin $(STAGING_INSTALL_PREFIX)/bin/ ; \
	done
	