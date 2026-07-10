include $(TOPDIR)/rules.mk

PKG_NAME:=fips
PKG_VERSION:=0.5.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/jmcorgan/fips.git
PKG_SOURCE_VERSION:=v0.5.0
PKG_MIRROR_HASH:=7c12976db56d29cb64cf0b6370c31e18ac3fbfcb62bf43167535d4ddcc52b787

PKG_MAINTAINER:=TollGate Team <team@tollgate.net>
PKG_LICENSE:=GPL-2.0
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
  $(error Unsupported architecture: $(ARCH). Add a RUST_TARGET mapping in package/fips/Makefile.)
endif

RUST_RELEASE_DIR:=$(PKG_BUILD_DIR)/target/$(RUST_TARGET)/release

define Package/fips
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=FIPS mesh network daemon
  URL:=https://github.com/jmcorgan/fips
  DEPENDS:=+ca-bundle +ip-full +kmod-tun +libubox +libuci +libblobmsg-json
endef

define Package/fips/description
  FIPS is a mesh network daemon that creates resilient, self-organizing
  network topologies using secure peer-to-peer connections. It provides
  automatic mesh formation, dynamic routing, and secure communication
  for distributed network applications.
  
  Features:
  - Automatic mesh network formation and maintenance
  - Secure peer-to-peer communication with encryption
  - Dynamic routing and path optimization
  - Support for multiple network interfaces
  - Comprehensive monitoring and management tools
  - UCI-based configuration system
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
		--bin fips \
		--bin fipsctl \
		--bin fipstop \
		--bin fips-gateway
endef

define Package/fips/install
	# Daemon binaries
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(RUST_RELEASE_DIR)/fips $(1)/usr/bin/fips
	$(INSTALL_BIN) $(RUST_RELEASE_DIR)/fipsctl $(1)/usr/bin/fipsctl
	$(INSTALL_BIN) $(RUST_RELEASE_DIR)/fipstop $(1)/usr/bin/fipstop
	$(INSTALL_BIN) $(RUST_RELEASE_DIR)/fips-gateway $(1)/usr/bin/fips-gateway

	# procd init scripts
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/fips $(1)/etc/init.d/fips
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/fips-gateway $(1)/etc/init.d/fips-gateway

	# Default configuration
	$(INSTALL_DIR) $(1)/etc/fips
	$(INSTALL_CONF) $(CURDIR)/files/etc/fips/fips.conf $(1)/etc/fips/fips.conf
	$(INSTALL_CONF) $(CURDIR)/files/etc/fips/fips-gateway.conf $(1)/etc/fips/fips-gateway.conf

	# UCI config
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(CURDIR)/files/etc/config/fips $(1)/etc/config/fips

	# System integration files
	$(INSTALL_DIR) $(1)/etc/sysctl.d
	$(INSTALL_DATA) $(CURDIR)/files/etc/sysctl.d/fips.conf $(1)/etc/sysctl.d/fips.conf

	$(INSTALL_DIR) $(1)/etc/hotplug.d iface
	$(INSTALL_DATA) $(CURDIR)/files/etc/hotplug.d iface/10-fips $(1)/etc/hotplug.d iface/10-fips

	# Firewall integration
	$(INSTALL_DIR) $(1)/etc/firewall.d
	$(INSTALL_DATA) $(CURDIR)/files/etc/firewall.d/50-fips $(1)/etc/firewall.d/50-fips

	# sysupgrade: preserve FIPS configuration across upgrades
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/lib/upgrade/keep.d/fips $(1)/lib/upgrade/keep.d/fips
endef

$(eval $(call BuildPackage,fips))