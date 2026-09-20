import { readFile, readdir, stat } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const out = resolve(root,'dist');
const html = ['index.html','ja/index.html','support/index.html','privacy/index.html','404.html'];
for (const path of html) {
 const source = await readFile(resolve(out,path),'utf8');
 const ids = [...source.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
 assert.equal(ids.length,new Set(ids).size,`${path}: duplicate IDs`);
 for (const [,url] of source.matchAll(/(?:src|href)="([^"]+)"/g)) {
  if(url.startsWith('#')) assert(ids.includes(url.slice(1)),`${path}: missing anchor ${url}`);
  if(!url.startsWith('/') || url.startsWith('//')) continue;
  const local=resolve(out,'.'+url);
  const info=await stat(local).catch(()=>null);
  assert(info,`${path}: missing local asset or page ${url}`);
  if(info.isDirectory()) await stat(resolve(local,'index.html'));
 }
 for (const [,id] of source.matchAll(/aria-(?:controls|labelledby)="([^"]+)"/g)) assert(ids.includes(id),`${path}: missing ARIA target ${id}`);
}
const en=await readFile(resolve(out,'index.html'),'utf8');
const ja=await readFile(resolve(out,'ja/index.html'),'utf8');
const captures=JSON.parse(await readFile(resolve(root,'capture-provenance.json'),'utf8'));
for(const [language,source] of [['en',en],['ja',ja]]) {
 const screens=[...source.matchAll(/src="\/assets\/([^"/]+)-660\.webp"/g)];
 assert.equal(screens.length,7,`${language}: expected seven product image placements`);
 for(const [,asset] of screens) {
  assert(captures.some(c=>c.asset===asset&&c.language===language),`${language}: mismatched screenshot language ${asset}`);
  for(const width of [440,660,990]) await stat(resolve(out,`assets/${asset}-${width}.webp`));
 }
}
assert(en.includes('1,900+')&&ja.includes('1,900以上'));
assert(en.includes('One-time purchase. No subscription.'));
// The free tier and the Izzy Pro price are stated on the page, so they have to match the app.
const product=JSON.parse(await readFile(resolve(root,'../AppStore/metadata.json'),'utf8')).product;
const price=`¥${(product.launchPriceJPY??product.standardPriceJPY).toLocaleString('en-US')}`;
for(const [language,source] of [['en',en],['ja',ja]]) {
 assert(source.includes(price),`${language}: the page does not show the current price ${price}`);
 assert(source.includes(`¥${product.standardPriceJPY.toLocaleString('en-US')}`),`${language}: the page does not say where the price is going`);
 assert(source.includes(language==='ja'?'100表現':'100 expressions'),`${language}: the free tier is 100 expressions`);
}
const phrases=JSON.parse(await readFile(resolve(root,'../Izzy/Resources/phrases.json'),'utf8'));
// The pages claim a round "N+" rather than an exact number, so read the claim back
// out of the built page and check the catalog against it. The claim has to stay true
// as the catalog grows, and stay close enough that it is not badly out of date.
const catalogCount=Array.isArray(phrases)?phrases.length:phrases.phrases.length;
const claimed=Number([...en.matchAll(/([\d,]+)\+ (?:phrasal verbs|expressions)/g)][0][1].replace(/,/g,''));
assert(catalogCount>=claimed,`Landing copy claims ${claimed}+; the catalog holds only ${catalogCount}.`);
assert(catalogCount<claimed+1000,`Landing copy still claims ${claimed}+ while the catalog holds ${catalogCount}; raise the claim.`);
let bytes=0;
for(const path of await readdir(resolve(out,'assets'))) bytes+=(await stat(resolve(out,'assets',path))).size;
console.log(`Verified ${html.length} pages: local links, anchors, ARIA targets, and live catalog count. Assets: ${(bytes/1024).toFixed(0)} KB.`);
