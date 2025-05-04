## =============================================================================
## Teleport Cross-Compile Makefile
## =============================================================================

# Derive this Makefile’s directory and the shared spksrc mk directory
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir   $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# Teleport source‐archive identity and download settings
PKG_NAME      ?= teleport
PKG_VERS      ?= 17.4.7
PKG_EXT       ?= tar.gz
PKG_DIST_SITE ?= https://github.com/gravitational/teleport/archive/refs/tags
PKG_DIST_NAME ?= v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_FILE ?= $(PKG_NAME)-$(PKG_DIST_NAME)
PKG_DIR       ?= $(PKG_NAME)-$(PKG_VERS)

# Build dependency: ensure Go toolchain is built first
DEPENDS       := native/go

# Upstream metadata for Teleport
HOMEPAGE      := https://github.com/gravitational/teleport
COMMENT       := Teleport provides secure SSH, application, and database proxy
LICENSE       := AGPL-3.0

# Teleport does not support these architectures
UNSUPPORTED_ARCHS := $(PPC_ARCHS) $(ARMv5_ARCHS) $(i686_ARCHS) $(ARMv7L_ARCHS)

# Go build environment variables
CGO_ENABLED   := 1
GO_LDFLAGS    := -s -w

# Tell spksrc.cross-go.mk which target to invoke
COMPILE_TARGET := teleport_compile_target

# Pull in spksrc’s Go cross‐compile framework
include $(MKPATH)/spksrc.cross-go.mk

# Paths for source extraction and build output
GO_SRC_DIR    := $(EXTRACT_PATH)/$(PKG_DIR)
GO_BIN_DIR    := $(GO_SRC_DIR)/build

# Default goal: build the Go toolchain if needed, then Teleport end-to-end
.DEFAULT_GOAL := all

# Path to the native/go package for building Go
NATIVE_GO_DIR := $(realpath $(MAKEFILE_DIR)/../../native/go)

# Top-level workflow: build Go → fetch+verify → extract → patch → compile → stage
all: native_go download checksum extract patch teleport_compile_target go_install_target

# Build the native Go toolchain if not already
native_go:
	$(MAKE) -C $(NATIVE_GO_DIR)

# Compile Teleport: ensure sources are extracted and patched first
teleport_compile_target:
	@echo "===> Building Teleport v$(PKG_VERS) for $(GO_ARCH) (GOARM=$(GOARM))"
	$(RUN) sh -c 'cd $(GO_SRC_DIR) && mkdir -p build && CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=$(GO_ARCH) GOARM=$(GOARM) go build -trimpath -ldflags "$(GO_LDFLAGS)" -o build/teleport ./lib'

# Stage step: installs build/teleport into the staging area
go_install_target: teleport_compile_target
