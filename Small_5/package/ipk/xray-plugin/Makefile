#
# Copyright (C) 2021 ImmortalWrt
# <https://project-openwrt.eu.org>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=xray-plugin
PKG_VERSION:=1.8.24
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/teddysun/xray-plugin.git
PKG_SOURCE_VERSION:=96a75e491a3400935fa58861ad4342027cddd4e0
PKG_MIRROR_HASH:=72aeadde438606fe9e24d315943e1388f6149d3bd535d57715d5826daebd9c92

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@project-openwrt.eu.org>

PKG_CONFIG_DEPENDS:= \
	CONFIG_XRAY_PLUGIN_PROVIDE_V2RAY_PLUGIN

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/teddysun/xray-plugin

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/xray-plugin/config
config XRAY_PLUGIN_PROVIDE_V2RAY_PLUGIN
	bool "Provide v2ray-plugin binary using xray-plugin"
	default n
endef

define Package/xray-plugin
	SECTION:=net
	CATEGORY:=Network
	TITLE:=SIP003 plugin for Shadowsocks, based on Xray
	URL:=https://github.com/teddysun/xray-plugin
	DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
endef

define Package/xray-plugin/description
	Yet another SIP003 plugin for Shadowsocks, based on Xray.
endef

define Package/xray-plugin/install
	$(call GoPackage/Package/Install/Bin,$(1))
ifneq ($(CONFIG_XRAY_PLUGIN_PROVIDE_V2RAY_PLUGIN),)
	$(LN) xray-plugin $(1)/usr/bin/v2ray-plugin
endif
endef

$(eval $(call GoBinPackage,xray-plugin))
$(eval $(call BuildPackage,xray-plugin))
