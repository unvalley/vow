// izzy を一文字に畳んだマークの習作。依存なしで SVG を書き出す。
//   node Brand/studies/izzy-monogram/make.mjs
// 各案は「ふくらんだ一つの塊」で、重なった線は一つの面としてまとまる。
// 立体は浅い明暗の層で近似したもので、最終の造形ではない。
import { writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const out = fileURLToPath(new URL('./', import.meta.url));
const INK = '#0B0B0C';
const bar = (d, w) => ({ d, w });
const dot = (x, y, r) => ({ d: `M ${x} ${y} L ${x} ${y + 0.01}`, w: r * 2 });

const candidates = {
  // A ひと筆：i の軸から y の尾まで、折り返す一本の帯で izzy を書く。
  fold: {
    title: 'ひと筆',
    shapes: [
      bar('M 270 360 L 760 360 L 292 562 L 764 562 L 296 764 L 742 764 L 742 826 Q 742 886 682 886 L 636 886', 150),
      dot(280, 176, 75),
    ],
  },
  // B 傾き：同じ骨格を傾け、いまのマークの斜めの流れを残す。
  tilt: {
    title: '傾き',
    rotate: -13,
    scale: 0.94,
    shapes: [
      bar('M 270 360 L 760 360 L 292 562 L 764 562 L 296 764 L 742 764 L 742 826 Q 742 886 682 886 L 636 886', 158),
      dot(280, 176, 79),
    ],
  },
  // C ならび：i と y を柱にして、間に zz の折り返しを挟み、正方形に収める。
  row: {
    title: 'ならび',
    scale: 0.93,
    shapes: [
      bar('M 196 352 L 196 676', 128),                                       // i
      dot(196, 228, 64),
      bar('M 318 352 L 648 352 L 330 514 L 660 514 L 336 676 L 666 676', 118), // zz
      bar('M 726 352 L 800 520 M 900 352 L 800 828 Q 786 884 716 872', 128),  // y
    ],
  },
  // D 2段：iz と zy を2段に積み、太らせた文字どうしを接して一塊にする。
  stack: {
    title: '2段',
    scale: 0.94,
    shapes: [
      bar('M 196 300 L 196 502', 136),                                       // i
      dot(196, 138, 66),
      bar('M 330 300 L 784 300 L 344 500 L 792 500', 136),                   // z
      bar('M 176 648 L 588 648 L 190 852 L 600 852', 136),                   // z
      bar('M 700 648 L 784 812 M 892 648 L 784 900 Q 764 948 698 936', 136), // y
    ],
  },
};

function body(id, shapes, { flat = false } = {}) {
  const w = Math.max(...shapes.map(s => s.w));
  const half = w / 2;
  const line = (fill, width, extra = '') => shapes
    .map(s => `<path d="${s.d}" fill="none" stroke="${fill}" stroke-width="${(s.w * width).toFixed(1)}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`)
    .join('');
  if (flat) return line('#FAFAF9', 1);
  return `
  <defs>
    <linearGradient id="face-${id}" gradientUnits="userSpaceOnUse" x1="180" y1="120" x2="880" y2="920">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="0.48" stop-color="#EFF0F4"/>
      <stop offset="1" stop-color="#AFB3C0"/>
    </linearGradient>
    <mask id="body-${id}"><g>${line('#FFFFFF', 1)}</g></mask>
    <filter id="soft-${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${(half * 0.2).toFixed(1)}"/></filter>
    <filter id="cast-${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${(half * 0.4).toFixed(1)}"/></filter>
  </defs>
  <g opacity="0.5" filter="url(#cast-${id})" transform="translate(${(half * 0.2).toFixed(1)} ${(half * 0.28).toFixed(1)})">${line('#000000', 1)}</g>
  <g>${line(`url(#face-${id})`, 1)}</g>
  <g mask="url(#body-${id})">
    <g transform="translate(${(half * 0.36).toFixed(1)} ${(half * 0.42).toFixed(1)})" filter="url(#soft-${id})" opacity="0.7">${line('#70768A', 1)}</g>
    <g transform="translate(${(-half * 0.2).toFixed(1)} ${(-half * 0.24).toFixed(1)})" filter="url(#soft-${id})" opacity="0.9">${line('#FFFFFF', 0.58)}</g>
  </g>`;
}

function svg(name, c, { flat = false } = {}) {
  const t = [];
  if (c.rotate) t.push(`rotate(${c.rotate} 512 512)`);
  if (c.scale) t.push(`translate(${(512 * (1 - c.scale)).toFixed(1)} ${(512 * (1 - c.scale)).toFixed(1)}) scale(${c.scale})`);
  const g = `<g${t.length ? ` transform="${t.join(' ')}"` : ''}>${body(flat ? `${name}-f` : name, c.shapes, { flat })}</g>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">`
    + `<title>izzy monogram — ${c.title}${flat ? '（単色）' : ''}</title>`
    + `<rect width="1024" height="1024" fill="${INK}"/>${g}</svg>`;
}

await mkdir(out, { recursive: true });
for (const [name, c] of Object.entries(candidates)) {
  await writeFile(path.join(out, `${name}.svg`), svg(name, c));
  await writeFile(path.join(out, `${name}-flat.svg`), svg(name, c, { flat: true }));
}
console.log(`${Object.keys(candidates).length} 案を ${out} に書き出した。`);
