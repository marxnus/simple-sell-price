#!/usr/bin/env python3
"""Build a runtime-only ZIP and test the exact extracted package."""

import argparse
import hashlib
import re
from pathlib import Path
import subprocess
import tempfile
import zipfile
from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", default="lua5.1")
    parser.add_argument("--luac", default="luac5.1")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    runtime = project / "SimpleSellPrice"
    manifests = [runtime / "SimpleSellPrice.toc", runtime / "SimpleSellPrice_Camelot.toc"]
    assert manifests[0].read_bytes() == manifests[1].read_bytes(), "TOCs differ"
    toc = manifests[0].read_text()
    version = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.MULTILINE).group(1)
    for required in (
        "## Interface: 16001",
        "## Author: meinyrdi",
        "## IconTexture: Interface\\AddOns\\SimpleSellPrice\\Media\\Icon",
        "## AllowLoadGameType: camelot",
        "## SavedVariables: SimpleSellPriceDB",
    ):
        assert required in toc, required
    files = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    assert files == ["Settings.lua", "Core.lua"], "Unexpected TOC entry order"
    expected = {"SimpleSellPrice/" + path.name: path.read_bytes() for path in manifests}
    for name in files:
        path = runtime / name
        subprocess.run([args.luac, "-p", str(path)], check=True)
        expected["SimpleSellPrice/" + name] = path.read_bytes()
    expected["SimpleSellPrice/LICENSE"] = (runtime / "LICENSE").read_bytes()
    icon = runtime / "Media/Icon.tga"
    with Image.open(icon) as image:
        assert image.size == (64, 64) and image.mode == "RGBA", "Invalid runtime icon"
    assert icon.read_bytes()[2] == 2, "Runtime TGA must be uncompressed true-color"
    expected["SimpleSellPrice/Media/Icon.tga"] = icon.read_bytes()
    core = (runtime / "Core.lua").read_text()
    assert f'ns.VERSION = "{version}"' in core, "Core and TOC versions differ"
    assert 'ns.AUTHOR = "meinyrdi"' in core, "Core author differs"
    assert '2026 meinyrdi' in (runtime / "LICENSE").read_text(), "License author differs"
    actual_files = {path.relative_to(project).as_posix() for path in runtime.rglob("*") if path.is_file()}
    assert actual_files == set(expected), "Unexpected runtime file"

    dist = project / "dist"
    dist.mkdir(exist_ok=True)
    output = dist / f"SimpleSellPrice-{version}-Camelot.zip"
    with tempfile.TemporaryDirectory(prefix="simplesellprice-package-") as temp:
        archive = Path(temp) / output.name
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
            for name, content in expected.items():
                package.writestr(name, content)
        with zipfile.ZipFile(archive) as package:
            assert package.testzip() is None, "Corrupt archive"
            assert set(package.namelist()) == set(expected), "Archive contents differ"
            assert all(package.read(name) == content for name, content in expected.items()), "Archive content mismatch"
            extracted = Path(temp) / "extracted"
            package.extractall(extracted)
        subprocess.run(
            [args.lua, str(project / "tests/run.lua"), str(extracted / "SimpleSellPrice")],
            cwd=project,
            check=True,
        )
        output.write_bytes(archive.read_bytes())
    checksum = hashlib.sha256(output.read_bytes()).hexdigest()
    (dist / "SHA256SUMS").write_text(f"{checksum}  {output.name}\n")
    print(f"Verified {len(expected)} runtime files: {output}")
    print(f"SHA-256: {checksum}")


if __name__ == "__main__":
    main()
