#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# build_libstdcxx.sh -- libstdc++ (GCC 13.3 source, gcc.lock) for Symbian over Open C / P.I.P.S. headers. Inside the
# toolchain container (ghcr.io/phorepoc/base; the ARM compiler is in it too):
#
#   ARCH=x32|arm bash recipes/build_libstdcxx.sh
#
# x32: the amd64 board's ABI. arm: ARMv7 Thumb-2 + VFP, soft-float ABI (links with the ARMv5TE userland of the ROM),
# built with the container's arm-none-eabi-gcc. Output: $OUT/libstdc++.a (see env.sh), then libgcc_eh.a / libgcc.a
# (package_libgcc.sh). The configured build tree and the compiler wrappers stay in $W (webkit-symbian reads them).
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/env.sh"
bash "$HERE/fetch_gcc.sh" || exit 1
if [ "$ARCH" = arm ]; then
  CFL=--arm; MFL="-march=armv7-a -mthumb -mfloat-abi=softfp -mfpu=vfpv3-d16 -mword-relocations"   # E32 relocates 32-bit words only: no MOVW/MOVT
  GINC=$(arm-none-eabi-gcc -print-file-name=include)
else
  CFL=; MFL=-mx32; GINC=$(gcc -print-file-name=include)
fi
S=$GCC_SRC
[ -d $S/libstdc++-v3 ] || tar -C $W --exclude="gcc-$GCC_VERSION/gcc" --exclude="gcc-$GCC_VERSION/gcc-*" -xf $GCC_TARBALL || exit 1
[ -f $S/gcc/DATESTAMP ] || tar -C $W -xf $GCC_TARBALL gcc-$GCC_VERSION/gcc/DATESTAMP gcc-$GCC_VERSION/gcc/BASE-VER gcc-$GCC_VERSION/gcc/DEV-PHASE
# the Open C compile line for a C/C++ program, minus what libstdc++'s own configure must decide itself
mapfile -t FL < <(python3 $PHOREPOC_PDK/tools/openc_cflags.py --exe $CFL | grep -v -x -E -e '-x|c|-march=armv5te|-marm|-mfloat-abi=soft|-std=gnu11|-fno-exceptions|-fno-rtti|-fshort-wchar|-w|-ffreestanding|-fno-builtin|-masm=intel|-Dwchar_t=unsigned short|-D__SOFTFP=')
[ "${#FL[@]}" -gt 10 ] || { echo "build_libstdcxx: openc_cflags.py failed (is the include tree exported, the build dir writable?)"; exit 1; }
mkdir -p $W/bin
for t in gcc g++; do   # libstdc++ own -I first (its cstdlib include_next must find stdapis AFTER it), the Open C line after "$@"
  { echo "#!/bin/sh"; echo -n "exec $CROSS$t $MFL "'"$@"'" "; printf "'%s' " "${FL[@]}" "-I$OVR" -include $OVR/ph_cxx_compat.h -idirafter $GINC; echo; } > $W/bin/ph-$t; chmod +x $W/bin/ph-$t
done
# os/newlib assumes newlib ctype tables; Open C ctype is functions -> take os/generic (self-built table) for the OS dir
cp $S/libstdc++-v3/config/os/generic/* $S/libstdc++-v3/config/os/newlib/
cp $S/libgcc/gthr-posix.h $S/libgcc/gthr-default.h   # what gcc/configure generates in-tree; configure probes gthr.h with it
B=$W/build; mkdir -p $B; cd $B
if [ ! -f Makefile ]; then
  sed -i 's/^\( *\)as_fn_error \$? "Link tests are not allowed.*/\1:/' $S/libstdc++-v3/configure   # link tests then RUN and FAIL (-nostdlib): every function is "absent"
  # arm-none-eabi-gcc reports "Thread model: single" (bare metal); our threads are Open C pthreads, as on x32
  sed -i 's/^\( *\)target_thread_file=`\$CXX -v 2>&1 .*/\1target_thread_file=posix/' $S/libstdc++-v3/configure
  CC=$W/bin/ph-gcc CXX=$W/bin/ph-g++ LDFLAGS="-nostdlib -nostartfiles -static" CFLAGS="-O2 -g0" CXXFLAGS="-O2 -g0 -fexceptions -frtti" \
  $S/libstdc++-v3/configure --host=$HOST --build=x86_64-linux-gnu --with-newlib --disable-shared --enable-static \
     --disable-multilib --disable-libstdcxx-pch --disable-nls --disable-libstdcxx-dual-abi --disable-libstdcxx-filesystem-ts \
     --enable-libstdcxx-threads --disable-libstdcxx-backtrace --with-default-libstdcxx-abi=new > $OUT/configure.log 2>&1 || { tail -30 $OUT/configure.log; exit 1; }
fi
echo configured
cd $B
make -C include > $OUT/make-inc.log 2>&1 || tail -5 $OUT/make-inc.log
make -k -j${JOBS:-$(nproc)} > $OUT/make.log 2>&1
echo "make exit $?"; grep -c "error:" $OUT/make.log
# the archive is assembled by hand: -k leaves a few TUs out (std::filesystem dir ops, <chrono> tzdb, long-double math stubs:
# Open C lacks d_type / has C long double overloads) -- none of which the browser needs
rm -f $OUT/libstdc++.a; find $B/src $B/libsupc++ -name '*.o' ! -path '*/.libs/*.dll*' | sort > $OUT/objs.txt
${CROSS}ar rcs $OUT/libstdc++.a $(cat $OUT/objs.txt); ls -l $OUT/libstdc++.a; wc -l < $OUT/objs.txt
# libstdc++'s own throws (std::__throw_*) become weak: ph_throw.cpp (an object of each image) defines them -- log + panic
# instead of a throw our images cannot unwind. ph_weaken_throws.sh = this step alone.
CROSS=$CROSS bash $HERE/ph_weaken_throws.sh $OUT/libstdc++.a
bash $HERE/package_libgcc.sh
