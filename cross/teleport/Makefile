## =============================================================================
## Teleport Cross-Compile Makefile
## =============================================================================

# 1) Derive this Makefile’s directory and the shared spksrc mk directory
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(dir   $(MAKEFILE_PATH))
MKPATH        := $(realpath $(MAKEFILE_DIR)/../../mk)
SPKSRC_ROOT   := $(realpath $(MAKEFILE_DIR)/../..)

# native Go toolchain
NATIVE_GO_DIR := $(SPKSRC_ROOT)/native/go
GO_BIN        := $(NATIVE_GO_DIR)/work-native/go/bin/go

# Teleport source‐archive identity and download settings
PKG_NAME      ?= teleport
PKG_VERS      ?= 17.4.7
PKG_EXT       ?= tar.gz
PKG_DIST_SITE ?= https://github.com/gravitational/teleport/archive/refs/tags
PKG_DIST_NAME := v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_FILE := $(PKG_NAME)-$(PKG_DIST_NAME)
DIST_DIR      := $(SPKSRC_ROOT)/distrib

# working directories
WORK_DIR      := $(MAKEFILE_DIR)/work
PKG_DIR       := $(PKG_NAME)-$(PKG_VERS)
EXTRACT_DIR   := $(WORK_DIR)/$(PKG_DIR)
BUILD_DIR     := $(EXTRACT_DIR)/build
INSTALL_DIR   := $(WORK_DIR)/install/usr/local/$(PKG_NAME)

# Go build settings
CGO_ENABLED   ?= 1
GO_LDFLAGS    ?= -s -w
GO            := $(GO_BIN)

# Build dependency: ensure Go toolchain is built first
DEPENDS       := native/go

# Upstream metadata for Teleport
HOMEPAGE      := https://github.com/gravitational/teleport
COMMENT       := Teleport provides secure SSH, application, and database proxy
LICENSE       := AGPL-3.0

# Teleport does not support these architectures
UNSUPPORTED_ARCHS := $(PPC_ARCHS) $(ARMv5_ARCHS) $(i686_ARCHS) $(ARMv7L_ARCHS)

# default goal
.DEFAULT_GOAL := all

all: go download checksum extract patch compile stage

go:
	@if [ ! -x "$(GO)" ]; then \
	  $(MAKE) -C "$(NATIVE_GO_DIR)"; \
	fi

download:
	@mkdir -p "$(DIST_DIR)"
	@if [ ! -f "$(DIST_DIR)/$(PKG_DIST_FILE)" ]; then \
	  wget --https-only -O "$(DIST_DIR)/$(PKG_DIST_FILE)" \
	       "$(PKG_DIST_SITE)/v$(PKG_VERS).$(PKG_EXT)"; \
	fi

checksum: download
	@if [ -f digests ]; then \
	  grep -q "$(PKG_DIST_FILE)" digests || \
	    (echo "ERROR: no digest for $(PKG_DIST_FILE)" && exit 1); \
	  grep "$(PKG_DIST_FILE)" digests | \
	    while read file type sum; do \
	      case $$type in \
	        SHA256|sha256) echo "$$sum  $$file" | sha256sum -c - ;; \
	        *) echo "WARNING: unsupported digest type $$type";; \
	      esac; \
	    done; \
	else \
	  echo "WARNING: no digests file, skipping checksum"; \
	fi

extract: download
	@mkdir -p "$(WORK_DIR)"
	tar -xzf "$(DIST_DIR)/$(PKG_DIST_FILE)" -C "$(WORK_DIR)"

patch:
	@echo ">> no patches to apply"

compile: extract
	@mkdir -p "$(BUILD_DIR)"
	cd "$(EXTRACT_DIR)" && \
	CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=$(GOARCH) \
	$(GO) build -trimpath -ldflags "$(GO_LDFLAGS)" \
	  -o "$(BUILD_DIR)/$(PKG_NAME)" ./lib

stage: compile
	@mkdir -p "$(INSTALL_DIR)/bin"
	install -m 755 "$(BUILD_DIR)/$(PKG_NAME)" \
	        "$(INSTALL_DIR)/bin/$(PKG_NAME)"

clean:
	@rm -rf "$(WORK_DIR)"
	