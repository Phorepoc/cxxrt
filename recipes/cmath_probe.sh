#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# cmath_probe.sh -- lists what <cmath>/<cstdlib>/<cctype>/<cwchar> name that Open C's headers lack (with the C99 config macros
# on): the work list for os/src/cxxrt/compat/. Inside the toolchain container, after build_libstdcxx.sh (x32).
HERE=$(cd "$(dirname "$0")" && pwd)
ARCH=x32
. "$HERE/env.sh"
P=$CXXRT_WORK/cmath_probe.cpp
echo '#include <cmath>
#include <cstdlib>
#include <cctype>
#include <cwchar>
int main(){return 0;}' > $P
$W/bin/ph-g++ -I$W/build/include/x86_64-unknown-elf -I$W/build/include -I$GCC_SRC/libstdc++-v3/libsupc++ -std=gnu++20 -fsyntax-only -fmax-errors=0 $P 2>&1 | grep "error:" | sed "s/.*error: //" | sort | uniq -c | sort -rn | head -${N:-80}
