// Compose the store images around unchanged simulator captures.
//
// Each frame is ink with a soft grey light behind the screen, one line of copy above it, and
// the capture itself with its corners rounded — no device frame. The background follows the
// layered-radial method in justinjay.wang/methods-for-random-gradients: several radial
// gradients from one small palette, each with its own focal point, scale, rotation and skew,
// fading to transparent over a base colour. It is seeded by the frame's key, so a rebuild
// draws the same background, and the Japanese and English images of a frame share one.
import {readFile,writeFile,mkdir,readdir,rm} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const sharp=createRequire(path.join(root,'landing/package.json'))('sharp');
const base=path.join(root,'AppStore/screenshots');
const copy=JSON.parse(await readFile(path.join(base,'copy.json')));
const sources=JSON.parse(await readFile(path.join(base,'captures.json')));
// The count comes from the shipped catalog, so an expansion cannot leave the record behind.
const catalogCount=JSON.parse(await readFile(path.join(root,'Izzy/Resources/phrases.json'))).length;
const sha=b=>createHash('sha256').update(b).digest('hex');
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;');

const INK='#0D0D0F', GLOWS=['#3A3A3F','#5C5C63','#8E8E95'], TEXT='#F4F4F2';
const DEVICES={
 // canvas, the capture's width on it, where the capture starts, the line's baseline, its cap
 'iPhone-6.9':{w:1320,h:2868,screen:1060,top:440,baseline:300,margin:72,max:88,radius:0.14},
 'iPad-13':   {w:2064,h:2752,screen:1560,top:470,baseline:330,margin:150,max:120,radius:0.035},
};
const FONTS={ja:'Hiragino Sans',en:'Helvetica Neue'};

/** Mulberry32 over a string seed: the same frame key always draws the same background. */
function rng(seedText){
 let h=1779033703^seedText.length;
 for(let i=0;i<seedText.length;i++){h=Math.imul(h^seedText.charCodeAt(i),3432918353);h=h<<13|h>>>19;}
 let a=h>>>0;
 return ()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};
}

/** Layered radial in greys on ink. The light gathers behind the screen and leaves the line on ink. */
function backdrop(w,h,seed,layers=5){
 const r=rng(seed),defs=[],rects=[];
 for(let i=0;i<layers;i++){
  const c=GLOWS[Math.floor(r()*GLOWS.length)];
  const cx=(0.15+r()*0.7).toFixed(3),cy=(0.5+r()*0.5).toFixed(3);
  const fx=(Number(cx)+(r()-0.5)*0.2).toFixed(3),fy=(Number(cy)+(r()-0.5)*0.2).toFixed(3);
  const rad=(0.3+r()*0.4).toFixed(3),rot=(r()*360).toFixed(1);
  const sx=(0.8+r()*0.9).toFixed(2),sy=(0.8+r()*0.9).toFixed(2),skew=((r()-0.5)*20).toFixed(1);
  defs.push(`<radialGradient id="l${i}" cx="${cx}" cy="${cy}" fx="${fx}" fy="${fy}" r="${rad}" gradientTransform="translate(${cx} ${cy}) rotate(${rot}) skewX(${skew}) scale(${sx} ${sy}) translate(${-cx} ${-cy})"><stop offset="0" stop-color="${c}" stop-opacity="${(0.4+r()*0.35).toFixed(2)}"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>`);
  rects.push(`<rect width="${w}" height="${h}" fill="url(#l${i})"/>`);
 }
 return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><defs>${defs.join('')}</defs><rect width="${w}" height="${h}" fill="${INK}"/>${rects.join('')}</svg>`);
}

/** Film grain around mid-grey, for a soft-light pass over the background only. */
async function grain(w,h,seed,amount=16){
 const r=rng('grain-'+seed),px=Buffer.alloc(w*h);
 for(let i=0;i<px.length;i++)px[i]=Math.max(0,Math.min(255,Math.round(128+(r()-0.5)*amount*2)));
 return sharp(px,{raw:{width:w,height:h,channels:1}}).toColourspace('srgb').png().toBuffer();
}

const line=(text,lang,size,x,y)=>`<text x="${x}" y="${y}" text-anchor="middle" font-family="${FONTS[lang]}" font-weight="700" font-size="${size}" fill="${TEXT}" letter-spacing="${lang==='ja'?-1:-2}">${escape(text)}</text>`;

/** The rendered width of one line at a size, read off the pixels rather than guessed. */
async function measure(text,lang,size){
 const w=Math.round(size*text.length*1.2)+200,h=Math.round(size*2);
 const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${line(text,lang,size,w/2,size*1.3)}</svg>`);
 const {info}=await sharp(svg).trim().toBuffer({resolveWithObject:true});
 return info.width;
}

