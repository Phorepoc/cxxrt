#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# build_phcompat.sh -- libphcompat.a (os/src/cxxrt/compat/*.c: POSIX and C99 functions Open C lacks) on the pure Open C
# line. Inside the toolchain container, after build_libstdcxx.sh:  ARCH=x32|arm bash recipes/build_phcompat.sh
# -> $OUT/libphcompat.a
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/env.sh"
D=$CXXRT/os/src/cxxrt/compat; T=$CXXRT_WORK/phcompat-$ARCH; rm -rf $T; mkdir -p $T
# the pure Open C compiler wrappers ($W/bin/pp-gcc, pp-g++) are the pdk's
ARCH=$ARCH W=$W bash $PHOREPOC_PDK/tools/toolchain/mk_pure_wrappers.sh >/dev/null || exit 1
for f in $D/*.c; do $W/bin/pp-gcc -O2 -g0 -Wall -Wno-unused -c $f -o $T/$(basename $f .c).o 2>&1 | grep -v "Wmissing-field\|PTHREAD_\|^ *[0-9]* |\|^ *|\|In file included\|from " ; done
rm -f $OUT/libphcompat.a; ${CROSS}ar rcs $OUT/libphcompat.a $T/*.o; ls -l $OUT/libphcompat.a
