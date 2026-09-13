// Deterministic brand exports from the approved outlined Archivo wordmark.
import { readFile, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(path.join(root, 'landing/package.json'));
const sharp = require('sharp');
const wordmark = await readFile(path.join(root, 'Brand/vow-wordmark.svg'), 'utf8');
const outline = wordmark.match(/ d="([^"]+)"/)[1];
const v = outline.slice(0, outline.indexOf('Z') + 1);
// The first letter's existing bounds: x 10.54...91.12, y 0...105.2.
// Uniform scale preserves the approved 85% condensed letter geometry.
const symbol = `<path fill="#FAFAF9" transform="translate(196.854 838.12) scale(6.2 -6.2)" d="${v}"/>`;
const icon = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>vow</title><rect width="1024" height="1024" fill="#202020"/>${symbol}</svg>\n`;
await writeFile(path.join(root, 'Brand/vow-icon.svg'), icon);
const png = await sharp(Buffer.from(icon)).flatten({background:'#202020'}).removeAlpha().png().toBuffer();
await writeFile(path.join(root, 'Brand/vow-icon-1024.png'), png);
await writeFile(path.join(root, 'Vow/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png'), png);
await writeFile(path.join(root, 'landing/public/assets/favicon.svg'), icon);
await sharp(png).resize(180).png().toFile(path.join(root, 'landing/public/assets/apple-touch-icon.png'));
await copyFile(path.join(root, 'Brand/vow-wordmark.svg'), path.join(root, 'landing/public/assets/wordmark.svg'));
// Sharing artwork is typography, not a simulated app screen.
const paths = wordmark.match(/<path .*\/>/s)[0];
const social = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630"><rect width="1200" height="630" fill="#FAFAF9"/><g transform="translate(80 60) scale(.7)">${paths}</g><text x="100" y="330" font-family="Helvetica,Arial,sans-serif" font-size="76" letter-spacing="-3" fill="#202020">Make English your own.</text><text x="104" y="410" font-family="Helvetica,Arial,sans-serif" font-size="27" fill="#636764">Phrasal verbs. Idioms. A little practice, every day.</text><text x="104" y="550" font-family="Helvetica,Arial,sans-serif" font-size="23" fill="#636764">vow</text></svg>`;
await writeFile(path.join(root, 'Brand/vow-social.svg'), social);
await sharp(Buffer.from(social)).removeAlpha().png().toFile(path.join(root, 'landing/public/assets/social.png'));
console.log('Brand icon, app icon, favicon, touch icon and social image exported.');
