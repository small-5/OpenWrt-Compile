include $(TOPDIR)/rules.mk

PKG_NAME:=autocore
PKG_VERSION:=113.12.3
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/autocore
	TITLE:=X86/X64 auto core loadbalance script.
	MAINTAINER:=Maha_5
	DEPENDS:=+(TARGET_x86||TARGET_rockchip||TARGET_sunxi):ethtool +TARGET_x86:lm-sensors +TARGET_bcm27xx:bcm27xx-userland +TARGET_bcm53xx:nvram
endef

define Package/autocore/description
	X86/X64 auto core loadbalance script.
endef

define Build/Prepare
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

define Package/autocore/install

ifneq ($(filter i386 i686 x86_64, $(ARCH)),)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/autocore $(1)/etc/init.d/autocore
else ifeq ($(BOARD),rockchip)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/autocore-rockchip $(1)/etc/init.d/autocore
endif

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/status/include
	$(INSTALL_DATA) ./files/*.js $(1)/www/luci-static/resources/view/status/include/
	$(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)/www/luci-static/resources/view/status/include/),true)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/*.json $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,autocore))
