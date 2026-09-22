// Every shipped copy of the mark, derived from one artwork.
//
// `Brand/izzy-icon-artwork.png` is the artwork as delivered: the white mark, full bleed on black.
// The app icon itself is the Icon Composer document (`Izzy/Resources/Izzy.icon`), whose single Mark
// layer is that artwork with the black ground cut away; iOS draws the dark, clear and tinted icons
// from the same document. `Brand/izzy-app-icon-1024.png` is its Default rendition. Icon Composer's
// `ictool` writes that rendition on macOS; here it is composed from the artwork and a drawn
// outline, so it can be rebuilt without a Mac in the loop.
//
//   node scripts/build_icon_assets.mjs && node scripts/build_brand.mjs
import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(path.join(root, 'landing/package.json'));
const sharp = require('sharp');
const at = (...p) => path.join(root, ...p);

const SIDE = 1024;
const artwork = sharp(at('Brand/izzy-icon-artwork.png')).resize(SIDE, SIDE, { fit: 'cover', kernel: 'lanczos3' });

// The ground is black, so what the mark covers is what is bright. Alpha follows luminance and
// reaches full at the mark's darkest shading; the cast shadow below it falls away instead of
// becoming a grey halo. Colour is left as painted, as in the mark this replaces.
const FLOOR = 0.14, FULL = 0.55;
const { data, info } = await artwork.clone().removeAlpha().raw().toBuffer({ resolveWithObject: true });
const cut = Buffer.alloc(info.width * info.height * 4);
for (let p = 0; p < info.width * info.height; p++) {
  const i = p * info.channels, o = p * 4;
  const luma = (0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2]) / 255;
  cut[o] = data[i]; cut[o + 1] = data[i + 1]; cut[o + 2] = data[i + 2];
  cut[o + 3] = Math.round(255 * Math.min(1, Math.max(0, (luma - FLOOR) / (FULL - FLOOR))));
}
const layerPng = await sharp(cut, { raw: { width: info.width, height: info.height, channels: 4 } })
  .png({ compressionLevel: 9 }).toBuffer();

// The icon layer keeps the artwork's own framing, because that composition is the icon. The mark
// used on its own is trimmed and re-padded so the shape spans 76% of its frame, the presence the
// website hero, the launch screen and the widget were built around.
const SPAN = 0.76;
let [minX, minY, maxX, maxY] = [info.width, info.height, 0, 0];
for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
  if (cut[(y * info.width + x) * 4 + 3] > 8) {
    if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
  }
}
const shape = { left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 };
const scale = (SIDE * SPAN) / Math.max(shape.width, shape.height);
const drawn = { w: Math.round(shape.width * scale), h: Math.round(shape.height * scale) };
const markPng = await sharp(layerPng).extract(shape)
  .resize(drawn.w, drawn.h, { kernel: 'lanczos3' })
  .extend({
    left: Math.round((SIDE - drawn.w) / 2), right: SIDE - drawn.w - Math.round((SIDE - drawn.w) / 2),
    top: Math.round((SIDE - drawn.h) / 2), bottom: SIDE - drawn.h - Math.round((SIDE - drawn.h) / 2),
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  }).png({ compressionLevel: 9 }).toBuffer();
const resized = (side) => sharp(markPng).resize(side, side, { kernel: 'lanczos3' }).png({ compressionLevel: 9 });

// The Icon Composer layer, and the same shape on its own for the website hero.
await mkdir(at('Izzy/Resources/Izzy.icon/Assets'), { recursive: true });
await sharp(layerPng).toFile(at('Izzy/Resources/Izzy.icon/Assets/mark.png'));
await sharp(markPng).toFile(at('Brand/izzy-mark.png'));

// The Default rendition: the artwork under the icon's rounded outline. iOS masks the shipped icon
// itself, so this shape only serves the preview and the website icons resized from it. A
// superellipse (|x|^n + |y|^n = 1) with n = 4.4 stays within about two pixels of the mask ictool
// wrote at this size; it is sampled 3 x 3 per pixel so the edge keeps its antialiasing.
const N = 4.4, SAMPLES = 3, radius = SIDE / 2;
const mask = Buffer.alloc(SIDE * SIDE * 4);
for (let y = 0; y < SIDE; y++) for (let x = 0; x < SIDE; x++) {
  let covered = 0;
  for (let sy = 0; sy < SAMPLES; sy++) for (let sx = 0; sx < SAMPLES; sx++) {
    const u = Math.abs((x + (sx + 0.5) / SAMPLES - radius) / radius);
    const v = Math.abs((y + (sy + 0.5) / SAMPLES - radius) / radius);
    if (Math.pow(u, N) + Math.pow(v, N) <= 1) covered++;
  }
  const o = (y * SIDE + x) * 4;
  mask[o] = mask[o + 1] = mask[o + 2] = 255;
  mask[o + 3] = Math.round((255 * covered) / (SAMPLES * SAMPLES));
}
const maskPng = await sharp(mask, { raw: { width: SIDE, height: SIDE, channels: 4 } }).png().toBuffer();
await artwork.clone().ensureAlpha()
  .composite([{ input: maskPng, blend: 'dest-in' }])
  .png({ compressionLevel: 9 }).toFile(at('Brand/izzy-app-icon-1024.png'));

// The launch screen shows the mark at 160 points; the widget shows it at 22.
await resized(320).toFile(at('Izzy/Resources/Assets.xcassets/LaunchMark.imageset/launch-mark@2x.png'));
await resized(480).toFile(at('Izzy/Resources/Assets.xcassets/LaunchMark.imageset/launch-mark@3x.png'));
await resized(48).toFile(at('IzzyWidget/Assets.xcassets/IzzyMark.imageset/izzy-mark@2x.png'));
await resized(72).toFile(at('IzzyWidget/Assets.xcassets/IzzyMark.imageset/izzy-mark@3x.png'));

console.log('Icon layer, brand mark, 1024px rendition, launch mark and widget mark rebuilt from Brand/izzy-icon-artwork.png.');
console.log('Run `node scripts/build_brand.mjs` for the website icons, and re-export with ictool when a Mac is at hand.');
