#
# Copyright (C) 2014 OpenWrt-dist
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=redsocks2
PKG_VERSION:=0.70
PKG_RELEASE:=1
PKG_MAINTAINER:=semigodking <semigodking@gmail.com>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/semigodking/redsocks.git
PKG_SOURCE_VERSION:=f1837c869fc34b7da21142a0a34191d5c8eea88c
PKG_MIRROR_HASH:=8605c55367df2769e32ccf594f206f53662e64f7cc19f5ef60e0f1bbf0afa19d

include $(INCLUDE_DIR)/package.mk

define Package/redsocks2
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Redirect any TCP connection to a SOCKS or HTTPS proxy server
	URL:=https://github.com/semigodking/redsocks
	DEPENDS:=+libevent2 +libopenssl
endef

define Package/redsocks2/description
This is a modified version of original redsocks. \
The name is changed to be REDSOCKS2 since this release to distinguish with original redsocks. \
This variant is useful for anti-GFW (Great Fire Wall).
endef

define Build/Compile
	$(call Build/Compile/Default,DISABLE_SHADOWSOCKS=true)
endef

define Package/redsocks2/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/redsocks2 $(1)/usr/bin
endef

$(eval $(call BuildPackage,redsocks2))
