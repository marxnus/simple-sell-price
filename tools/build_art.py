#!/usr/bin/env python3
"""Rebuild original Simple Sell Price artwork with Pillow and system Lato fonts."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "art"
MEDIA = ROOT / "SimpleSellPrice" / "Media"
FONTS = Path("/usr/share/fonts/truetype/lato")
INK = "#12171D"
PANEL = "#1B222A"
GOLD = "#EDC578"
CREAM = "#F4EEE1"
MUTED = "#A6ADB5"


def identity_shapes():
    """A single coin with an original numeral cutout, in front of a stack."""
    shapes = [
        ("round", (6, 6, 506, 506), "#181E25", "#3B3933", 3, 104),
        ("ellipse", (80, 371, 432, 404), "#101419", None, 0),
    ]
    for top in (277, 233, 189):
        shapes.extend([
            ("rect", (274, top, 414, top + 38), "#AD783C", None, 0),
            ("ellipse", (274, top + 17, 414, top + 59), "#B88746", "#E5B969", 5),
            ("ellipse", (274, top - 21, 414, top + 21), "#D6A453", "#F0CA80", 5),
        ])
    shapes.extend([
        ("ellipse", (99, 138, 345, 384), "#101419", None, 0),
        ("ellipse", (92, 126, 338, 372), GOLD, None, 0),
        ("ellipse", (108, 142, 322, 356), "#D6A552", "#92703E", 4),
        ("ellipse", (119, 153, 311, 345), "#DBAE5B", None, 0),
        ("polygon", ((220, 178), (181, 204), (195, 228), (213, 216),
                     (213, 292), (188, 292), (188, 319), (269, 319),
                     (269, 292), (244, 292), (244, 178)), "#272922", None, 0),
    ])
    return shapes


def logo(size=512, scale=4):
    canvas = Image.new("RGBA", (size * scale, size * scale))
    draw = ImageDraw.Draw(canvas)
    factor = size * scale / 512
    for shape in identity_shapes():
        kind, coords, fill, stroke, width, *extra = shape
        width = round(width * factor)
        if kind == "polygon":
            draw.polygon([(round(x * factor), round(y * factor)) for x, y in coords], fill=fill)
        else:
            box = tuple(round(v * factor) for v in coords)
            if kind == "round":
                draw.rounded_rectangle(box, radius=round(extra[0] * factor), fill=fill, outline=stroke, width=width)
            elif kind == "ellipse":
                draw.ellipse(box, fill=fill, outline=stroke, width=width)
            elif kind == "rect":
                draw.rectangle(box, fill=fill, outline=stroke, width=width)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def svg_master():
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-labelledby="title desc">',
             '<title id="title">Simple Sell Price</title>',
             '<desc id="desc">A warm gold coin bearing a one, in front of three stacked coins on a charcoal tile. Original artwork for meinyrdi.</desc>']
    for kind, coords, fill, stroke, width, *extra in identity_shapes():
        style = f'fill="{fill}"'
        if stroke:
            style += f' stroke="{stroke}" stroke-width="{width}"'
        if kind == "polygon":
            points = " ".join(f"{x},{y}" for x, y in coords)
            parts.append(f'<polygon points="{points}" {style}/>')
        else:
            x1, y1, x2, y2 = coords
            if kind == "ellipse":
                parts.append(f'<ellipse cx="{(x1+x2)/2:g}" cy="{(y1+y2)/2:g}" rx="{(x2-x1)/2:g}" ry="{(y2-y1)/2:g}" {style}/>')
            else:
                radius = f' rx="{extra[0]}"' if kind == "round" else ""
                parts.append(f'<rect x="{x1}" y="{y1}" width="{x2-x1}" height="{y2-y1}"{radius} {style}/>')
    parts.append('</svg>\n')
    return "\n".join(parts)


class Canvas:
    def __init__(self, width, height, scale=2):
        self.scale = scale
        self.image = Image.new("RGB", (width * scale, height * scale), INK)
        self.draw = ImageDraw.Draw(self.image)

    def font(self, size, weight="Regular"):
        return ImageFont.truetype(str(FONTS / f"Lato-{weight}.ttf"), round(size * self.scale))

    def text(self, xy, value, size, color=CREAM, weight="Regular", **kwargs):
        self.draw.text(tuple(round(v * self.scale) for v in xy), value,
                       font=self.font(size, weight), fill=color, **kwargs)

    def rect(self, box, fill, outline=None, radius=0, width=1):
        self.draw.rounded_rectangle(tuple(round(v * self.scale) for v in box),
                                    radius=round(radius * self.scale), fill=fill,
                                    outline=outline, width=round(width * self.scale))

    def line(self, coords, fill, width=1):
        self.draw.line(tuple(round(v * self.scale) for v in coords), fill=fill, width=round(width * self.scale))

    def mark(self, xy, size):
        emblem = logo(size * self.scale, scale=2)
        self.image.paste(emblem, tuple(round(v * self.scale) for v in xy), emblem)

    def save(self, path):
        self.image.resize((self.image.width // self.scale, self.image.height // self.scale),
                          Image.Resampling.LANCZOS).save(path, optimize=True)


def banner():
    c = Canvas(1280, 640)
    c.rect((0, 0, 1280, 6), GOLD)
    c.text((80, 76), "WORLD OF WARCRAFT: FOREVER", 16, GOLD, "Bold")
    c.line((80, 126, 126, 126), GOLD, 3)
    c.text((76, 160), "Simple", 80, CREAM, "Heavy")
    c.text((76, 247), "Sell Price", 80, CREAM, "Heavy")
    c.text((80, 366), "One item. One clear price.", 28, GOLD, "Semibold")
    c.text((80, 415), "Hold Shift for stacks. Show both when you want.", 22, MUTED)
    c.mark((835, 120), 365)
    c.line((80, 520, 1200, 520), "#333A40")
    c.text((80, 552), "by meinyrdi", 19, CREAM, "Semibold")
    c.text((936, 552), "SMALL. SIMPLE. STANDALONE.", 13, MUTED, "Bold")
    c.save(ART / "banner.png")


def feature_preview():
    c = Canvas(1280, 720)
    c.text((68, 50), "Your prices, at a glance.", 44, CREAM, "Heavy")
    c.text((70, 114), "The same Sell Price line, three simple ways.", 23, MUTED)
    specs = [
        (68, "DEFAULT", "Price for one item", "Sell Price: 1s 50c"),
        (460, "HOLD SHIFT", "Price for your stack", "Sell Price: 30s"),
        (852, "SHOW BOTH", "Both values together", "Sell Price: 1s 50c each / 30s stack (20)"),
    ]
    for x, mode, title, price in specs:
        c.rect((x, 214, x + 360, 512), PANEL, "#39414A", 18)
        c.rect((x + 24, 239, x + 28, 258), GOLD, radius=2)
        c.text((x + 42, 239), mode, 15, GOLD, "Bold")
        c.text((x + 24, 287), title, 23, CREAM, "Bold")
        c.line((x + 24, 336, x + 336, 336), "#39414A")
        c.text((x + 24, 366), "Silk Cloth", 24, CREAM, "Semibold")
        c.text((x + 24, 404), "Crafting Reagent", 17, "#8CC0DE")
        c.text((x + 24, 451), price, 16 if mode == "SHOW BOTH" else 21, GOLD, "Semibold")
    c.text((70, 554), "ILLUSTRATIVE EXAMPLE", 13, GOLD, "Bold")
    c.text((70, 582), "20 Silk Cloth · 1s 50c each · 30s for the stack. This is an illustration, not a game screenshot.", 18, MUTED)
    c.line((68, 638, 1212, 638), "#333A40")
    c.text((70, 660), "Simple Sell Price", 19, CREAM, "Bold")
    c.text((1059, 663), "by meinyrdi", 17, MUTED)
    c.save(ART / "feature-preview.png")


def main():
    ART.mkdir(exist_ok=True)
    MEDIA.mkdir(exist_ok=True)
    (ART / "logo.svg").write_text(svg_master())
    logo(512).save(ART / "icon-512.png", optimize=True)
    project_icon = Image.new("RGB", (400, 400), INK)
    emblem = logo(400)
    project_icon.paste(emblem, (0, 0), emblem)
    project_icon.save(ART / "curseforge-icon.png", optimize=True)
    for size in (16, 32, 48):
        logo(size).save(ART / f"favicon-{size}.png", optimize=True)
    logo(256).save(ART / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)], bitmap_format="bmp")
    logo(64).save(MEDIA / "Icon.tga", format="TGA", compression=None)
    header = (MEDIA / "Icon.tga").read_bytes()[:18]
    assert header[2] == 2 and header[16] == 32, "Game texture must be uncompressed 32-bit truecolor TGA"
    banner()
    feature_preview()
    manifest = {}
    for path in sorted([*ART.glob("*.png"), MEDIA / "Icon.tga"]):
        with Image.open(path) as image:
            manifest[str(path.relative_to(ROOT))] = {"width": image.width, "height": image.height, "mode": image.mode}
    (ART / "dimensions.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
