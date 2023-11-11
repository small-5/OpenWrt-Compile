include $(TOPDIR)/rules.mk

PKG_NAME:=https-dns-proxy_alt
PKG_VERSION:=112-10-25
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/aarond10/https_dns_proxy/
PKG_SOURCE_VERSION:=977341a4e35a37ee454e97e82caf4276b1b4961a
PKG_MIRROR_HASH:=8622846f1038ac05436a48d9b36a07c516cbb6504ce68e7ee8c5529788fac39b
PKG_MAINTAINER:=Stan Grishin <stangri@melmac.ca>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += -DCLANG_TIDY_EXE= -DGIT_VERSION=$(PKG_VERSION)-$(PKG_RELEASE)

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=DNS Over HTTPS Proxy
	URL:=https://docs.openwrt.melmac.net/https-dns-proxy/
	DEPENDS:=+libcares +libcurl +libev +ca-bundle
	CONFLICTS:=https_dns_proxy
endef

define Package/$(PKG_NAME)/description
Light-weight DNS-over-HTTPS, non-caching translation proxy for the RFC 8484 DoH standard.
It receives regular (UDP) DNS requests and resolves them via DoH resolver.
Please see https://docs.openwrt.melmac.net/https-dns-proxy/ for more information.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/https_dns_proxy $(1)/usr/sbin/https-dns-proxy
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
