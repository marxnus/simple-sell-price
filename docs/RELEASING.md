# Releasing Simple Sell Price

## Verify the source

Use Python 3 with **Pillow**, and Lua 5.1. Pillow verifies the packaged TGA icon
as part of the build. On Ubuntu, install `lua5.1` and `python3-pil`. The optional
artwork generator also uses Pillow and Lato fonts; generated artwork is
committed and does not need to be rebuilt for every release.

Keep the two TOCs identical, including version, author and ordered Lua entries.
Match the release version in the package tool, install instructions and
changelog. Runtime files live only under `SimpleSellPrice/`.

Run:

```sh
python3 tools/package.py --lua lua5.1 --luac luac5.1
```

The packager validates the manifests, Lua syntax and TGA icon, builds the
installable ZIP, checks all six runtime files against source, and runs the
behavioral suite against a fresh extraction. It writes the archive and
`dist/SHA256SUMS` only after those checks pass. Do not put tests, development
artwork or release credentials in the installable ZIP.

Run the relevant [native checks](../tests/live-acceptance.md) in Forever and
record the exact `GetBuildInfo()` result. Describe only the checks actually
performed. Basic tooltip behavior was confirmed in 1.0.1; that does not imply
comprehensive combat, rendering or third-party-addon testing for later releases.

## Publish the same artifact

1. Commit the verified source and changelog. Tag the commit `v1.0.2` for the
   current release; use the corresponding version for future releases.
2. Create the matching release at
   [marxnus/simple-sell-price](https://github.com/marxnus/simple-sell-price/releases).
   Attach the verified `SimpleSellPrice-1.0.2-Camelot.zip` and `SHA256SUMS`, using
   the matching changelog entry as release notes.
3. Upload the **same ZIP** to the CurseForge project as a release for **WoW
   Forever 1.60.1**. Use [CURSEFORGE.md](../CURSEFORGE.md) for project fields,
   description and release notes. Credit the maker as **meinyrdi**.
4. Read back the repository release, attached filenames and CurseForge file
   metadata. A successful upload can still be awaiting CurseForge moderation;
   report upload and public availability separately.

The GitHub CI workflow builds and tests the package without publishing it.
Keep tokens, cookies, account data and upload responses outside the repository.

## Artwork

Use `art/curseforge-icon.png` for the project icon, `art/banner.png` for the
banner and `art/feature-preview.png` for the feature gallery. The feature image
is an **illustrative example** and must be labelled accordingly. Generation
details and original artwork licensing are recorded in
[art/PROVENANCE.md](../art/PROVENANCE.md).
