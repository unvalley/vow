import {readFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const sharp=createRequire(path.join(root,'landing/package.json'))('sharp');
const sha=b=>createHash('sha256').update(b).digest('hex');
const base=path.join(root,'AppStore/screenshots');
const manifest=JSON.parse(await readFile(path.join(base,'manifest.json')));
// One image per frame in copy.json, for each language and each store device.
const copy=JSON.parse(await readFile(path.join(base,'copy.json')));
const frames=copy.ja.length;
if(copy.en.length!==frames)throw Error('Japanese and English need the same frames');
if(manifest.length!==frames*4)throw Error(`Expected ${frames} screenshots for each language and device`);
const catalogHash=sha(await readFile(path.join(root,'Izzy/Resources/phrases.json')));
const names=new Set();
for(const row of manifest){
 if(names.has(row.file))throw Error(`Duplicate ${row.file}`);names.add(row.file);
 if(row.catalogSHA256!==catalogHash)throw Error(`Stale capture: ${row.file}`);
 const b=await readFile(path.join(base,row.file)),m=await sharp(b).metadata();
 if(sha(b)!==row.sha256||m.width!==row.width||m.height!==row.height||m.hasAlpha)throw Error(`Invalid image ${row.file}`);
 if(sha(await readFile(path.join(base,row.sourceCapture)))!==row.sourceSHA256)throw Error(`Changed source ${row.sourceCapture}`);
 if(!['free','pro'].includes(row.access)||!row.resultBundle||!row.test)throw Error(`Missing provenance ${row.file}`);
}
for(const device of ['iPhone-6.9','iPad-13'])for(const lang of ['ja','en']){
 const rows=manifest.filter(r=>r.file.startsWith(`${device}/app-store-${lang}-`));
 if(rows.length!==frames)throw Error(`Incomplete ${device}/${lang}`);
}
// The app icon ships as an Icon Composer document; Brand holds its exported Default rendition.
// That rendition carries the icon mask, so transparency outside the mask is expected.
await readFile(path.join(root,'Izzy/Resources/Izzy.icon/icon.json'));
const b=await readFile(path.join(root,'Brand/izzy-app-icon-1024.png'));
const m=await sharp(b).metadata(),s=await sharp(b).stats();
if(m.width!==1024||m.height!==1024||s.channels.slice(0,3).some(c=>c.max-c.min<200))throw Error('Invalid or blank app icon');
console.log(`Verified ${manifest.length} current store screenshots, raw capture hashes, dimensions, access provenance, the icon document and its nonblank 1024px rendition.`);
