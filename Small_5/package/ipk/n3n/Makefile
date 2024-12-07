
include $(TOPDIR)/rules.mk

PKG_NAME:=n3n
PKG_VERSION:=3.4.4
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/n42n/n3n.git
PKG_SOURCE_VERSION:=6086ae261e7c5d298cdbcc3894d93748adb05ae5
PKG_MIRROR_HASH:=0db05b373e30f5bb2fb56ab3de87d1679e531802983a73631d053a368e08c2ce

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
