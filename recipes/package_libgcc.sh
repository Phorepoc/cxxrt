#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# package_libgcc.sh -- libgcc.a / libgcc_eh.a of the container's compiler into $OUT, next to libstdc++.a (GPL-3.0 with the
# GCC Runtime Library Exception: see NOTICE). Inside the toolchain container.
#   x32: the compiler's x32 multilib.   arm: libgcc.a for ARMv7 Thumb-2 + soft-float ABI (the 64-bit division / shift helpers
#   the engines call); the toolchain's default v7 libgcc has MOVW relocations E32 cannot carry, so an ARM image links its own.
set -u
. "$(dirname "$0")/env.sh"
if [ "$ARCH" = arm ]; then
  cp "$(arm-none-eabi-gcc -march=armv7-a -mthumb -mfloat-abi=softfp -mfpu=vfpv3-d16 -print-libgcc-file-name)" $OUT/libgcc.a
else
  cp "$(gcc -mx32 -print-file-name=libgcc_eh.a)" $OUT/libgcc_eh.a
  cp "$(gcc -mx32 -print-file-name=libgcc.a)" $OUT/libgcc.a
fi
ls -l $OUT/libgcc*.a
