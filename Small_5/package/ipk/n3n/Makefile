
include $(TOPDIR)/rules.mk

PKG_NAME:=n3n
PKG_VERSION:=3.4.4
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/n42n/n3n.git
PKG_SOURCE_VERSION:=b92fe5de9ba4226387c1aad590a5fb7e824f8e80
PKG_MIRROR_HASH:=7961d30cc5c655da80f73e45a1ebd834ece13f35d56e109ba1bdef5aed91a0ed

PKG_LICENSE:=GPL3

PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/n3n/Default
  SECTION:=net
  CATEGORY:=Network
  TITLE:=N3N Peer-to-peer VPN
  URL:=http://github.com/n42n/n3n
  SUBMENU:=VPN
endef

define Package/n3n-edge
  $(call Package/n3n/Default)
  TITLE+= client (edge node)
  DEPENDS+=+kmod-tun
endef

define Package/n3n-supernode
  $(call Package/n3n/Default)
  TITLE+= server (supernode)
endef

define Package/n3n-edge/description
The client node for the N3N infrastructure
endef

define Package/n3n-supernode/description
The supernode for the N3N infrastructure
endef

define Build/Configure
	( cd $(PKG_BUILD_DIR); \
	./autogen.sh; \
	./configure --with-rundir=/var/run )
endef

define Package/n3n-edge/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/apps/n3n-edge $(1)/usr/bin/edge
endef

define Package/n3n-supernode/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/apps/n3n-supernode $(1)/usr/bin/supernode
endef

$(eval $(call BuildPackage,n3n-edge))
$(eval $(call BuildPackage,n3n-supernode))
