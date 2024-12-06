include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-overwall
PKG_VERSION:=113.12.7
PKG_RELEASE:=1
PKG_MAINTAINER:=Maha_5

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
config PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Server
	bool "Include Shadowsocks Server"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR_Server
	bool "Include ShadowsocksR Server"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_Simple_obfs
	bool "Include Shadowsocks Simple-obfs Plugin"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_Simple_obfs_server
	bool "Include Shadowsocks Simple-obfs-server Plugin"
	depends on PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Server
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_Xray_plugin
	bool "Include Shadowsocks Xray Plugin"
	default y if x86||x86_64||arm||aarch64

config PACKAGE_$(PKG_NAME)_INCLUDE_Xray
	bool "Include Xray"
	default y if x86||x86_64||arm||aarch64

config PACKAGE_$(PKG_NAME)_INCLUDE_Trojan_Plus
	bool "Include Trojan Plus"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_NaiveProxy
	bool "Include NaiveProxy"
	depends on !(arc||armeb||mips||mips64||powerpc)
	default n

config PACKAGE_$(PKG_NAME)_INCLUDE_Kcptun
	bool "Include Kcptun"
	default y if x86||x86_64||arm||aarch64

config PACKAGE_$(PKG_NAME)_INCLUDE_Socks5_Proxy
	bool "Include Socks5 Transparent Proxy"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_Socks_Server
	bool "Include Socks Sever"
	default y
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=SS/SSR/Trojan/Socks5/Tun/NaiveProxy/XRay LuCI interface
	PKGARCH:=all
	DEPENDS:=+openssl-util +ipset +ip-full +iptables +IPV6:ip6tables +iptables-mod-tproxy +kmod-ipt-nat +IPV6:kmod-ipt-nat6 +dnsmasq-full +smartdns +coreutils +coreutils-base64 +curl +tcping +chinadns-ng +lua +luci-compat \
	+shadowsocks-libev-ss-redir +shadowsocks-libev-ss-local +shadowsocksr-libev-redir +shadowsocksr-libev-local +TARGET_x86:dmidecode \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Server:shadowsocks-libev-ss-server \
	+PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR_Server:shadowsocksr-libev-server \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Simple_obfs:simple-obfs \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Simple_obfs_server:simple-obfs-server \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Xray_plugin:xray-plugin \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Xray:xray-core \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Trojan_Plus:trojan-plus \
	+PACKAGE_$(PKG_NAME)_INCLUDE_NaiveProxy:naiveproxy \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Kcptun:kcptun-client \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Socks5_Proxy:redsocks2 \
	+PACKAGE_$(PKG_NAME)_INCLUDE_Socks_Server:microsocks
endef

define Build/Prepare
	chmod -R 755 luasrc/* root/*
	find luasrc -type f -exec chmod 644 {} \;
	find root -type f -exec chmod 644 {} \;
	chmod 755 root/etc/hotplug.d/iface/* root/etc/init.d/* root/usr/share/overwall/*
	mkdir $(PKG_BUILD_DIR)/i18n
	$(foreach po,$(wildcard ${CURDIR}/po/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/i18n/$(patsubst %.po,%.lmo,$(notdir $(po)));)
	cp src/* $(PKG_BUILD_DIR)
	cp root/usr/share/overwall/curl $(PKG_BUILD_DIR)
	shc -rBf $(PKG_BUILD_DIR)/curl
	mv $(PKG_BUILD_DIR)/curl.x.c $(PKG_BUILD_DIR)/curl.c
	rm $(PKG_BUILD_DIR)/{curl,curl.x}
endef

define Package/$(PKG_NAME)/conffiles
/etc/overwall/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	cp -pr luasrc/* $(1)/usr/lib/lua/luci
	cp -pr root/* $(1)/
	#luac -s -o $(1)/usr/share/overwall/auth  $(1)/usr/share/overwall/auth
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/i18n/* $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/curl $(1)/usr/share/overwall/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
