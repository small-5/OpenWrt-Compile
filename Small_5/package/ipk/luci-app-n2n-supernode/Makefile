include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-n2n-supernode
PKG_VERSION:=1.0
PKG_RELEASE:=8

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for N2N Supernode.
  DEPENDS:=+n2n-supernode +luci-compat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI support for N2N Supernode.
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/po/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/*.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luasrc/model/cbi/*.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/n2n-supernode
	$(INSTALL_DATA) ./luasrc/view/n2n-supernode/*.htm $(1)/usr/lib/lua/luci/view/n2n-supernode/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/n2n-supernode.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/n2n-supernode $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/n2n-supernode $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/acl.d/* $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
