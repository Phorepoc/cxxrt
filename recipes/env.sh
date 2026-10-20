# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# Sourced by the recipes. Runs inside the toolchain container (ghcr.io/phorepoc/base), like the pdk's build tools:
#   PHOREPOC_PDK     the pdk checkout (tools/openc_cflags.py, tools/toolchain/mk_pure_wrappers.sh)
#   PHOREPOC_CORE    core (default: ../core); PHOREPOC_BUILD  all generated files (default: $PHOREPOC_CORE/build)
#   ARCH             x32 (default) or arm
# The include tree must be exported first (the pdk's tools/epoc32_export.py, `ph source export -a`).
#
#   OUT   the archives: $PHOREPOC_BUILD/thirdparty/{x86,arm}/cxxrt  (what the registry entries link)
#   W     the work dir of this architecture: the GCC source, the libstdc++ build tree, the compiler wrappers
CXXRT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${PHOREPOC_CORE:=$CXXRT/../core}"
: "${PHOREPOC_BUILD:=$PHOREPOC_CORE/build}"
: "${PHOREPOC_PDK:=$CXXRT/../pdk}"
export PHOREPOC_CORE PHOREPOC_BUILD PHOREPOC_PDK
. "$CXXRT/gcc.lock"
GCC_TARBALL=$PHOREPOC_BUILD/cxxrt-work/dl/gcc-$GCC_VERSION.tar.xz
ARCH=${ARCH:-x32}
if [ "$ARCH" = arm ]; then
    TP=arm; CROSS=arm-none-eabi-; HOST=arm-none-eabi; LTRIP=arm-none-eabi; OSSL_TARGET=linux-armv4
else
    TP=x86; CROSS=; HOST=x86_64-unknown-elf; LTRIP=x86_64-unknown-elf; OSSL_TARGET=linux-x32
fi
CXXRT_WORK=$PHOREPOC_BUILD/cxxrt-work
W=${W:-$CXXRT_WORK/lsc-$ARCH}
OUT=${OUT:-$PHOREPOC_BUILD/thirdparty/$TP/cxxrt}
OVR=$PHOREPOC_PDK/tools/toolchain/openc_posix       # the POSIX header overlay (poll.h, uchar.h, ph_cxx_compat.h ...)
GCC_SRC=$W/gcc-$GCC_VERSION
mkdir -p "$W" "$OUT"

# fetch_verified URL SHA256 OUTFILE -- download unless OUTFILE already has that hash; fail on a mismatch
fetch_verified() {
    local url=$1 want=$2 out=$3 got
    if [ -f "$out" ] && [ "$(sha256sum "$out" | cut -d' ' -f1)" = "$want" ]; then return 0; fi
    mkdir -p "$(dirname "$out")"
    curl -fsSL --retry 3 -o "$out.part" "$url"
    got=$(sha256sum "$out.part" | cut -d' ' -f1)
    if [ "$got" != "$want" ]; then
        rm -f "$out.part"
        echo "sha256 mismatch for $url: got $got, want $want" >&2
        return 1
    fi
    mv "$out.part" "$out"
}
