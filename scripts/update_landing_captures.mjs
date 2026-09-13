import {readFile,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const sharp=createRequire(path.join(root,'landing/package.json'))('sharp');
const captures=JSON.parse(await readFile(path.join(root,'AppStore/screenshots/captures.json')));
const mapping={'today-current':'01-today','library-current':'02-idioms','idiom-current':'03-lesson','review-current':'04-review','daily-goal':'05-goal','stats-current':'07-stats'};
const record=[];
for(const language of ['ja','en'])for(const [name,key] of Object.entries(mapping)){
 const source=captures.find(x=>x.device==='iPhone-6.9'&&x.language===language&&x.key===key);
 if(!source)throw Error(`Missing ${language} iPhone capture ${key}`);
 const raw=await readFile(path.join(root,'AppStore/screenshots',source.file));
 if(createHash('sha256').update(raw).digest('hex')!==source.sha256)throw Error(`Changed capture: ${source.file}`);
 const asset=language==='en'?`${name}-en`:name;
 for(const width of [440,660,990])await sharp(raw).resize({width}).webp({quality:82}).toFile(path.join(root,`landing/public/assets/${asset}-${width}.webp`));
 record.push({asset,language,sourceCapture:`AppStore/screenshots/${source.file}`,sourceSHA256:source.sha256,resultBundle:source.resultBundle,exampleData:key==='07-stats'});
}
await writeFile(path.join(root,'landing/capture-provenance.json'),JSON.stringify(record,null,2)+'\n');
console.log('Updated six landing screenshots in two languages at three sizes, with provenance.');
