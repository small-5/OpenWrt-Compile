#!/bin/bash
VERSION="民國111年雙十紀念版"
A=0
[ -n "$OP_TARGET" ] || OP_TARGET="X64"
case "$OP_TARGET" in
	X64)path="X64";;
	R7800)path="R7800";;
	N1)path="N1";;
	RPI-4)path="RPI-4";;
	K2P-16M)path="K2P";A=1;B=1;;
	K2P-32M)path="K2P";A=1;;
	MI-AC2100)path="MI-AC2100";A=1;;
	REDMI-AC2100)path="REDMI-AC2100";A=1;;
	CR660X)path="CR660X";A=1;;
	D2)path="D2";A=1;;
	XY-C5)path="XY-C5";A=1;;
	R2S)path="R2S";A=2;;
	R4S)path="R4S";A=2;;
	R1-PLUS)path="R1-PLUS";A=2;;
	AC58U)path="AC58U";A=3;;
	ACRH17)path="ACRH17";A=3;;
	R619AC-128M)path="R619AC-128M";A=3;;
	NANOPI-NEO2)path="NANOPI-NEO2";;
	*)echo "No adaptation target!";exit 1;;
esac
cp -r target/$path/. Small_5

if [ $A = 1 ];then
	rm -rf openwrt/target/linux/ramips
	cp -r target/target/ramips/. Small_5
	chmod 0775 Small_5/target/linux/ramips/mt76x8/base-files/etc/init.d/* Small_5/target/linux/ramips/mt76x8/base-files/lib/upgrade/*
	chmod 0775 Small_5/target/linux/ramips/mt7620/base-files/etc/init.d/* Small_5/target/linux/ramips/mt7620/base-files/lib/upgrade/*
	chmod 0775 Small_5/target/linux/ramips/mt7621/base-files/etc/init.d/* Small_5/target/linux/ramips/mt7621/base-files/lib/upgrade/platform.sh Small_5/target/linux/ramips/mt7621/base-files/sbin/*
	chmod 0755 Small_5/target/linux/ramips/rt288x/base-files/lib/upgrade/*
	chmod 0755 Small_5/target/linux/ramips/rt305x/base-files/lib/upgrade/*
	chmod 0755 Small_5/target/linux/ramips/rt3883/base-files/lib/upgrade/*
	[ "$B" = 1 ] && rm -f Small_5/Patch-K2P-32M.patch
elif [ $A = 2 ];then
	rm -rf openwrt/package/boot/uboot-rockchip openwrt/package/kernel/linux/modules/video.mk openwrt/target/linux/rockchip
	cp -r target/target/rockchip/. Small_5
	chmod 0775 Small_5/package/boot/arm-trusted-firmware-rockchip-vendor/*.sh
elif [ $A = 3 ];then
	rm -rf openwrt/package/firmware/ipq-wifi openwrt/target/linux/ipq40xx
	cp -r target/target/ipq40xx/. Small_5
	chmod 0775 Small_5/target/linux/ipq40xx/base-files/etc/init.d/* Small_5/target/linux/ipq40xx/base-files/lib/upgrade/*
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
+ %D $VERSION By Small_5, %C
  -----------------------------------------------------

--- a/package/base-files/files/etc/openwrt_release
+++ b/package/base-files/files/etc/openwrt_release
@@ -1,7 +1,7 @@
 DISTRIB_ID='%D'
-DISTRIB_RELEASE='%V'
+DISTRIB_RELEASE='$VERSION By Small_5'
 DISTRIB_REVISION='%R'
 DISTRIB_TARGET='%S'
 DISTRIB_ARCH='%A'
-DISTRIB_DESCRIPTION='%D %V %C'
+DISTRIB_DESCRIPTION='%D $VERSION By Small_5 %C'
 DISTRIB_TAINTS='%t'

--- a/package/base-files/files/usr/lib/os-release
+++ b/package/base-files/files/usr/lib/os-release
@@ -1,8 +1,8 @@
 NAME="%D"
-VERSION="%V"
+VERSION="$VERSION By Small_5"
 ID="%d"
 ID_LIKE="lede openwrt"
-PRETTY_NAME="%D %V"
+PRETTY_NAME="%D $VERSION By Small_5"
 VERSION_ID="%v"
 HOME_URL="%u"
 BUG_URL="%b"
@@ -15,4 +15,4 @@
 OPENWRT_DEVICE_MANUFACTURER_URL="%m"
 OPENWRT_DEVICE_PRODUCT="%P"
 OPENWRT_DEVICE_REVISION="%h"
-OPENWRT_RELEASE="%D %V %C"
+OPENWRT_RELEASE="%D $VERSION By Small_5 %C"
EOF

patch -p1 -E < default.patch && patch -p1 -E < feeds.patch && patch -p1 -E < version.patch && rm -f default.patch feeds.patch version.patch
for i in $(find -maxdepth 1 -name 'Patch-*.patch' | sed 's#.*/##');do
	patch -p1 -E < $i
done
rm -f Patch-*.patch
echo "Model:$OP_TARGET"
