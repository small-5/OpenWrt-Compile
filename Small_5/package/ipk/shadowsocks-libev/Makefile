include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-libev
PKG_VERSION:=3.3.5
PKG_RELEASE:=11
PKG_CPE_ID:=cpe:/a:shadowsocks:shadowsocks-libev

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev.git
PKG_SOURCE_VERSION:=d83ace0f0d9c05656c13d66aa4a449bf70143254
PKG_MIRROR_HASH:=58390166a1b7885ef63e1f919df97f9c23512d0606b8df2a4636bfa1f884c5ba

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_FLAGS:=no-mips16 lto
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=c-ares pcre2

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocks-libev/Default
  define Package/shadowsocks-libev-$(1)
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    TITLE:=shadowsocks-libev $(1)
    URL:=https://github.com/shadowsocks/shadowsocks-libev
    DEPENDS:=+libev +libmbedtls +libpthread +libsodium $(DEPENDS_$(1))
  endef

  define Package/shadowsocks-libev-$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/usr/bin/$(1) $$(1)/usr/bin
  endef

endef

DEPENDS_ss-local = +libpcre2
DEPENDS_ss-server = +libcares +libpcre2

SHADOWSOCKS_COMPONENTS:=ss-local ss-redir ss-tunnel ss-server
define shadowsocks-libev/templates
  $(foreach component,$(SHADOWSOCKS_COMPONENTS),
    $(call Package/shadowsocks-libev/Default,$(component))
  )
endef
$(eval $(call shadowsocks-libev/templates))

define Build/Prepare
	$(call Build/Prepare/Default)
	$(FIND) $(PKG_BUILD_DIR) \
			   -name '*.o' \
			-o -name '*.lo' \
			-o -name '.deps' \
			-o -name '.libs' \
		| $(XARGS) rm -rvf
endef

CONFIGURE_ARGS += \
	--disable-documentation \
	--disable-silent-rules \
	--disable-assert \
	--disable-ssp \

TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

$(foreach component,$(SHADOWSOCKS_COMPONENTS), \
  $(eval $(call BuildPackage,shadowsocks-libev-$(component))) \
)
