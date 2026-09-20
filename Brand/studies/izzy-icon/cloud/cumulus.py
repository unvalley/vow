import sys
ARGS = sys.argv[1:]; sys.argv = [sys.argv[0], '__none__']  # reuse helpers without running the old renders
exec(open('cloudword.py').read().split("P = {")[0])
from scipy import ndimage

def cumulus(p):
    rng = np.random.default_rng(p['seed'])
    m = word_mask(p.get('scale', 1.0)) > .5
    if p.get('round_r'):
        # round the letterforms before packing: opening takes the corners off,
        # closing fills the sharpest nooks, so the clouds sit on curves, not on a blocky outline
        r = p['round_r']; c = p.get('close_r', r * .6)
        grow = lambda mask, d: ndimage.distance_transform_edt(~mask) <= d
        shrink = lambda mask, d: ndimage.distance_transform_edt(mask) > d
        m = grow(shrink(m, r), r)      # opening: takes the corners off
        m = shrink(grow(m, c), c)      # closing: fills the sharpest nooks
    lab, nlab = ndimage.label(m)
    dist = ndimage.distance_transform_edt(m).astype(np.float32)
    # room around each part: distance to the nearest other part, halved
    others = {}
    for k in range(1, nlab + 1):
        others[k] = ndimage.distance_transform_edt(~((lab > 0) & (lab != k))).astype(np.float32) / 2
    H = np.zeros((N, N), np.float32); E = np.zeros((N, N), np.float32)
    yy, xx = np.nonzero(m)
    def puffs(count, rmin, rmax, near_edge=None):
        idx = rng.integers(0, len(yy), count * 3)
        placed = 0
        for i in idx:
            y, x = yy[i], xx[i]; d = dist[y, x]
            if near_edge and d > near_edge: continue
            r = float(np.clip(d * rng.uniform(1.0, 1.25), rmin, rmax)) if near_edge is None else rng.uniform(rmin, rmax)
            room = others[lab[y, x]][y, x] - p['keep_gap']
            r = min(r, room, d + p.get('bulge', 1e9))      # never reach a neighbour, never bulge far past the outline
            if r < p.get('r_skip', 6): continue            # too small to read as a lobe: leave it out
            y0, y1 = max(0, int(y - r)), min(N, int(y + r) + 1); x0, x1 = max(0, int(x - r)), min(N, int(x + r) + 1)
            gy, gx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            dd = (gx - x) ** 2 + (gy - y) ** 2
            h = np.sqrt(np.clip(r * r - dd, 0, None)) + rng.uniform(0, r * .15)
            if p.get('smooth_k'):
                E[y0:y1, x0:x1] += np.where(dd < r * r, np.exp(p['smooth_k'] * h) - 1, 0)
            else:
                H[y0:y1, x0:x1] = np.maximum(H[y0:y1, x0:x1], np.where(dd < r * r, h, 0))
            placed += 1
            if placed >= count: break
    puffs(p['big'], p['r_big'][0], p['r_big'][1])                           # bodies that fill the strokes
    puffs(p['small'], p['r_small'][0], p['r_small'][1], near_edge=p['edge_band'])   # cauliflower lobes on the outline
    if p.get('smooth_k'):
        H = np.log1p(E) / p['smooth_k']       # smooth union: overlapping puffs blend into one billow
    if p.get('detail'):
        # cauliflower grain: medium-scale noise on the surface, fading out where the cloud is thin
        det = (noise(p['seed'] + 5, p.get('detail_scales', ((40, .5), (18, .3), (8, .2)))) - .5) * p['detail']
        H = np.maximum(H + det * smooth(0, 40, H), 0)
    Hs = ndimage.gaussian_filter(H, p.get('hs', 2.0))
    gy, gx = np.gradient(Hs)
    nx, ny, nz = -gx, -gy, np.ones_like(Hs) * p['flat']
    ln = np.sqrt(nx * nx + ny * ny + nz * nz); nx, ny, nz = nx / ln, ny / ln, nz / ln
    L = np.array(p['light'], np.float32); L /= np.linalg.norm(L)
    diff = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
    # crevices between lobes (neighbours rise above this point) read as rounder when darkened
    occl = np.clip((ndimage.gaussian_filter(Hs, p.get('ao_r', 16)) - Hs) / p.get('ao_k', 22), 0, 1)
    # darker, flatter bases: shade by height inside each letter from top to bottom
    base_shadow = ndimage.gaussian_filter((H > 0).astype(np.float32), 40)
    below = np.clip(base_shadow - shift(base_shadow, 0, -60), 0, 1)
    tex = noise(p['seed'] + 3, ((48, .5), (20, .3), (8, .2)))
    light = np.clip(p['ambient'] + (1 - p['ambient']) * diff ** p['gamma'] - below * p['base'] - occl * p.get('ao', 0) + (tex - .5) * p['texture'], 0, 1)[..., None]
    lit = np.array(p['cloud'], np.float32) / 255; sh = np.array(p['shadow'], np.float32) / 255
    col = sh * (1 - light) + lit * light
    if p.get('rim'):
        # thin edges scatter sunlight through instead of going dark
        thin = 1 - smooth(0, p.get('rim_thin', 30), Hs)
        col = np.clip(col + np.array(p.get('rim_c', (214, 234, 255)), np.float32) / 255 * (thin ** 2 * p['rim'])[..., None], 0, 1)
    # soft, slightly wispy edge
    n = noise(p['seed'] + 9, ((64, .5), (24, .3), (10, .2)))
    near = ndimage.gaussian_filter((H > 0).astype(np.float32), 10) > .02
    A = smooth(0, p['feather'], Hs + (n - .5) * p['fuzz'] * near)
    A = np.clip(ndimage.gaussian_filter(A, 1.2), 0, 1)[..., None]
    bg = sky(p['sky_top'], p['sky_bottom'], p.get('glow'))
    img = bg * (1 - A) + col * A
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((1024, 1024), Image.LANCZOS)

