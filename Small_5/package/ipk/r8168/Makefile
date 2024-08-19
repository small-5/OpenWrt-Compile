include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=r8168
PKG_VERSION:=8.053.00
PKG_RELEASE:=3

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/r8168
  TITLE:=Driver for Realtek r8168 chipsets
  SUBMENU:=Network Devices
  DEPENDS:=@PCI_SUPPORT
  FILES:= $(PKG_BUILD_DIR)/r8168.ko
  AUTOLOAD:=$(call AutoProbe,r8168)
  CONFLICTS:=kmod-r8169
endef

define KernelPackage/r8168/description
  This package contains a driver for Realtek r8168 chipsets.
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M=$(PKG_BUILD_DIR) \
		modules
endef

$(eval $(call KernelPackage,r8168))
