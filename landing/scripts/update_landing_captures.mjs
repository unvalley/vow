// Refreshes the product imagery from verified captures.
//
// Capture first, with the screenshot UI test on a 6.9-inch simulator:
//
//   xcodebuild -project Izzy.xcodeproj -scheme Izzy \
//     -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath .build/shots \
//     -parallel-testing-enabled NO -jobs 2 CODE_SIGNING_ALLOWED=NO \
//     -only-testing:IzzyUITests/BrandScreenshotsUITests/testCurrentStoreScreenshots \
//     -resultBundlePath .build/shots/Brand.xcresult test
//   xcrun xcresulttool export attachments --path .build/shots/Brand.xcresult \
//     --output-path .build/shots/attachments
//
// Then copy each `brand-<lang>-<step>` attachment to
// AppStore/screenshots/raw/iPhone-6.9/<lang>-<step>.png and run this script. It writes the three
// WebP widths the pages request and rewrites capture-provenance.json with the source hashes.
import { readFile, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import path from 'node:path';
const root = path.resolve(fileURLToPath(new URL('../', import.meta.url)));
const repo = path.resolve(root, '..');
const require = createRequire(path.join(root, 'package.json'));
const sharp = require('sharp');
const raw = path.join(repo, 'AppStore/screenshots/raw/iPhone-6.9');
const assets = path.join(root, 'public/assets');
const resultBundle = '.build/shots/Brand.xcresult';
// Each landing asset and the capture step it comes from.
const steps = {
  'today-current': '01-today',
  'library-current': '02-idioms',
  'idiom-current': '03-lesson',
  'review-current': '04-review',
  'daily-goal': '05-goal',
  'stats-current': '07-stats',
};
const widths = [440, 660, 990];
const provenance = [];
for (const [asset, step] of Object.entries(steps)) {
  for (const [language, suffix] of [['ja', ''], ['en', '-en']]) {
    const source = path.join(raw, `${language}-${step}.png`);
    const file = await readFile(source);
    for (const width of widths) {
      await sharp(file).resize({ width }).webp({ quality: 82, effort: 6 })
        .toFile(path.join(assets, `${asset}${suffix}-${width}.webp`));
    }
    provenance.push({
      asset: asset + suffix,
      language,
      sourceCapture: path.relative(repo, source),
      sourceSHA256: createHash('sha256').update(file).digest('hex'),
      resultBundle,
      // Stats runs on the app's isolated sample history, never a learner's own record.
      exampleData: asset === 'stats-current',
    });
  }
}
await writeFile(path.join(root, 'capture-provenance.json'), JSON.stringify(provenance, null, 2) + '\n');
console.log(`Wrote ${provenance.length * widths.length} WebP files and capture-provenance.json.`);
