Noto Sans Malayalam Regular, Noto Sans Tamil Regular, Noto Sans Devanagari Regular.
Source: https://github.com/notofonts/noto-fonts/tree/main/hinted/ttf
Copyright 2012 Google Inc. Licensed under the SIL Open Font License 1.1 (OFL.txt).
Original TTF files are encoded without modification in ../partner_certificate_assets.ts.

HarfBuzzJS 1.6.2 (https://github.com/harfbuzz/harfbuzzjs) is vendored under the MIT licence in HARFBUZZ-LICENSE.txt. harfbuzz-runtime.js is the unmodified Emscripten runtime; harfbuzz.mjs is the official wrapper with the import renamed and wasmBinary provided from partner_certificate_assets.ts. WASM is embedded so Supabase deployment needs no runtime file or network fetch.

Local wrapper patch: track() registers an unregister token; releaseBuffer() unregisters and destroys short-lived shaping buffers deterministically. The certificate generator calls it in finally after copying the glyph arrays. Font objects are bounded by the three-script cache.
