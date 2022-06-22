include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-adblock-plus
PKG_VERSION:=1.1
PKG_RELEASE:=3
PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Small_5

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=LuCI
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for Adblock Plus+
  DEPENDS:=+openssl-util +curl +dnsmasq-full +ipset +luci-compat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Luci Support for Adblock Plus+.
endef

define Build/Prepare
	chmod -R 755 luasrc/* root/*
	find luasrc -type f -exec chmod 644 {} \;
	find root -type f -exec chmod 644 {} \;
	chmod 755 root/etc/init.d/* root/usr/share/adblock/*
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/adblock/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	cp -pr luasrc/* $(1)/usr/lib/lua/luci
	cp -pr root/* $(1)/
	luac -s -o $(1)/usr/share/adblock/auth  $(1)/usr/share/adblock/auth
	po2lmo po/zh-cn/adblock.po $(1)/usr/lib/lua/luci/i18n/adblock.zh-cn.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
