include $(TOPDIR)/rules.mk

PKG_NAME:=autocore
PKG_VERSION:=1
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/autocore
	TITLE:=X86/X64 auto core loadbalance script.
	MAINTAINER:=Small_5
	DEPENDS:=@TARGET_x86 +lm-sensors +ethtool
endef

define Package/autocore-arm
	TITLE:=ARM auto core loadbalance script.
	DEPENDS:=@(TARGET_bcm27xx||TARGET_bcm53xx||TARGET_ipq40xx||TARGET_ipq806x||TARGET_mvebu||TARGET_rockchip||TARGET_sunxi) \
		+(TARGET_rockchip||TARGET_sunxi):ethtool +TARGET_bcm27xx:bcm27xx-userland +TARGET_bcm53xx:nvram
endef

define Package/autocore/description
	X86/X64 auto core loadbalance script.
endef

define Package/autocore-arm/description
	ARM auto core loadbalance script.
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
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/autocore $(1)/etc/init.d/autocore
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/ethinfo $(1)/usr/bin/ethinfo
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/status/include
	$(INSTALL_DATA) ./files/*.js $(1)/www/luci-static/resources/view/status/include/
	$(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)/www/luci-static/resources/view/status/include/),true)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef

ifeq ($(BOARD),rockchip)
define Package/autocore-arm/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/autocore-rockchip $(1)/etc/init.d/autocore
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/ethinfo $(1)/usr/bin/ethinfo
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/status/include
	$(INSTALL_DATA) ./files/*.js $(1)/www/luci-static/resources/view/status/include/
	$(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)/www/luci-static/resources/view/status/include/),true)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef
else
define Package/autocore-arm/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef
endif
$(eval $(call BuildPackage,autocore))
$(eval $(call BuildPackage,autocore-arm))
