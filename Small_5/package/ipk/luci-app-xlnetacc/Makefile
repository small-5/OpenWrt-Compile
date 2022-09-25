include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xlnetacc
PKG_VERSION:=1
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for XLNetAcc
	PKGARCH:=all
	DEPENDS:=+jshn +curl +openssl-util +luci-compat
endef

define Package/$(PKG_NAME)/description
	LuCI Support for XLNetAcc.
endef

define Build/Prepare
	chmod -R 755 luasrc/* root/*
	find luasrc -type f -exec chmod 644 {} \;
	find root -type f -exec chmod 644 {} \;
	chmod 755 root/etc/init.d/* root/etc/hotplug.d/iface/* root/usr/bin/*
	mkdir $(PKG_BUILD_DIR)/i18n
	$(foreach po,$(wildcard ${CURDIR}/po/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/i18n/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/xlnetacc
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	cp -pr luasrc/* $(1)/usr/lib/lua/luci
	cp -pr root/* $(1)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
