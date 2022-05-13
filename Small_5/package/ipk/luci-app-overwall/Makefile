include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-overwall
PKG_VERSION:=1.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

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
	DEPENDS:=+openssl-util +ipset +ip-full +iptables-mod-tproxy +dnsmasq-full +smartdns +coreutils +coreutils-base64 +curl +tcping +chinadns-ng +lua +luci-compat \
	+shadowsocks-libev-ss-redir +shadowsocks-libev-ss-local +shadowsocksr-libev-redir +shadowsocksr-libev-local \
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
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/overwall/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	cp -pr luasrc/* $(1)/usr/lib/lua/luci
	cp -pr root/* $(1)/
	luac -s -o $(1)/usr/share/overwall/auth  $(1)/usr/share/overwall/auth
	po2lmo po/zh-cn/overwall.po $(1)/usr/lib/lua/luci/i18n/overwall.zh-cn.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
