#!/usr/bin/env bash
# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0
#
# run_cxx17test.sh -- build the cxx17test component, a ROM that boots only it, run the ROM and print the "[cxxrt]" lines
# (the test reports over RDebug; a passing run ends "fails=0").
#
# On the host, with the pdk's `ph` on PATH, after `bash build.sh` (in the toolchain container):
#   PHOREPOC_ADAPTATIONS=<board adaptations>:<cxxrt> PHOREPOC_RUN='<command>' bash tests/run_cxx17test.sh
# PHOREPOC_RUN starts the built ROM on the board (QEMU, VirtualBox ...) and writes its serial log to stdout, e.g. a wrapper
# around the board's emulator command; it is not part of this repository. BOARD defaults to pc.
set -eu
: "${PHOREPOC_RUN:?set PHOREPOC_RUN to the command that boots the ROM and prints the serial log}"
BOARD=${BOARD:-pc}
ph component build -b "$BOARD" cxx17test
ph image rom -b "$BOARD" -s cxx17test
sh -c "$PHOREPOC_RUN" | grep -a "\[cxxrt\]\|cxx17test\|CRASH\|PANIC\|FAULT" | head -"${N:-20}" | cut -c1-250
