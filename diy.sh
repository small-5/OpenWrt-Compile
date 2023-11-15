#!/bin/bash
VERSION="民國112年11月16日 By Small_5"
A=0
[ -n "$OP_TARGET" ] || OP_TARGET="X64"
case "$OP_TARGET" in
	X64)path="X64";;
	R7800)path="R7800";;
	N1)path="N1";;
	RPI-4)path="RPI-4";;
	R2S)path="R2S";A=1;;
	R4S)path="R4S";A=1;;
	R1-PLUS)path="R1-PLUS";A=1;;
	AC58U)path="AC58U";A=2;;
	ACRH17)path="ACRH17";A=2;;
	R619AC-128M)path="R619AC-128M";A=2;;
	MT3000)path="MT3000";A=3;;
	NANOPI-NEO2)path="NANOPI-NEO2";;
	*)echo "No adaptation target!";exit 1;;
esac
cp -r target/$path/. Small_5

if [ $A = 1 ];then
	rm -rf openwrt/include/u-boot.mk openwrt/package/boot/{arm-trusted-firmware-rockchip,uboot-rockchip} openwrt/package/kernel/linux/modules/video.mk openwrt/target/linux/rockchip
	cp -r target/target/rockchip/. Small_5
elif [ $A = 2 ];then
	cp -r target/target/ipq40xx/. Small_5
elif [ $A = 3 ];then
	rm -rf openwrt/package/boot/{arm-trusted-firmware-mediatek,uboot-mediatek} openwrt/target/linux/mediatek
	cp -r target/target/mediatek/. Small_5
	chmod +x Small_5/target/linux/mediatek/base-files/etc/hotplug.d/iface/99-mtk-lro
fi

cp -r Small_5/. openwrt
rm -rf Openwrt_Custom Small_5 target SHA README.md
cd openwrt

cat > version.patch  <<EOF
--- a/package/base-files/files/etc/banner
+++ b/package/base-files/files/etc/banner
@@ -4,5 +4,5 @@
  |_______||   __|_____|__|__||________||__|  |____|
           |__| W I R E L E S S   F R E E D O M
  -----------------------------------------------------
- %D %V, %C
+ %D $VERSION
  -----------------------------------------------------

--- a/package/base-files/files/etc/openwrt_release
+++ b/package/base-files/files/etc/openwrt_release
@@ -1,7 +1,6 @@
 DISTRIB_ID='%D'
-DISTRIB_RELEASE='%V'
-DISTRIB_REVISION='%R'
+DISTRIB_RELEASE='$VERSION'
 DISTRIB_TARGET='%S'
 DISTRIB_ARCH='%A'
-DISTRIB_DESCRIPTION='%D %V %C'
+DISTRIB_DESCRIPTION='%D $VERSION'
 DISTRIB_TAINTS='%t'

--- a/package/base-files/files/usr/lib/os-release
+++ b/package/base-files/files/usr/lib/os-release
@@ -1,8 +1,8 @@
 NAME="%D"
-VERSION="%V"
+VERSION="$VERSION"
 ID="%d"
 ID_LIKE="lede openwrt"
-PRETTY_NAME="%D %V"
+PRETTY_NAME="%D $VERSION"
 VERSION_ID="%v"
 HOME_URL="%u"
 BUG_URL="%b"
@@ -15,4 +15,4 @@
 OPENWRT_DEVICE_MANUFACTURER_URL="%m"
 OPENWRT_DEVICE_PRODUCT="%P"
 OPENWRT_DEVICE_REVISION="%h"
-OPENWRT_RELEASE="%D %V %C"
+OPENWRT_RELEASE="%D $VERSION"
EOF

patch -p1 -E < default.patch && patch -p1 -E < feeds.patch && patch -p1 -E < version.patch && rm -f default.patch feeds.patch version.patch
for i in $(find -maxdepth 1 -name 'Patch-*.patch' | sed 's#.*/##');do
	patch -p1 -E < $i
done
rm -f Patch-*.patch
echo "Model:$OP_TARGET"
