import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
OUT = '/private/tmp/claude-501/-Users-unvalley-ghq-github-com-unvalley-vow/03b4a290-6a07-433e-805f-2b7da44721bf/scratchpad/sky/'
W, H = 2400, 1800          # render at 1.5x, save at 1600 x 1200

def fbm(seed, scales, shape=(H, W)):
    rng = np.random.default_rng(seed); out = np.zeros(shape, np.float32); tot = 0
    for sc, amp in scales:
        g = rng.random((shape[0] // sc + 3, shape[1] // sc + 3)).astype(np.float32)
        up = Image.fromarray((g * 255).astype(np.uint8)).resize(((shape[1] // sc + 3) * sc, (shape[0] // sc + 3) * sc), Image.BICUBIC)
        out += amp * (np.asarray(up, np.float32)[:shape[0], :shape[1]] / 255); tot += amp
    return out / tot

def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)

def clouds(clusters, seed, k=.03):
    """clusters: (cx, cy, rx, ry, puff, scale) in pixels; flat bases like fair-weather cumulus."""
    rng = np.random.default_rng(seed)
    E = np.zeros((H, W), np.float32)
    for cx, cy, rx, ry, count, sc in clusters:
        base = cy + ry * .55
        for _ in range(count):
            a = rng.uniform(0, 2 * np.pi); t = np.sqrt(rng.uniform(0, 1))
            x = cx + np.cos(a) * rx * t; y = cy + np.sin(a) * ry * t * .8
            r = rng.uniform(.3, 1.05) * sc * (1 - .3 * t)
            if rng.random() < .22:                      # a few towers rising from the top
                y -= rng.uniform(.2, .7) * ry; r *= rng.uniform(.5, .9)
            if y + r > base: y = base - r * rng.uniform(.2, .8)
            y0, y1 = max(0, int(y - r)), min(H, int(y + r) + 1); x0, x1 = max(0, int(x - r)), min(W, int(x + r) + 1)
            if y1 <= y0 or x1 <= x0: continue
            gy, gx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            dd = (gx - x) ** 2 + (gy - y) ** 2
            h = np.sqrt(np.clip(r * r - dd, 0, None))
            E[y0:y1, x0:x1] += np.where(dd < r * r, np.exp(k * h) - 1, 0)
        # flat bottom: nothing hangs below the cluster base
        if base < H:   # bases fade out rather than cutting off
            fade = np.clip(1 - np.linspace(0, 1, max(H - int(base), 1), dtype=np.float32) * 2.2, 0, 1)[:, None]
            E[int(base):] *= fade
    return np.log1p(E) / k

def render(p):
    Hm = clouds(p['clusters'], p['seed'])
    Hm = np.maximum(Hm + (fbm(p['seed'] + 3, ((64, .5), (28, .3), (12, .2))) - .5) * p['detail'] * smooth(0, 40, Hm), 0)
    Hs = ndimage.gaussian_filter(Hm, 6)
    gy, gx = np.gradient(Hs)
    nx, ny, nz = -gx, -gy, np.full_like(Hs, 4.0)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz); nx, ny, nz = nx / ln, ny / ln, nz / ln
    L = np.array(p['sun'], np.float32); L /= np.linalg.norm(L)
    sun = np.clip((nx * L[0] + ny * L[1] + nz * L[2]) * .55 + .45, 0, 1) ** 1.05
    occl = np.clip((ndimage.gaussian_filter(Hs, 40) - Hs) / 34, 0, 1)
    thin = 1 - smooth(0, 52, Hs)
    near = ndimage.gaussian_filter((Hm > 0).astype(np.float32), 14) > .02     # only ruffle the outline, not the open sky
    edge = (fbm(p['seed'] + 8, ((40, .5), (18, .3), (8, .2))) - .5) * p.get('edge_noise', 26) * near
    A = np.clip(ndimage.gaussian_filter(smooth(0, p.get('feather', 34), Hs + edge), 3), 0, 1)[..., None]
    lit = np.array(p['lit'], np.float32) / 255; shade = np.array(p['shade'], np.float32) / 255
    col = shade * (1 - sun[..., None]) + lit * sun[..., None]
    col = col * (1 - occl[..., None] * p.get('ao', .10))
    col = np.clip(col + np.array(p['rim'], np.float32) / 255 * (thin ** 2 * p.get('rim_strength', .38))[..., None], 0, 1)
    t = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
    bg = np.array(p['sky_top'], np.float32) / 255 * (1 - t) + np.array(p['sky_bottom'], np.float32) / 255 * t
    bg = np.broadcast_to(bg, (H, W, 3)).copy()
    img = bg * (1 - A) + col * A
    haze = smooth(.55, 1.0, np.linspace(0, 1, H, dtype=np.float32))[:, None, None]
    img = img * (1 - haze * .35) + np.array(p['sky_bottom'], np.float32) / 255 * haze * .35   # softer towards the bottom
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((1600, 1200), Image.LANCZOS)

# clusters: (cx, cy, rx, ry, puffs, puff size)
P = {
 'today-sky': dict(seed=7, detail=18, edge_noise=30, feather=44, rim_strength=.26, ao=.10, sun=(-.5, -.8, .5),
                   lit=(255, 255, 255), shade=(214, 226, 244), rim=(234, 245, 255), sky_top=(116, 172, 233), sky_bottom=(214, 235, 250),
                   clusters=[(520, 430, 330, 150, 170, 170), (1560, 300, 420, 170, 200, 190), (2130, 760, 300, 130, 140, 150),
                             (880, 900, 380, 120, 140, 130), (1800, 1180, 460, 130, 130, 120), (260, 1150, 320, 110, 100, 110)]),
 'today-sky-e': dict(seed=7, detail=18, edge_noise=30, feather=40, rim_strength=.3, sun=(-.5, -.8, .5), lit=(255, 255, 255),
                     shade=(202, 218, 240), rim=(232, 244, 255), sky_top=(116, 172, 233), sky_bottom=(214, 235, 250),
                     clusters=[(520, 430, 330, 150, 170, 170), (1560, 300, 420, 170, 200, 190), (2130, 760, 300, 130, 140, 150),
                               (880, 900, 380, 120, 140, 130), (1800, 1180, 460, 130, 130, 120), (260, 1150, 320, 110, 100, 110)]),
 'today-sky-f': dict(seed=21, detail=20, edge_noise=34, feather=48, rim_strength=.28, sun=(-.5, -.8, .5), lit=(255, 255, 255),
                     shade=(206, 220, 241), rim=(234, 245, 255), sky_top=(122, 178, 235), sky_bottom=(220, 238, 251),
                     clusters=[(680, 360, 400, 160, 190, 185), (1820, 520, 430, 165, 200, 180), (1150, 820, 340, 125, 140, 140),
                               (330, 980, 300, 115, 120, 125), (2150, 1150, 380, 120, 120, 120)]),
 'today-sky-c': dict(seed=7, detail=18, edge_noise=26, rim_strength=.4, sun=(-.5, -.8, .5), lit=(255, 255, 255),
                     shade=(198, 214, 238), rim=(232, 244, 255), sky_top=(118, 174, 234), sky_bottom=(214, 235, 250),
                     clusters=[(520, 430, 330, 150, 170, 170), (1560, 300, 420, 170, 200, 190), (2130, 760, 300, 130, 140, 150),
                               (880, 900, 380, 120, 140, 130), (1800, 1180, 460, 130, 130, 120), (260, 1150, 320, 110, 100, 110)]),
 'today-sky-d': dict(seed=21, detail=18, edge_noise=30, rim_strength=.42, sun=(-.5, -.8, .5), lit=(255, 255, 255),
                     shade=(202, 218, 240), rim=(232, 244, 255), sky_top=(124, 180, 236), sky_bottom=(220, 238, 251),
                     clusters=[(680, 360, 400, 160, 190, 185), (1820, 520, 430, 165, 200, 180), (1150, 820, 340, 125, 140, 140),
                               (330, 980, 300, 115, 120, 125), (2150, 1150, 380, 120, 120, 120)]),
 'today-sky-a': dict(seed=7, detail=10, sun=(-.5, -.8, .5), lit=(255, 255, 255), shade=(176, 200, 232), rim=(226, 240, 255),
                     sky_top=(122, 178, 236), sky_bottom=(216, 236, 250),
                     clusters=[(520, 430, 330, 150, 150, 170), (1560, 300, 420, 170, 180, 190), (2130, 760, 300, 130, 120, 150),
                               (880, 900, 380, 120, 120, 130), (1800, 1180, 460, 130, 110, 120), (260, 1150, 320, 110, 90, 110)]),
 'today-sky-b': dict(seed=11, detail=10, sun=(-.5, -.8, .5), lit=(255, 255, 255), shade=(182, 204, 234), rim=(230, 242, 255),
                     sky_top=(142, 190, 240), sky_bottom=(226, 241, 252),
                     clusters=[(700, 380, 420, 170, 190, 200), (1750, 620, 460, 180, 190, 190), (300, 880, 300, 120, 110, 130),
                               (1300, 1080, 420, 130, 120, 130), (2200, 1250, 380, 120, 100, 120)]),
}
for k in (sys.argv[1:] or P):
    render(P[k]).save(OUT + k + '.jpg', quality=90, progressive=True); print('saved', k)
