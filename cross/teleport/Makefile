## =============================================================================
## Teleport Cross-Compile Makefile
## =============================================================================

# 1) Derive paths to this Makefile and the spksrc mk directory
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)

# 2) Package identity and source archive settings
PKG_NAME      ?= teleport
PKG_VERS      ?= 17.4.7
PKG_EXT       ?= tar.gz
PKG_DIST_SITE ?= https://github.com/gravitational/teleport/archive/refs/tags
PKG_DIST_NAME ?= v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_FILE ?= $(PKG_NAME)-$(PKG_DIST_NAME)
PKG_DIR       ?= $(PKG_NAME)-$(PKG_VERS)

# 3) Ensure Go toolchain is available
DEPENDS       = native/go

# 4) Metadata for the open-source Teleport project
HOMEPAGE      = https://github.com/gravitational/teleport
COMMENT       = Teleport provides secure SSH, Application, and Database access
LICENSE       = AGPL-3.0

# 5) Architectures not supported by Teleport
UNSUPPORTED_ARCHS = $(PPC_ARCHS) $(ARMv5_ARCHS) $(i686_ARCHS) $(ARMv7L_ARCHS)

# 6) Directories for source extraction and build output
GO_SRC_DIR    = $(EXTRACT_PATH)/$(PKG_DIR)
GO_BIN_DIR    = $(GO_SRC_DIR)/build

# 7) Go build environment variables
CGO_ENABLED   = 1
GO_LDFLAGS    = -s -w

# 8) Name of the compile target used by spksrc.cross-go.mk
COMPILE_TARGET = teleport_compile_target

# 9) Include spksrc’s generic Go cross-compile rules
include $(MKPATH)/spksrc.cross-go.mk

# 10) Build the Teleport server binary for the target architecture
teleport_compile_target:
	@echo "===> Building Teleport v$(PKG_VERS) for $(GO_ARCH) (GOARM=$(GOARM))"
	cd $(GO_SRC_DIR) && \
	CGO_ENABLED=$(CGO_ENABLED) \
	GOOS=linux GOARCH=$(GO_ARCH) GOARM=$(GOARM) \
	go build -trimpath -ldflags "$(GO_LDFLAGS)" \
		-o $(GO_BIN_DIR)/teleport \
		./lib
	