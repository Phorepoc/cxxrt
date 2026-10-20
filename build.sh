#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# build.sh -- everything the registry entries link, for one architecture (ARCH=x32 default, or arm): libstdc++, libgcc,
# libphcompat, and for x32 the cxx17test archive. Inside the toolchain container with PHOREPOC_PDK / PHOREPOC_CORE /
# PHOREPOC_BUILD set (see README.md) and the include tree exported.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
bash "$here/recipes/build_libstdcxx.sh"
bash "$here/recipes/build_phcompat.sh"
[ "${ARCH:-x32}" = arm ] || bash "$here/recipes/build_cxxtest.sh"
