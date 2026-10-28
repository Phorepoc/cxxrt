# cxxrt

Symbian's C++ library dates from 2010, so modern C++ code can't use it. cxxrt fixes that for
[Phorepoc](https://github.com/Phorepoc). It builds GCC 13.3's libstdc++, with C++17 and C++20, on top of Symbian's
POSIX layer (Open C), and adds the POSIX functions Open C never had.

It's what lets big ports run at all. The WebKit engine in [webkit-symbian](https://github.com/Phorepoc/webkit-symbian)
links it, and so does OpenH264 in [codecpack](https://github.com/Phorepoc/codecpack).

We don't keep a copy of GCC here. The recipe downloads the release named in `gcc.lock`, checks it against its SHA-256,
and builds libstdc++ from it.

## Building

Check out core and the [pdk](https://github.com/Phorepoc/pdk) next to this repository and run `ph source export -a`
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
  across Symbian images yet, so a crash should at least say why.
- `os/src/cxxrt/cxx17_test.cpp` is the test program, and `registry/components_cxxrt.py` registers it.

## License

Our files are Apache-2.0. The libstdc++ and libgcc the recipes build are GPL-3.0 with the GCC Runtime Library
Exception, which lets you link them into programs under any license. `NOTICE` and `LICENSES/` have the details.

Contributions are welcome under the same terms. Add your name to `AUTHORS` in your first pull request.
