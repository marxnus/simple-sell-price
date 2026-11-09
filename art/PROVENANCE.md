# Artwork provenance

Original artwork created for **Simple Sell Price**, made by **meinyrdi**, on
9 November 2026. The mark combines an original numeral-one coin and a small
stack of coins, using warm gold against charcoal. No Blizzard textures,
screenshots, third-party logos, or AI-generated images are included.

The master vector is `logo.svg`. It and all rasters are generated from the same
original geometric shapes in `../tools/build_art.py`. The banner and feature
illustration use Lato from the host's system font installation (SIL Open Font
License); font binaries are not redistributed. The feature illustration is
explicitly labelled illustrative and is not a native game screenshot.

Assets are covered by this project's MIT license. Rebuild from the project root
with `python3 tools/build_art.py`; this requires Pillow and system Lato fonts at
`/usr/share/fonts/truetype/lato`. Keep the committed raster outputs when an exact
font version is unavailable.

| File | Purpose | Dimensions |
| --- | --- | --- |
| `logo.svg` | Editable master identity | 512 × 512 viewBox |
| `icon-512.png` | General project icon, RGBA | 512 × 512 |
| `curseforge-icon.png` | CurseForge project image, RGB | 400 × 400 |
| `banner.png` | Project banner | 1280 × 640 |
| `feature-preview.png` | Illustrative feature image | 1280 × 720 |
| `favicon-16.png`, `favicon-32.png`, `favicon-48.png` | Web favicons | 16, 32, 48 square |
| `favicon.ico` | Multi-resolution favicon | 16, 32, 48 square |
| `../SimpleSellPrice/Media/Icon.tga` | In-game addon/minimap icon, RGBA | 64 × 64 |

The game texture is an uncompressed truecolor 32-bit TGA (image type 2), with
dimensions and header checked by the builder. `dimensions.json` records the
generated raster sizes. Favicons and project artwork are release materials and
are not required in the installed addon.