base = dict(seed=4, keep_gap=14, big=420, r_big=(30, 78), small=1100, r_small=(12, 28), edge_band=22, flat=8.0,
            light=(-.55, -.75, .55), ambient=.36, gamma=1.1, base=.4, texture=.10, feather=18, fuzz=16,
            cloud=(255, 255, 255), shadow=(132, 158, 198), sky_top=(58, 144, 238), sky_bottom=(166, 213, 255), glow=(840, 140, 430, (255, 255, 255), .22))
V = {
 'cumulus-day': base,
 'cumulus-soft': dict(base, seed=9, small=500, r_small=(20, 40), fuzz=26, feather=26, ambient=.55, sky_top=(98, 172, 246), sky_bottom=(204, 232, 255)),
 'cumulus-dusk': dict(base, seed=4, cloud=(255, 246, 236), shadow=(196, 150, 172), sky_top=(142, 134, 250), sky_bottom=(255, 200, 184), glow=(820, 170, 460, (255, 232, 206), .35)),
 'cumulus-night': dict(base, seed=4, cloud=(214, 226, 246), shadow=(70, 90, 130), ambient=.35, sky_top=(12, 22, 46), sky_bottom=(34, 52, 90), glow=(840, 140, 380, (110, 140, 205), .22)),
}
deep = dict(base, sky_top=(18, 92, 212), sky_bottom=(70, 148, 240), glow=(840, 140, 420, (160, 205, 255), .25),
            flat=3.5, ambient=.30, gamma=1.25, base=.35, ao=.55, ao_r=16, ao_k=22, texture=.06, fuzz=6, feather=10,
            cloud=(255, 255, 255), shadow=(120, 148, 196))
V['round-a'] = dict(deep, seed=4, big=360, r_big=(40, 92), small=750, r_small=(22, 40), edge_band=26)
V['round-b'] = dict(deep, seed=6, big=300, r_big=(48, 100), small=520, r_small=(30, 54), edge_band=32)
V['round-c'] = dict(deep, seed=8, big=260, r_big=(52, 104), small=380, r_small=(38, 64), edge_band=38, sky_top=(12, 78, 196), sky_bottom=(58, 136, 234))
billow = dict(deep, smooth_k=.045, hs=5, flat=4.0, ambient=.34, gamma=1.3, ao=.30, ao_r=40, ao_k=30, fuzz=5, feather=10, base=.30)
V['billow-a'] = dict(billow, seed=4, big=240, r_big=(46, 96), small=460, r_small=(26, 44), edge_band=28)
V['billow-b'] = dict(billow, seed=12, big=200, r_big=(52, 104), small=300, r_small=(34, 58), edge_band=34)
V['billow-c'] = dict(billow, seed=12, big=200, r_big=(52, 104), small=300, r_small=(34, 58), edge_band=34, sky_top=(10, 74, 192), sky_bottom=(52, 130, 232))
V['billow2-a'] = dict(billow, seed=4, big=260, r_big=(46, 96), small=520, r_small=(26, 46), edge_band=28, bulge=20, r_skip=16)
V['billow2-b'] = dict(billow, seed=12, big=220, r_big=(52, 104), small=380, r_small=(32, 56), edge_band=32, bulge=24, r_skip=18)
night_colors = dict(cloud=(214, 226, 248), shadow=(64, 84, 128), ambient=.30, sky_top=(8, 18, 44), sky_bottom=(26, 46, 88), glow=(840, 140, 380, (100, 132, 200), .22))
V['billow2-a-night'] = dict(V['billow2-a'], **night_colors)
V['billow2-b-night'] = dict(V['billow2-b'], **night_colors)
V['final-g'] = dict(V['billow2-a'], detail=8, rim=.18, rim_thin=30)
V['final-h'] = dict(V['billow2-a'], detail=13, rim=.24, rim_thin=36, detail_scales=((30, .5), (14, .3), (6, .2)))
V['final-g-night'] = dict(V['billow2-a-night'], detail=8, rim=.14, rim_thin=30, rim_c=(120, 152, 216))
V['round1'] = dict(V['final-g'], round_r=16, close_r=4, bulge=30, r_big=(52, 100), big=210, r_small=(32, 56), small=320, edge_band=32, r_skip=22)
V['round2'] = dict(V['final-g'], round_r=24, close_r=4, bulge=38, r_big=(58, 108), big=180, r_small=(38, 66), small=260, edge_band=38, r_skip=26)
V['round2-night'] = dict(V['round2'], **dict(cloud=(214, 226, 248), shadow=(64, 84, 128), ambient=.30,
                                             sky_top=(8, 18, 44), sky_bottom=(26, 46, 88), glow=(840, 140, 380, (110, 140, 205), .22),
                                             rim=.14, rim_c=(120, 152, 216)))
for k in (ARGS or V):
    cumulus(V[k]).save(OUT + f'{k}.png'); print('saved', k)
