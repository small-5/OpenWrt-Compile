#
# Copyright (C) 2010-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openvpn-easy-rsa-whisky
PKG_VERSION:=113.12.7
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/OpenVPN/easy-rsa.git
PKG_SOURCE_VERSION:=c7a0d1621876f6462e7a77f25a546bfb69bd29b2
PKG_MIRROR_HASH:=bd8fdf7363bcbaa2b98433b6e3c38fcb2d061de2735ce61ef26e7b0e01c16ea6
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=CLI utility to build and manage a PKI CA.
  SECTION:=net
  CATEGORY:=Network
  URL:=http://openvpn.net
  SUBMENU:=VPN
  DEPENDS:=+openssl-util
  PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easyrsa3/easyrsa $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/easy-rsa
	$(INSTALL_DATA) ./files/vars $(1)/etc/easy-rsa/vars
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
