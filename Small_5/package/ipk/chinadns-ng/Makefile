include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=112.11.13
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/zfl9/chinadns-ng.git
PKG_SOURCE_VERSION:=de1cdc469573675b8610b66d98141665e84b92e2
PKG_MIRROR_HASH:=6120214da5906b60fd50d90dc2a6c9d36606b4ff6119bb4a48dc61942f36544c

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=pexcn <i@pexcn.me>

include $(INCLUDE_DIR)/package.mk

define Package/chinadns-ng
	SECTION:=net
	CATEGORY:=Network
	TITLE:=ChinaDNS Next Generation, refactoring with epoll and ipset
	URL:=https://github.com/zfl9/chinadns-ng
	DEPENDS:=+ipset
endef

define Package/chinadns-ng/description
ChinaDNS Next Generation, refactoring with epoll and ipset.
endef

define Package/chinadns-ng/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/chinadns-ng $(1)/usr/bin
endef

$(eval $(call BuildPackage,chinadns-ng))
