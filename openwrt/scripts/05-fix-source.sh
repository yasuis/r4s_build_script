#!/bin/bash

# libsodium - fix build with lto (GNU BUG - 89147)
sed -i "/CONFIGURE_ARGS/i\TARGET_CFLAGS += -ffat-lto-objects\n" feeds/packages/libs/libsodium/Makefile

# grub2 -  disable `gc-sections` flag
sed -i '/PKG_BUILD_FLAGS/ s/$/ no-gc-sections/' package/boot/grub2/Makefile

# fix gcc13
if [ "$USE_GCC13" = "y" ] || [ "$USE_GCC14" = y ]; then
    # libwebsockets
    mkdir feeds/packages/libs/libwebsockets/patches
    pushd feeds/packages/libs/libwebsockets/patches
        curl -sLO https://raw.githubusercontent.com/openwrt/packages/bcd970fb4ff6029fbf612dccf6d8c2902a65e20e/libs/libwebsockets/patches/010-fix-enum-int-mismatch-openssl.patch
        curl -sLO https://raw.githubusercontent.com/openwrt/packages/bcd970fb4ff6029fbf612dccf6d8c2902a65e20e/libs/libwebsockets/patches/011-fix-enum-int-mismatch-mbedtls.patch
        curl -sLO https://raw.githubusercontent.com/openwrt/packages/94bd1ca8bad053a772a3ea8cb06ce59241fb9a57/libs/libwebsockets/patches/100-fix-uninitialized-variable-usage.patch
    popd
fi

# fix gcc14
if [ "$USE_GCC14" = y ]; then
    # iproute2
    rm -rf package/network/utils/iproute2
    git clone https://$github/sbwml/package_network_utils_iproute2 package/network/utils/iproute2
    # openvswitch
    [ "$version" = "rc2" ] && curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/openvswitch/0008-ovs-atomic-Fix-inclusion-of-Clang-header-by-GCC-14.patch > feeds/packages/net/openvswitch/patches/0008-ovs-atomic-Fix-inclusion-of-Clang-header-by-GCC-14.patch
    # wsdd2
    mkdir -p feeds/packages/net/wsdd2/patches
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/wsdd2/100-wsdd2-cast-from-pointer-to-integer-of-different-size.patch > feeds/packages/net/wsdd2/patches/100-wsdd2-cast-from-pointer-to-integer-of-different-size.patch
    # libunwind
    rm -rf package/libs/libunwind
    git clone https://$github/sbwml/package_libs_libunwind package/libs/libunwind
    # lrzsz
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/lrzsz/900-lrzsz-fix-gcc14.patch > package/new/lrzsz/patches/900-lrzsz-fix-gcc14.patch
    sed -i '/lrzsz\/install/iTARGET_CFLAGS += -Wno-implicit-function-declaration -Wno-builtin-declaration-mismatch -Wno-incompatible-pointer-types' package/new/lrzsz/Makefile
    # mbedtls
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/mbedtls/900-tests-fix-calloc-argument-list-gcc-14-fix.patch > package/libs/mbedtls/patches/900-tests-fix-calloc-argument-list-gcc-14-fix.patch
    # linux-atm
    rm -rf package/network/utils/linux-atm
    git clone https://$github/sbwml/package_network_utils_linux-atm package/network/utils/linux-atm
    # lsof
    rm -rf feeds/packages/utils/lsof
    cp -a ../master/packages/utils/lsof feeds/packages/utils/lsof
    # screen
    SCREEN_VERSION=4.9.1
    SCREEN_HASH=26cef3e3c42571c0d484ad6faf110c5c15091fbf872b06fa7aa4766c7405ac69
    sed -ri "s/(PKG_VERSION:=)[^\"]*/\1$SCREEN_VERSION/;s/(PKG_HASH:=)[^\"]*/\1$SCREEN_HASH/" feeds/packages/utils/screen/Makefile
    rm -rf feeds/packages/utils/screen/patches && mkdir -p feeds/packages/utils/screen/patches
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/screen/900-fix-implicit-function-declaration.patch > feeds/packages/utils/screen/patches/900-fix-implicit-function-declaration.patch
    # xdp-tools
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/xdp-tools/900-Fix-transposed-calloc-arguments.patch > package/network/utils/xdp-tools/patches/900-Fix-transposed-calloc-arguments.patch
    # perl
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/perl/1000-fix-implicit-declaration-error.patch > feeds/packages/lang/perl/patches/1000-fix-implicit-declaration-error.patch
    # grub2
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/grub2/900-fix-incompatible-pointer-type.patch > package/boot/grub2/patches/900-fix-incompatible-pointer-type.patch
fi

# xdp-tools
[ "$platform" != "x86_64" ] && sed -i '/TARGET_LDFLAGS +=/iTARGET_CFLAGS += -Wno-error=maybe-uninitialized -ffat-lto-objects\n' package/network/utils/xdp-tools/Makefile
[ "$platform" = "x86_64" ] && sed -i '/TARGET_LDFLAGS +=/iTARGET_CFLAGS += -ffat-lto-objects\n' package/network/utils/xdp-tools/Makefile

# ksmbd luci
rm -rf feeds/luci/applications/luci-app-ksmbd
cp -a ../master/luci/applications/luci-app-ksmbd feeds/luci/applications/luci-app-ksmbd
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/luci/applications/luci-app-ksmbd/htdocs/luci-static/resources/view/ksmbd.js

# ksmbd tools
rm -rf feeds/packages/net/ksmbd-tools
cp -a ../master/packages/net/ksmbd-tools feeds/packages/net/ksmbd-tools
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/ksmbd-tools/files/ksmbd.config.example
sed -i 's/bind interfaces only = yes/bind interfaces only = no/g' feeds/packages/net/ksmbd-tools/files/ksmbd.conf.template

# vim - fix E1187: Failed to source defaults.vim
pushd feeds/packages
    curl -s https://github.com/openwrt/packages/commit/699d3fbee266b676e21b7ed310471c0ed74012c9.patch | patch -p1
popd

# bpf - add host clang-15/17 support
sed -i 's/command -v clang/command -v clang clang-17 clang-15/g' include/bpf.mk

# perf
curl -s https://$mirror/openwrt/patch/openwrt-6.x/musl/990-add-typedefs-for-Elf64_Relr-and-Elf32_Relr.patch > toolchain/musl/patches/990-add-typedefs-for-Elf64_Relr-and-Elf32_Relr.patch
curl -s https://$mirror/openwrt/patch/openwrt-6.x/perf/Makefile > package/devel/perf/Makefile
