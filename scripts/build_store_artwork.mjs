// Compose store presentation around unchanged simulator captures.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const sharp=createRequire(path.join(root,'landing/package.json'))('sharp');
const base=path.join(root,'AppStore/screenshots');
const copy=JSON.parse(await readFile(path.join(base,'copy.json')));
const sources=JSON.parse(await readFile(path.join(base,'captures.json')));
const mark=(await readFile(path.join(root,'Brand/vow-wordmark.svg'),'utf8')).match(/<path .*\/>/s)[0];
const sha=b=>createHash('sha256').update(b).digest('hex');
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;');
const manifest=[];
for(const source of sources){
 const c=copy[source.language].find(x=>x.key===source.key);
 if(!c)throw Error(`No copy for ${source.key}`);
 const raw=await readFile(path.join(base,source.file));
 if(sha(raw)!==source.sha256)throw Error(`Capture changed: ${source.file}`);
 const m=await sharp(raw).metadata();
 const w=m.width,h=m.height,pad=w===2064;
 if(!((w===1320&&h===2868)||(w===2064&&h===2752)))throw Error(`Unsupported dimensions ${w}x${h}`);
 const left=pad?150:98, top=pad?568:570, foot=96;
 const screen=await sharp(raw).resize({height:h-top-foot}).removeAlpha().png().toBuffer();
 const sm=await sharp(screen).metadata();
 const font=pad?108:94;
 const header=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="${w}" height="${h}" fill="#FAFAF9"/><g transform="translate(${left-20} 38) scale(.65)">${mark}</g><g font-family="Helvetica,Arial,Hiragino Sans,sans-serif" fill="#202020" font-size="${font}" letter-spacing="-3">${c.title.map((t,i)=>`<text x="${left}" y="${245+i*116}">${escape(t)}</text>`).join('')}</g><text x="${left}" y="455" font-family="Helvetica,Arial,Hiragino Sans,sans-serif" font-size="${pad?34:30}" fill="#636764">${escape(c.detail)}</text></svg>`;
 const output=await sharp(Buffer.from(header)).composite([{input:screen,left:Math.round((w-sm.width)/2),top}]).removeAlpha().png().toBuffer();
 const file=`${source.device}/app-store-${source.language}-${source.key}.png`;
 await mkdir(path.dirname(path.join(base,file)),{recursive:true});
 await writeFile(path.join(base,file),output);
 manifest.push({file,width:w,height:h,hasAlpha:false,sha256:sha(output),sourceCapture:source.file,sourceSHA256:source.sha256,resultBundle:source.resultBundle,test:source.test,access:c.access,exampleData:c.exampleData??false,catalogCount:1200,catalogSHA256:source.catalogSHA256});
}
await writeFile(path.join(base,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported ${manifest.length} store images from verified captures.`);
