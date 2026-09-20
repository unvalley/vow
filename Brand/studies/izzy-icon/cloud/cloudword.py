from lib import *
import json, sys, re
S = '/private/tmp/claude-501/-Users-unvalley-ghq-github-com-unvalley-vow/03b4a290-6a07-433e-805f-2b7da44721bf/scratchpad'
OUT = S + '/cloud/'
C = json.load(open(S + '/izzy/bounce-center.json'))['bounce-center-92']
WORD = ''.join(f'<path d="{c["d"]}"/>' for l in C['paths'] for c in l)
N = 2048  # work at 2x, downsample at the end

def word_mask(scale=1.0, dy=0):
    m = re.match(r'translate\(([-\d.]+) ([-\d.]+)\) scale\(([\d.]+)\)', C['transform'])
    tx, ty, s = map(float, m.groups())
    # scale about the icon centre so the cloud word can breathe a little
    tx2 = 512 - (512 - tx) * scale; ty2 = 512 - (512 - ty) * scale + dy; s2 = s * scale
    im = raster(svg(f'<g transform="translate({tx2} {ty2}) scale({s2})" fill="#fff">{WORD}</g>', '#000'), N)
    return np.asarray(im, dtype=np.float32) / 255

def blur(a, r):
    im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    return np.asarray(im, dtype=np.float32) / 255

def noise(seed, scales=((256, .45), (128, .25), (64, .15), (32, .09), (16, .06))):
    rng = np.random.default_rng(seed); out = np.zeros((N, N), np.float32)
    for sc, amp in scales:
        g = rng.random((N // sc + 3, N // sc + 3)).astype(np.float32)
        up = Image.fromarray((g * 255).astype(np.uint8)).resize(((N // sc + 3) * sc, (N // sc + 3) * sc), Image.BICUBIC)
        out += amp * (np.asarray(up, np.float32)[:N, :N] / 255)
    return out / sum(a for _, a in scales)

def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)

def shift(a, dx, dy):
    out = np.zeros_like(a)
    ys = slice(max(dy, 0), N + min(dy, 0)); yd = slice(max(-dy, 0), N + min(-dy, 0))
    xs = slice(max(dx, 0), N + min(dx, 0)); xd = slice(max(-dx, 0), N + min(-dx, 0))
    out[ys, xs] = a[yd, xd]; return out

def sky(top, bottom, glow=None):
    t = np.linspace(0, 1, N, dtype=np.float32)[:, None, None]
    top = np.array(top, np.float32) / 255; bottom = np.array(bottom, np.float32) / 255
    img = top * (1 - t) + bottom * t
    img = np.broadcast_to(img, (N, N, 3)).copy()
    if glow:
        (gx, gy, gr, gc, ga) = glow
        yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
        d = np.sqrt((xx - gx * 2) ** 2 + (yy - gy * 2) ** 2) / (gr * 2)
        g = np.exp(-d * d)[..., None] * ga
        img = img * (1 - g) + np.array(gc, np.float32) / 255 * g
    return img

def cloud_word(p):
    m = word_mask(p.get('scale', 1.0), p.get('dy', 0))
    body = blur(m, p['puff'])                               # soft field around the strokes
    n1 = noise(p['seed']); n2 = noise(p['seed'] + 7, ((96, .5), (48, .3), (24, .2)))
    field = body + (n1 - .5) * p['bump'] + (n2 - .5) * p['bump'] * .5
    D = smooth(p['edge'] - p['soft'], p['edge'] + p['soft'], field)          # cloud density / alpha
    wisp = smooth(p['edge'] - .22, p['edge'] - .02, field) * p['wisp']        # thin haze just outside
    # light from the upper left: bright tops, blue-grey undersides
    under = np.clip(D - shift(D, -int(p['light'] * .4), -p['light']), 0, 1)   # density with no cloud below it
    under = blur(under, p['light'] * .6)
    top = np.clip(D - shift(D, int(p['light'] * .3), p['light']), 0, 1)
    top = blur(top, p['light'] * .4)
    inner = blur(D, p['light'] * 1.2)                     # thick parts
    tex = noise(p['seed'] + 3, ((64, .5), (24, .3), (10, .2)))
    base = np.array(p['cloud'], np.float32) / 255
    shade = np.array(p['shadow'], np.float32) / 255
    col = np.broadcast_to(base, (N, N, 3)).copy()
    k = np.clip(under * p['under'] + (1 - inner) * .15 + (tex - .5) * p['texture'], 0, 1)[..., None]
    col = col * (1 - k) + shade * k
    col = np.clip(col + top[..., None] * .06, 0, 1)
    bg = sky(p['sky_top'], p['sky_bottom'], p.get('glow'))
    a = np.clip(D + wisp * (1 - D), 0, 1)[..., None]
    img = bg * (1 - a) + col * a
    out = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((1024, 1024), Image.LANCZOS)
    return out

P = {
 'cumulus': dict(seed=11, puff=26, bump=.34, edge=.50, soft=.06, wisp=.35, light=26, under=.85, texture=.35,
                 cloud=(250, 252, 255), shadow=(168, 190, 218), sky_top=(64, 150, 240), sky_bottom=(170, 215, 255), glow=(830, 150, 420, (255, 255, 255), .25)),
 'soft': dict(seed=5, puff=34, bump=.26, edge=.46, soft=.10, wisp=.5, light=30, under=.7, texture=.25,
              cloud=(252, 253, 255), shadow=(182, 200, 226), sky_top=(96, 170, 245), sky_bottom=(200, 230, 255), glow=(830, 150, 420, (255, 255, 255), .2)),
 'golden': dict(seed=21, puff=26, bump=.34, edge=.50, soft=.06, wisp=.35, light=26, under=.85, texture=.35,
                cloud=(255, 250, 244), shadow=(214, 170, 180), sky_top=(150, 140, 255), sky_bottom=(255, 205, 190), glow=(820, 170, 460, (255, 236, 214), .35)),
 'night': dict(seed=11, puff=26, bump=.34, edge=.50, soft=.06, wisp=.3, light=26, under=.85, texture=.35,
               cloud=(196, 212, 238), shadow=(92, 112, 150), sky_top=(14, 24, 48), sky_bottom=(36, 56, 94), glow=(830, 150, 380, (120, 150, 210), .2)),
}
for k in (sys.argv[1:] or P):
    cloud_word(P[k]).save(OUT + f'cloud-{k}.png')
    print('saved', k)
