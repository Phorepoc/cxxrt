#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# build_cxxtest.sh -- the C++17 test (os/src/cxxrt/cxx17_test.cpp) + the exception-registration glue (eh_register.cpp), compiled
# against the libstdc++ headers of build_libstdcxx.sh, into $OUT/cxx17test.a for the `cxx17test` registry component.
# Inside the toolchain container (x32 only), after build_libstdcxx.sh:   [EH=1] bash recipes/build_cxxtest.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ARCH=x32
. "$HERE/env.sh"
D=$CXXRT/os/src/cxxrt
inc="-I$W/build/include/x86_64-unknown-elf -I$W/build/include -I$GCC_SRC/libstdc++-v3/libsupc++"
for src in cxx17_test eh_register; do
  $W/bin/ph-g++ $inc -std=gnu++20 -fexceptions -frtti -O2 -g0 ${EH:+-DPH_EH} -c $D/$src.cpp -o $OUT/$src.o 2>&1 | grep -v "SYMBIAN_ENABLE\|previous def\|^ *1864\|^ *|\|In file included from <command" | head -${N:-30}
done
rm -f $OUT/cxx17test.a; ar rcs $OUT/cxx17test.a $OUT/cxx17_test.o ${EH:+$OUT/eh_register.o}   # EH=1: + the .eh_frame registration (unfinished, see below)
bash $HERE/package_libgcc.sh
if [ -n "${EH:-}" ]; then
# ld rewrites .eh_frame (it drops the FDEs of --gc-sections'd functions, merges CIEs) but --emit-relocs keeps the OLD relocation
# offsets -> the E32 emitter relocates the wrong words (seen: 182 corrupted words in the ROM's eh table). UNFINISHED.
for a in cxx17test libstdc++ libgcc_eh libgcc; do
  objcopy --rename-section .eh_frame=.ph_eh_frame,alloc,load,readonly,data,contents $OUT/$a.a
done
fi
ls -l $OUT/*.a