/** One size per device and language: the largest at which every line in the set fits. */
async function fittedSize(device,lang){
 const d=DEVICES[device],available=d.w-2*d.margin;
 let size=d.max;
 for(const frame of copy[lang]){
  const width=await measure(frame.title,lang,100);
  size=Math.min(size,Math.floor(100*available/width));
 }
 return size;
}

/** The capture with the screen's rounded corners and a faint hairline, so its edge reads on ink. */
async function screen(raw,d){
 const m=await sharp(raw).metadata(),S=d.screen,H=Math.round(S*m.height/m.width),r=Math.round(S*d.radius);
 const shot=await sharp(raw).resize({width:S,height:H}).png().toBuffer();
 const mask=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${H}"><rect width="${S}" height="${H}" rx="${r}" fill="#fff"/></svg>`);
 const hairline=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${H}"><rect x="1" y="1" width="${S-2}" height="${H-2}" rx="${r-1}" fill="none" stroke="#FFFFFF" stroke-opacity=".14" stroke-width="2"/></svg>`);
 return sharp(shot).composite([{input:mask,blend:'dest-in'},{input:hairline}]).png().toBuffer();
}

const manifest=[],written=new Set();
for(const device of Object.keys(DEVICES)){
 const d=DEVICES[device];
 for(const lang of ['ja','en']){
  const size=await fittedSize(device,lang);
  for(const frame of copy[lang]){
   const source=sources.find(s=>s.device===device&&s.language===lang&&s.key===frame.capture);
   if(!source)throw Error(`No ${device} ${lang} capture ${frame.capture} for ${frame.key}`);
   const raw=await readFile(path.join(base,source.file));
   if(sha(raw)!==source.sha256)throw Error(`Capture changed: ${source.file}`);
   const bg=await sharp(backdrop(d.w,d.h,'store-'+frame.key)).png().toBuffer();
   const grained=await sharp(bg).composite([{input:await grain(d.w,d.h,frame.key),blend:'soft-light'}]).png().toBuffer();
   const text=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${d.w}" height="${d.h}">${line(frame.title,lang,size,d.w/2,d.baseline)}</svg>`);
   const shot=await screen(raw,d),sm=await sharp(shot).metadata();
   if(d.top+sm.height>d.h)throw Error(`${device}: the capture runs past the canvas`);
   const output=await sharp(grained).composite([{input:text},{input:shot,left:Math.round((d.w-sm.width)/2),top:d.top}]).removeAlpha().png().toBuffer();
   const file=`${device}/app-store-${lang}-${frame.key}.png`;
   await mkdir(path.dirname(path.join(base,file)),{recursive:true});
   await writeFile(path.join(base,file),output);
   written.add(file);
   manifest.push({file,width:d.w,height:d.h,hasAlpha:false,sha256:sha(output),sourceCapture:source.file,sourceSHA256:source.sha256,resultBundle:source.resultBundle,test:source.test,access:frame.access,exampleData:frame.exampleData??false,catalogCount,catalogSHA256:source.catalogSHA256});
  }
 }
}
// Frames that are no longer in copy.json are removed, so nothing stale sits beside the set.
for(const device of Object.keys(DEVICES)){
 for(const name of await readdir(path.join(base,device))){
  if(name.startsWith('app-store-')&&!written.has(`${device}/${name}`))await rm(path.join(base,device,name));
 }
}
await writeFile(path.join(base,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
// The gallery lists exactly what was written.
const gallery=Object.keys(DEVICES).map(device=>['ja','en'].map(lang=>`<h2>${device} · ${lang}</h2><div class="row">${copy[lang].map(f=>`<img src="${device}/app-store-${lang}-${f.key}.png" alt="${escape(f.title)}">`).join('')}</div>`).join('')).join('');
await writeFile(path.join(base,'preview.html'),`<!doctype html><html lang="en"><meta charset="utf-8"><title>Izzy — Store images</title><meta name="viewport" content="width=device-width, initial-scale=1"><style>body{margin:40px;background:#1a1a1c;color:#eee;font:14px system-ui}h2{font-weight:500;margin:32px 0 12px}.row{display:flex;gap:16px;overflow-x:auto}.row img{height:560px;border-radius:12px}</style>${gallery}</html>\n`);
console.log(`Exported ${manifest.length} store images from verified captures.`);
