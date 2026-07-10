include $(TOPDIR)/rules.mk

PKG_NAME:=tollgate-rs
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/OpenTollGate/tollgate-rs.git
PKG_SOURCE_VERSION:=v0.1.0
PKG_MIRROR_HASH:=d1c59d546acdfdd54304a7a268481de45822267c7f494b32f4a72672d08f5f1f

PKG_MAINTAINER:=TollGate Team <team@tollgate.net>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

# Rust host toolchain must be present in the build system.
# Enable via: make menuconfig → Advanced → Rust
PKG_BUILD_DEPENDS:=rust/host
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

# ---------------------------------------------------------------------------
# Map OpenWrt ARCH to Rust target triple. All OpenWrt targets use musl libc.
# ---------------------------------------------------------------------------
ifeq ($(ARCH),aarch64)
  RUST_TARGET:=aarch64-unknown-linux-musl
else ifeq ($(ARCH),x86_64)
  RUST_TARGET:=x86_64-unknown-linux-musl
else ifeq ($(ARCH),mipsel)
  RUST_TARGET:=mipsel-unknown-linux-musl
else ifeq ($(ARCH),mips)
  RUST_TARGET:=mips-unknown-linux-musl
else ifeq ($(ARCH),arm)
  # OpenWrt ARM targets predominantly use hardfloat ABI.
  # Override RUST_TARGET in your build if your target uses softfloat.
  RUST_TARGET:=arm-unknown-linux-musleabihf
else
  $(error Unsupported architecture: $(ARCH). Add a RUST_TARGET mapping in package/tollgate-rs/Makefile.)
endif

RUST_RELEASE_DIR:=$(PKG_BUILD_DIR)/target/$(RUST_TARGET)/release

define Package/tollgate-rs
  SECTION:=net
  CATEGORY:=Network
  TITLE:=TollGate node (Cashu metered access gateway)
  URL:=https://github.com/OpenTollGate/tollgate-rs
  DEPENDS:=+ca-bundle +ip-full
endef

define Package/tollgate-rs/description
  TollGate node provides metered network access using Cashu micropayments.
  Acts as a gateway that sells network access tokens and manages
  bandwidth allocation for connected clients.
  
  Features:
  - Cashu-based micropayment system for network access
  - Metered bandwidth allocation and accounting
  - Configurable access policies and rate limiting
  - RESTful API for integration with billing systems
  - Procd-based service management
endef

# ---------------------------------------------------------------------------
# Build with cross-compilation support
# ---------------------------------------------------------------------------
define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/.cargo
	printf '[target.$(RUST_TARGET)]\nlinker = "$(TARGET_CC)"\n' \
		> $(PKG_BUILD_DIR)/.cargo/config.toml
	cd $(PKG_BUILD_DIR) && \
	CARGO_HOME=$(STAGING_DIR_HOST)/share/cargo \
	cargo build \
		--release \
		--target $(RUST_TARGET) \
		--bin tollgate
endef

define Package/tollgate-rs/install
	# Daemon binary
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(RUST_RELEASE_DIR)/tollgate $(1)/usr/bin/tollgate

	# procd init script
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/tollgate-rs $(1)/etc/init.d/tollgate-rs

	# Default config — installed as CONF so opkg/apk will not clobber it on upgrade
	$(INSTALL_DIR) $(1)/etc/tollgate
	$(INSTALL_CONF) $(CURDIR)/files/etc/tollgate/tollgate.yaml $(1)/etc/tollgate/tollgate.yaml

	# UCI config: listen address / enabled flag
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(CURDIR)/files/etc/config/tollgate-rs $(1)/etc/config/tollgate-rs

	# sysupgrade: preserve /etc/tollgate/ across firmware upgrades
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/lib/upgrade/keep.d/tollgate-rs $(1)/lib/upgrade/keep.d/tollgate-rs
endef

$(eval $(call BuildPackage,tollgate-rs))