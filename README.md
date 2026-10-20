# cxxrt

The C++ runtime for ported libraries on [Phorepoc](https://github.com/Phorepoc): a modern libstdc++ (GCC 13.3, C++17/20)
that runs on Symbian's Open C, and the POSIX functions Open C lacks. The browser engine
([webkit-symbian](https://github.com/Phorepoc/webkit-symbian)) and other ports ([codecpack](https://github.com/Phorepoc/codecpack):
OpenH264) link it.

GCC's sources are not copied here: `recipes/` fetches the release pinned in `gcc.lock` (SHA-256) and builds libstdc++ from
it over Open C's headers.

| path | what |
|---|---|
| `recipes/build_libstdcxx.sh` | libstdc++ from the GCC source for x32 or ARM (ARMv7 Thumb-2 + VFP), over Open C / P.I.P.S. headers; then `ph_weaken_throws.sh` and `package_libgcc.sh` |
| `recipes/build_phcompat.sh` | `libphcompat.a`: the sources in `os/src/cxxrt/compat/` |
| `recipes/build_cxxtest.sh` | the `cxx17test` archive, `EH=1` adds the exception-registration glue |
| `recipes/try_compile.sh`, `cmath_probe.sh` | probes: compile one file against the headers; list what `<cmath>` and friends name that Open C lacks |
| `os/src/cxxrt/compat/` | libphcompat: C99 math (`phmath.c`), an aligned allocator for WebKit's FastMalloc (`phmem.c`), `poll()` over `select()` (`phpoll.c`), the POSIX/BSD calls Open C lacks (`phposix.c`, `phmisc.c`, `phsig.c`) |
| `os/src/cxxrt/ph_throw.cpp` | libstdc++'s `std::__throw_*` as strong symbols that log and panic (`CXX-THROW`): a throw the images cannot unwind says why it died. Add it to an image's sources |
| `os/src/cxxrt/eh_register.cpp` | the glue that hands an image's `.eh_frame` to libgcc's unwinder (C++ exceptions are not finished yet; the engines build without them) |
| `os/src/cxxrt/cxx17_test.cpp`, `cxxrt_main.cpp`, `group/cxx17test.mmp` | the test: `std::string`, containers, `std::function`, `optional`, `variant`, threads |
| `registry/components_cxxrt.py` | the `cxx17test` component |
| `tests/run_cxx17test.sh` | builds and boots the test |
| `gcc.lock` | the GCC pin |
| `build.sh` | all of it, start to end |

The pure-Open-C compiler wrappers (`mk_pure_wrappers.sh`) and the POSIX header overlay (`poll.h`, `uchar.h`, `sys/...`,
`ph_cxx_compat.h`) are the [pdk](https://github.com/Phorepoc/pdk)'s (`tools/toolchain/`); the recipes use them from there.

## Building

This repository is a layer, like the adaptations: it adds its `os/` to the OS tree and its registry entries to core's.
Inside the toolchain container (`ghcr.io/phorepoc/base`: GCC 13 with the x32 runtime, and the Arm GNU toolchain for
`ARCH=arm`), with [core](https://github.com/Phorepoc/core) and the pdk checked out next to this repository and the include
tree exported (`ph source export -a`). `PHOREPOC_ADAPTATIONS` names the board's adaptation, the OS tree the Open C compile
line is derived from:

```sh
docker run --rm --cpus=6 -v "$PWD/..:/src" -e PHOREPOC_PDK=/src/pdk -e PHOREPOC_CORE=/src/core -e PHOREPOC_BUILD=/src/core/build \
    -e PHOREPOC_ADAPTATIONS=/src/adaptation-x86-64 -w /src/cxxrt ghcr.io/phorepoc/base bash build.sh    # add -e ARCH=arm for ARM
```

Output: `$PHOREPOC_BUILD/thirdparty/x86/cxxrt/` (`libstdc++.a`, `libgcc.a`, `libgcc_eh.a`, `libphcompat.a`, `cxx17test.a`) and
`.../thirdparty/arm/cxxrt/`; the GCC source and the build tree are in `$PHOREPOC_BUILD/cxxrt-work/`. Other layers link
the archives through their registry entries (`x32_archives=["thirdparty/x86/cxxrt/libstdc++.a", ...]`). Building the test
component: `PHOREPOC_ADAPTATIONS=<board adaptations>:<cxxrt> ph component build -b pc cxx17test`.

## Licence

Our files are Apache-2.0 (see `LICENSE`), copyright The Phorepoc Authors (`AUTHORS`). The libstdc++ and libgcc the recipes
build are GPL-3.0 with the GCC Runtime Library Exception, which allows linking them into programs under any licence;
`NOTICE` has the details and `LICENSES/` the texts.

Contributions are welcome under the same terms: add yourself to `AUTHORS`.
