# Copyright The Phorepoc Authors
# SPDX-License-Identifier: Apache-2.0

r"""components_cxxrt -- the cxxrt layer's components (merged into core's registry when this repository is built:
PHOREPOC_ADAPTATIONS=<board adaptations>:<cxxrt>, see the pdk's tools/emitter/paths.py).

OS paths are relative to the merged OS tree. The archives are not in the tree: build.sh makes them under
$PHOREPOC_BUILD/thirdparty/{x86,arm}/cxxrt/ (libstdc++.a, libgcc.a, libgcc_eh.a, libphcompat.a, cxx17test.a), which is
where the "thirdparty/..." paths below resolve. Other layers (webkit-symbian, codecpack) link libstdc++.a, libgcc.a and
libphcompat.a from the same place."""
import os

from paths import OS_ROOT

COMPONENTS = {
    # A C++20 program on libstdc++ 13 (built by recipes/build_libstdcxx.sh from the GCC source over Open C): std::string,
    # containers, threads, exceptions. The standard-C++ part is a prebuilt archive (recipes/build_cxxtest.sh), linked through
    # x32_archives. eh=True (CXX_EH=1 in the environment): x32_exe_eh.ld keeps .eh_frame and the LSDAs in the code segment
    # (eh_register.cpp hands them to libgcc's unwinder).
    "cxx17test": dict(mmp=os.path.join(OS_ROOT, "src/cxxrt/group/cxx17test.mmp"), allow_wsd=True, static_ctors=True,
                      eh=os.environ.get("CXX_EH", "0") == "1", rtti=True, defs=["__SOFTFP="], stack=0x14000,
                      x32_archives=[f"thirdparty/x86/cxxrt/{a}.a" for a in ("cxx17test", "libstdc++", "libgcc_eh", "libgcc")]),
}
