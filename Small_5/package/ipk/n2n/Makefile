
include $(TOPDIR)/rules.mk

PKG_SOURCE_URL:=https://github.com/ntop/n2n.git
PKG_SOURCE_VERSION:=a74435c5591945ed79f372bf3c7c78197657800e

PKG_NAME:=n2n
PKG_VERSION:=3.1.1_git-$(PKG_SOURCE_VERSION)
PKG_RELEASE:=1
PKG_LICENSE:=GPL3

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_PROTO:=git

PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/n2n/Default
  SECTION:=net
  CATEGORY:=Network
  TITLE:=N2N Peer-to-peer VPN
  URL:=https://www.ntop.org/n2n
  SUBMENU:=VPN
  DEPENDS+=+libcap
endef

define Package/n2n-edge
  $(call Package/n2n/Default)
  TITLE+= client (edge node)
  DEPENDS+=+kmod-tun
endef

define Package/n2n-supernode
  $(call Package/n2n/Default)
  TITLE+= server (supernode)
endef

define Package/n2n-edge/description
The client node for the N2N infrastructure
endef

define Package/n2n-supernode/description
The supernode for the N2N infrastructure
endef

define Build/Configure
	( cd $(PKG_BUILD_DIR); ./autogen.sh )
	$(call Build/Configure/Default)
endef

define Package/n2n-edge/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/edge $(1)/usr/bin/
endef

define Package/n2n-supernode/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/supernode $(1)/usr/bin/
endef

$(eval $(call BuildPackage,n2n-edge))
$(eval $(call BuildPackage,n2n-supernode))
