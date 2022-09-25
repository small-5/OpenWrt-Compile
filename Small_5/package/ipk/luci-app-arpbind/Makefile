include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-arpbind
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Small_5

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=LuCI
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=ARP Binding
  DEPENDS:=+ip-full
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Luci Support for ARP Binding.
endef

define Build/Prepare
	chmod -R 755 htdocs/* root/*
	find htdocs -type f -exec chmod 644 {} \;
	find root -type f -exec chmod 644 {} \;
	chmod 755 root/etc/hotplug.d/iface/* root/etc/init.d/*
	mkdir $(PKG_BUILD_DIR)/i18n
	$(foreach po,$(wildcard ${CURDIR}/po/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/i18n/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define JsMin
	$(FIND) $(1) -type f -name '*.js' | while read src; do \
		if jsmin < "$$$$src" > "$$$$src.o"; \
		then mv "$$$$src.o" "$$$$src"; fi; \
	done
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www
	cp -pr htdocs/* $(1)/www
	$(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)/www/luci-static/resources/view/),true)
	cp -pr root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
