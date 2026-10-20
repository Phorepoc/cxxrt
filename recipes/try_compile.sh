#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# try_compile.sh [file.cpp] -- probe: compile one C++ file for x32 with the Open C headers and the container's libstdc++ headers.
# Inside the toolchain container; the include tree must be exported.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/env.sh"
mapfile -t FL < <(python3 $PHOREPOC_PDK/tools/openc_cflags.py --exe | grep -v -x -E -e '-x|c|-std=gnu11|-fno-exceptions|-fno-rtti|-fshort-wchar')
printf '%s\n' "${FL[@]}" | tail -8
SRC=${1:-$CXXRT/os/src/cxxrt/cxx17_test.cpp}
g++ -mx32 -x c++ -std=gnu++20 -fexceptions -frtti -O2 "${FL[@]}" -isystem /usr/include/c++/13 -isystem /usr/include/x86_64-linux-gnu/c++/13/x32 -c $SRC -o $CXXRT_WORK/try_compile.o 2>&1 | head -${N:-40}
