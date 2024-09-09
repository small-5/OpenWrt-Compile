include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=r8152
PKG_VERSION:=2.18.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/usb-net-rtl8152-vendor
  TITLE:=Kernel module for USB-to-Ethernet Realtek convertors
  SUBMENU:=USB Support
  DEPENDS:=+kmod-usb-net
  CONFLICTS:=kmod-usb-net-rtl8152
  FILES:=$(PKG_BUILD_DIR)/r8152.ko
  AUTOLOAD:=$(call AutoProbe,r8152)
endef

define KernelPackage/usb-net-rtl8152-vendor/description
  Kernel module for Realtek RTL8152/RTL8153 Based USB Ethernet Adapters
endef

define Build/Compile
	+$(KERNEL_MAKE) M=$(PKG_BUILD_DIR) modules
endef

$(eval $(call KernelPackage,usb-net-rtl8152-vendor))
