// Deterministic brand exports for the website, from the masters in Brand/.
//
// The app icon itself is an Icon Composer document (Izzy/Resources/Izzy.icon); iOS renders its
// dark and tinted variants. `Brand/izzy-app-icon-1024.png` is that document's Default rendition,
// exported with Icon Composer's `ictool`, and the site's icons are resized from it so the browser
// tab and the Home Screen show the same mark.
import { readFile, writeFile, copyFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(path.join(root, 'landing/package.json'));
const sharp = require('sharp');
const asset = name => path.join(root, 'landing/public/assets', name);

const appIcon = path.join(root, 'Brand/izzy-app-icon-1024.png');
await sharp(appIcon).resize(180).png().toFile(asset('apple-touch-icon.png'));
await sharp(appIcon).resize(192).png().toFile(asset('favicon.png'));

// The mark on its own, for the hero: white shape, transparent elsewhere.
await sharp(path.join(root, 'Brand/izzy-mark.png')).resize(720).png().toFile(asset('mark.png'));

await copyFile(path.join(root, 'Brand/izzy-wordmark.svg'), asset('wordmark.svg'));

// Sharing artwork: the mark and the name on ink, the same pairing as the site header.
const wordmark = await readFile(path.join(root, 'Brand/izzy-wordmark.svg'), 'utf8');
const letters = wordmark.match(/<g fill="#202020"[^>]*>[\s\S]*?<\/g>/)[0].replace('#202020', '#FAFAF9');
const markData = (await readFile(path.join(root, 'Brand/izzy-mark.png'))).toString('base64');
const social = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">`
  + `<rect width="1200" height="630" fill="#111113"/>`
  + `<image href="data:image/png;base64,${markData}" x="96" y="150" width="330" height="330"/>`
  + `<g transform="translate(500 168) scale(0.20)">${letters}</g>`
  + `<text x="500" y="452" font-family="Helvetica,Arial,sans-serif" font-size="40" fill="#FAFAF9">Make English your own.</text>`
  + `<text x="500" y="508" font-family="Helvetica,Arial,sans-serif" font-size="25" fill="#9A9A98">Phrasal verbs. Idioms. A little practice, every day.</text>`
  + `</svg>`;
await writeFile(path.join(root, 'Brand/izzy-social.svg'), social);
await sharp(Buffer.from(social)).removeAlpha().png().toFile(asset('social.png'));
console.log('Favicon, touch icon, hero mark, wordmark and social image exported from Brand/.');
