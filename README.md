# cxxrt

Symbian's C++ library dates from 2010, so modern C++ code can't use it. cxxrt fixes that for
[Phorepoc OS](https://github.com/Phorepoc). It builds GCC 13.3's libstdc++, with C++17 and C++20, on top of the
system's POSIX layer (Open C), and adds the POSIX functions Open C never had.

It's what lets big ports run at all. The WebKit engine in [webkit-symbian](https://github.com/Phorepoc/webkit-symbian)
links it, and so does OpenH264 in [codecpack](https://github.com/Phorepoc/codecpack).

This repository does not keep a copy of GCC. The recipe downloads the release named in `gcc.lock`, checks it against its SHA-256,
and builds libstdc++ from it.

## Building

Check out core and the [pdk](https://github.com/Phorepoc/pdk) next to this repository and run `phe source export -a`
once. Then build in the toolchain container:

```sh
docker run --rm --cpus=6 -v "$PWD/..:/src" -e PHOREPOC_PDK=/src/pdk -e PHOREPOC_CORE=/src/core \
    -e PHOREPOC_BUILD=/src/core/build -e PHOREPOC_ADAPTATIONS=/src/<adaptation> \
    -w /src/cxxrt ghcr.io/phorepoc/base bash build.sh
```

Add `-e ARCH=arm` for an ARM board, and set `PHOREPOC_ADAPTATIONS` to that board's repositories. The libraries end up
in `$PHOREPOC_BUILD/thirdparty/x86/cxxrt/` (or `arm/`), where other ports pick them up.

There's a test program that exercises strings, containers, `std::function`, `optional`, `variant` and threads.
`tests/run_cxx17test.sh` builds it and boots it in an image.

## What's in here

- `recipes/` downloads GCC and builds libstdc++, libgcc and the compatibility library.
- `os/src/cxxrt/compat/` is that compatibility library, `libphcompat`. It adds C99 math, an aligned allocator for
  WebKit, `poll()` on top of `select()`, and the POSIX and BSD calls Open C is missing.
- `os/src/cxxrt/ph_throw.cpp` logs an exception and stops the program with a clear reason. C++ exceptions don't work
  across Phorepoc OS images yet, so a crash should at least say why.
- `os/src/cxxrt/cxx17_test.cpp` is the test program, and `registry/components_cxxrt.py` registers it.

## Licensing

This is Phorepoc code, licensed under the [GNU Affero General Public License, version 3 only](LICENSE) (`AGPL-3.0-only`), with the [additional terms](ADDITIONAL-TERMS.md) its section 7 allows: keep the attribution "Phorepoc, founded by Kyriakos Bompotis" and the legal notices (also where your version shows notices, such as an About screen), and no rights to the Phorepoc names and logos ([TRADEMARKS.md](TRADEMARKS.md)). If you run a modified version for users over a network, AGPL section 13 asks you to offer them its source.

What you build with it is yours: the [Phorepoc Build Output Exception](LICENSES/Phorepoc-Build-Output-Exception-1.0.txt) lets you distribute the programs, libraries and packages you make with these tools, including the runtime pieces that end up in them, under any licence. `NOTICE` lists the runtime files it covers.

The libstdc++ and libgcc the recipes build are GPL-3.0 with the GCC Runtime Library Exception, which lets you link them into programs under any licence. `NOTICE` and `LICENSES/` have the details.

Phorepoc is dual-licensed. Commercial licences or licence exceptions (for example to ship it inside a closed product without the AGPL obligations) are available on request from the founder, Kyriakos Bompotis.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md) for the licence grant they need.
