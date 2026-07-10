include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp-bonding
PKG_VERSION:=0.1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=TollGate Team <team@tollgate.net>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/mptcp-bonding
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Multi-WAN MPTCP bonding client
  URL:=https://github.com/c03rad0r/tg-mptcp-server
  DEPENDS:=+shadowsocks-libev-ss-redir +ip-full +kmod-ipt-conntrack
endef

define Package/mptcp-bonding/description
  Multi-WAN MPTCP bonding client that bonds multiple upstream links using
  Multipath TCP subflows toward a convergence point. Provides seamless
  aggregation of multiple internet connections for improved bandwidth
  and reliability.
  
  Features:
  - MPTCP-based bonding of multiple WAN interfaces
  - Shadowsocks proxy integration for traffic steering
  - Dynamic endpoint management
  - UCI-based configuration
  - Automatic failover and load balancing
endef

# Pure-files package: no upstream source to fetch or compile.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/mptcp-bonding/install
	# Enable kernel MPTCP at boot
	$(INSTALL_DIR) $(1)/etc/sysctl.d
	$(INSTALL_DATA) $(CURDIR)/files/etc/sysctl.d/mptcp-bonding.conf \
		$(1)/etc/sysctl.d/mptcp-bonding.conf

	# UCI config: convergence-point server + ss-redir params
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/etc/config/mptcp-bonding \
		$(1)/etc/config/mptcp-bonding

	# procd init: bring up ss-redir over MPTCP toward the server
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/mptcp-bonding \
		$(1)/etc/init.d/mptcp-bonding

	# Bonding helper: per-WAN subflow / route setup
	$(INSTALL_DIR) $(1)/usr/lib/mptcp-bonding
	$(INSTALL_BIN) $(CURDIR)/files/usr/lib/mptcp-bonding/setup-bond.sh \
		$(1)/usr/lib/mptcp-bonding/setup-bond.sh

	# sysupgrade keep list
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/lib/upgrade/keep.d/mptcp-bonding \
		$(1)/lib/upgrade/keep.d/mptcp-bonding
endef

$(eval $(call BuildPackage,mptcp-bonding))