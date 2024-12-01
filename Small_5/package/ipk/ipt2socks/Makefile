include $(TOPDIR)/rules.mk

PKG_NAME:=ipt2socks
PKG_VERSION:=1.1.4
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/zfl9/ipt2socks.git
PKG_SOURCE_VERSION:=1a5f20895d8258b1eca104614fb15390320eac1a
PKG_MIRROR_HASH:=adfcbc862a1fdcae31eb2ece38a1b04f355213d0486bda81e8f331baf51fe983

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16 gc-sections lto

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/ipt2socks
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Convert iptables to socks5
	URL:=https://github.com/zfl9/ipt2socks
	DEPENDS:=+libpthread
endef

define Package/ipt2socks/description
	Utility for converting iptables (redirect/tproxy) to socks5.
endef

TARGET_CFLAGS+= $(FPIC)
MAKE_FLAGS+= \
	CFLAGS="-std=c99 -pthread $(TARGET_CFLAGS)" \
	EVCFLAGS="$(TARGET_CFLAGS)"

define Package/ipt2socks/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipt2socks $(1)/usr/bin
endef

$(eval $(call BuildPackage,ipt2socks))
