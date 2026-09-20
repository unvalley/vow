import math, io, subprocess
import numpy as np
from PIL import Image, ImageFilter
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.misc.transform import Transform
import potrace

F = '/private/tmp/claude-501/-Users-unvalley-ghq-github-com-unvalley-vow/03b4a290-6a07-433e-805f-2b7da44721bf/scratchpad/fonts/'
_cache = {}
def font(name, **axes):
    key = (name, tuple(sorted(axes.items())))
    if key not in _cache:
        f = TTFont(F + name + '.ttf')
        if 'fvar' in f and axes:
            f = instancer.instantiateVariableFont(f, axes)
        _cache[key] = f
    return _cache[key]

def compose(f, spec):
    """spec: list of dict(ch, x, y, rot, scale) in font units (y up); returns (path d, bounds) in SVG coords (y down)."""
    gs = f.getGlyphSet(); cmap = f.getBestCmap()
    d = []; bp_all = []
    for s in spec:
        g = gs[cmap[ord(s['ch'])]]
        b = BoundsPen(gs); g.draw(b); x0, y0, x1, y1 = b.bounds
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        sc = s.get('scale', 1)
        t = (Transform().translate(s.get('x', 0), -s.get('y', 0))
             .scale(1, -1).translate(cx, cy).rotate(math.radians(s.get('rot', 0))).scale(sc).translate(-cx, -cy))
        sp = SVGPathPen(gs); g.draw(TransformPen(sp, t)); d.append(sp.getCommands())
        bb = BoundsPen(gs); g.draw(TransformPen(bb, t)); bp_all.append(bb.bounds)
    X0 = min(b[0] for b in bp_all); Y0 = min(b[1] for b in bp_all); X1 = max(b[2] for b in bp_all); Y1 = max(b[3] for b in bp_all)
    return ' '.join(d), (X0, Y0, X1, Y1)

def advance(f, ch):
    gs = f.getGlyphSet(); return gs[f.getBestCmap()[ord(ch)]].width

def glyph_bounds(f, ch):
    gs = f.getGlyphSet(); b = BoundsPen(gs); gs[f.getBestCmap()[ord(ch)]].draw(b); return b.bounds

def fit(d, bounds, fill, box=1024, occ=0.78, dx=0, dy=0, rot=0):
    X0, Y0, X1, Y1 = bounds; w, h = X1 - X0, Y1 - Y0
    s = box * occ / max(w, h)
    tx = box / 2 - s * (X0 + X1) / 2 + dx; ty = box / 2 - s * (Y0 + Y1) / 2 + dy
    tr = f'rotate({rot} {box/2} {box/2}) ' if rot else ''
    return f'<path fill="{fill}" fill-rule="nonzero" transform="{tr}translate({tx:.2f} {ty:.2f}) scale({s:.5f})" d="{d}"/>'

def svg(body, bg, box=1024):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{box}" height="{box}" viewBox="0 0 {box} {box}"><rect width="{box}" height="{box}" fill="{bg}"/>{body}</svg>\n'

def raster(svg_text, size=1024):
    p = subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size)], input=svg_text.encode(), capture_output=True, check=True)
    return Image.open(io.BytesIO(p.stdout)).convert('L')

def goo(mask_img, passes):
    """mask: L image, 255 = shape. passes: [(blur_radius, threshold 0..1)]. Blur+threshold fuses and rounds."""
    im = mask_img
    for r, t in passes:
        im = im.filter(ImageFilter.GaussianBlur(r)).point(lambda v: 255 if v >= t * 255 else 0)
    return im

def trace(mask_img, fill, box=1024):
    a = np.array(mask_img) <= 127  # potracer fills False regions
    bm = potrace.Bitmap(a)
    plist = bm.trace(turdsize=20, alphamax=1.1, opticurve=True, opttolerance=0.3)
    sc = box / a.shape[1]
    parts = []
    for curve in plist:
        sp = curve.start_point
        seg = [f'M{sp.x*sc:.1f} {sp.y*sc:.1f}']
        for s in curve.segments:
            if s.is_corner:
                seg.append(f'L{s.c.x*sc:.1f} {s.c.y*sc:.1f} L{s.end_point.x*sc:.1f} {s.end_point.y*sc:.1f}')
            else:
                seg.append(f'C{s.c1.x*sc:.1f} {s.c1.y*sc:.1f} {s.c2.x*sc:.1f} {s.c2.y*sc:.1f} {s.end_point.x*sc:.1f} {s.end_point.y*sc:.1f}')
        parts.append(' '.join(seg) + 'Z')
    return f'<path fill="{fill}" fill-rule="evenodd" d="{" ".join(parts)}"/>'
