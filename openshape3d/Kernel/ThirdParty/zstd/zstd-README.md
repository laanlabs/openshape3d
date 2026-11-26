# Zstandard decoder (vendored)

`zstddeclib.c` is the official single-file **decoder-only** build of
[Zstandard](https://github.com/facebook/zstd) v1.5.7, generated from the
release tarball (SHA-256 verified) with

    cd build/single_file_libs
    python3 combine.py -r ../../lib -x legacy/zstd_legacy.h -o zstddeclib.c zstddeclib-in.c

`zstd.h` and `zstd_errors.h` are copied unchanged from `lib/` so Swift can see
the public API through the bridging header. No file here is modified.

Licence: BSD (see `zstd-LICENSE.txt`, copied unchanged), compatible with the
app's MIT licence. Upstream's per-file headers are kept.

Used by `BlendImporter` to open `.blend` files saved with Blender's
"Compress" option (zstd, seekable format, Blender 3.0+).

To update: regenerate `zstddeclib.c` from a newer release with the command
above and copy `lib/zstd.h`, `lib/zstd_errors.h` and `LICENSE` again.
