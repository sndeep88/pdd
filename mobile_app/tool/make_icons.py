"""Generate launcher icon + splash assets from the website favicon source."""
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT.parent / "assets" / "images" / "favicon-1024-source.png"
OUT = ROOT / "assets" / "images"
OUT.mkdir(parents=True, exist_ok=True)

GOLD = (236, 180, 52)
BG_A = (0, 58, 30)
BG_B = (0, 132, 66)

src = Image.open(SRC).convert("RGBA")
W, H = src.size

# 1) Extract the shamrock (gold pixels inside the frame, ignoring the border).
mx, my = int(W * 0.14), int(H * 0.14)
px = src.load()
fg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
fp = fg.load()
for y in range(my, H - my):
    for x in range(mx, W - mx):
        r, g, b, a = px[x, y]
        alpha = max(0.0, min(1.0, (r - 70) / 80.0))
        if alpha <= 0.0 or a < 10:
            continue
        if alpha < 0.95:
            r, g, b = GOLD
        fp[x, y] = (r, g, b, int(alpha * 255))

bbox = fg.getbbox()
shamrock = fg.crop(bbox)
sw, sh = shamrock.size


def gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    p = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2.0 * (size - 1))
            p[x, y] = tuple(int(BG_A[i] + (BG_B[i] - BG_A[i]) * t) for i in range(3))
    return img


def place(canvas: Image.Image, width_ratio: float) -> Image.Image:
    size = canvas.size[0]
    target_w = int(size * width_ratio)
    target_h = int(sh * target_w / sw)
    s = shamrock.resize((target_w, target_h), Image.LANCZOS)
    canvas.alpha_composite(s, ((size - target_w) // 2, (size - target_h) // 2))
    return canvas


# Shamrock only (transparent) - used in-app on splash + native splash.
splash = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
place(splash, 0.9).save(OUT / "shamrock.png")

# Adaptive icon foreground (keep inside the 66dp safe zone of 108dp).
adaptive_fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
place(adaptive_fg, 0.46).save(OUT / "icon_foreground.png")

# Adaptive icon background (plain gradient).
gradient(1024).save(OUT / "icon_background.png")

# Full icon (iOS + legacy Android): gradient + shamrock + soft gold glow.
base = gradient(1024).convert("RGBA")
glow = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
place(glow, 0.58)
glow = glow.filter(ImageFilter.GaussianBlur(28))
glow.putalpha(glow.getchannel("A").point(lambda v: int(v * 0.35)))
base.alpha_composite(glow)
place(base, 0.52)
base.convert("RGB").save(OUT / "app_icon.png")

print("shamrock bbox", bbox, "->", sw, sh)
print("written to", OUT)
