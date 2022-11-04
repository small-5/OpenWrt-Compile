#
# Copyright (C) 2014 OpenWrt-dist
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/semigodking/redsocks.git
# 7797a938a3945f0316640067da693b148f412f0b之后的版本无法多开，暂时不要更新（1951b49b774b0aab702348d0370e26bae1c3a7df也无法多开）
PKG_SOURCE_VERSION:=7797a938a3945f0316640067da693b148f412f0b
PKG_SOURCE_SHORTID=$(shell echo $(PKG_SOURCE_VERSION) | cut -c1-7)
PKG_NAME:=redsocks2
PKG_VERSION:=0.68_git-$(PKG_SOURCE_SHORTID)
PKG_RELEASE:=3

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MAINTAINER:=semigodking <semigodking@gmail.com>
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

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
