#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# fetch_gcc.sh -- the pinned GCC release tarball (gcc.lock, SHA-256 checked) -> $PHOREPOC_BUILD/cxxrt-work/dl/.
# build_libstdcxx.sh unpacks libstdc++-v3, libgcc and the licence texts from it.
set -eu
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
fetch_verified "$GCC_URL" "$GCC_SHA256" "$GCC_TARBALL"
echo "GCC $GCC_VERSION: $GCC_TARBALL"
