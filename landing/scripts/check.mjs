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
assert(en.includes('1200')&&ja.includes('1200'));
assert(en.includes('One-time purchase. No subscription.'));
const phrases=JSON.parse(await readFile(resolve(root,'../Vow/Resources/phrases.json'),'utf8'));
assert.equal(Array.isArray(phrases)?phrases.length:phrases.phrases.length,1200,'Update landing copy when catalog size changes.');
let bytes=0;
for(const path of await readdir(resolve(out,'assets'))) bytes+=(await stat(resolve(out,'assets',path))).size;
console.log(`Verified ${html.length} pages: local links, anchors, ARIA targets, and live catalog count. Assets: ${(bytes/1024).toFixed(0)} KB.`);
