include $(TOPDIR)/rules.mk

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/zfl9/ipt2socks.git
PKG_SOURCE_VERSION:=1a5f20895d8258b1eca104614fb15390320eac1a
PKG_SOURCE_SHORTID=$(shell echo $(PKG_SOURCE_VERSION) | cut -c1-7)
PKG_NAME:=ipt2socks
PKG_VERSION:=1.1.3_git-$(PKG_SOURCE_SHORTID)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(PKG_SOURCE_SUBDIR)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/ipt2socks
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Utility for converting iptables (REDIRECT/TPROXY) to SOCKS5
	URL:=https://github.com/zfl9/ipt2socks.git
endef

define Package/ipt2socks/description
Utility for converting iptables (REDIRECT/TPROXY) to SOCKS5.
endef

define Package/ipt2socks/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipt2socks $(1)/usr/bin
endef

$(eval $(call BuildPackage,ipt2socks))
