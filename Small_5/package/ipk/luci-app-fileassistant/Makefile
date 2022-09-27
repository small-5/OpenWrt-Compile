include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fileassistant
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for Fileassistant
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI support for Fileassistant
endef

define Build/Prepare
	chmod -R 755 luasrc/* root/*
	find luasrc -type f -exec chmod 644 {} \;
	find root -type f -exec chmod 644 {} \;
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
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	cp -pr luasrc/* $(1)/usr/lib/lua/luci
	cp -pr root/* $(1)/
	$(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)/www/luci-static/resources/fileassistant/),true)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
