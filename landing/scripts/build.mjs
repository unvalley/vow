import { mkdir, rm, cp, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import { copy } from '../copy.mjs';
import { downloadURL, origin } from '../site.config.mjs';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const out = resolve(root, 'dist');
if (downloadURL && !/^https:\/\/(apps\.apple\.com\/|testflight\.apple\.com\/join\/)/.test(downloadURL)) throw new Error('Use a verified public Apple download URL.');
await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });
await cp(resolve(root, 'public'), out, { recursive: true });
const esc = s => s.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');
const arrow = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 12h14m-6-6 6 6-6 6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const apple = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.7 12.7c0-2 1.6-3 1.7-3.1-1-1.5-2.5-1.7-3-1.7-1.3-.1-2.5.8-3.1.8-.7 0-1.7-.8-2.8-.7-1.4 0-2.8.9-3.5 2.1-1.5 2.6-.4 6.4 1 8.5.7 1 1.5 2 2.6 2 1 0 1.4-.6 2.8-.6s1.7.6 2.8.6c1.2 0 1.9-1 2.6-2 .8-1.1 1.1-2.2 1.1-2.3-.1 0-2.2-.9-2.2-3.6ZM14.6 6.5c.6-.7 1-1.7.9-2.7-.9 0-2 .6-2.6 1.3-.6.7-1.1 1.7-1 2.6 1 .1 2-.5 2.7-1.2Z"/></svg>';
// The capture sits in a drawn iPhone 17 body: metal edge, black bezel, Dynamic Island.
// The island lands in the gap the status bar already leaves between the clock and the icons.
const phoneImage = (name, alt, cls = '', eager = false) => `<div class="phone ${cls}"><div class="phone-screen"><img src="/assets/${name}-660.webp" srcset="/assets/${name}-440.webp 440w, /assets/${name}-660.webp 660w, /assets/${name}-990.webp 990w" sizes="(max-width: 600px) 260px, 310px" width="660" height="1434" alt="${esc(alt)}" ${eager ? 'fetchpriority="high" loading="eager"' : 'loading="lazy"'} decoding="async"></div></div>`;
function head(lang, title, description, path) {
 return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#fafaf9"><title>${esc(title)}</title><meta name="description" content="${esc(description)}"><link rel="canonical" href="${origin}${path}"><link rel="icon" href="/assets/favicon.png" type="image/png"><link rel="apple-touch-icon" href="/assets/apple-touch-icon.png"><meta property="og:type" content="website"><meta property="og:site_name" content="Izzy"><meta property="og:title" content="${esc(title)}"><meta property="og:description" content="${esc(description)}"><meta property="og:url" content="${origin}${path}"><meta property="og:image" content="${origin}/assets/social.png"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta name="twitter:card" content="summary_large_image"><link rel="stylesheet" href="/styles.css">`;
}
function page(lang) {
 const phone = (name, ...args) => phoneImage(lang === 'en' ? `${name}-en` : name, ...args);
 const t = copy[lang], home = lang === 'en' ? '/' : '/ja/';
 const action = downloadURL
  ? `<a class="button primary" href="${esc(downloadURL)}">${apple}${t.download}</a>`
  : `<span class="button primary is-waiting" role="link" aria-disabled="true">${apple}${t.download}</span>`;
 const status = downloadURL ? t.note : t.soon;
 return `${head(lang,t.title,t.description,home)}<link rel="alternate" hreflang="en" href="${origin}/"><link rel="alternate" hreflang="ja" href="${origin}/ja/"><link rel="alternate" hreflang="x-default" href="${origin}/"></head><body>
<a class="skip" href="#main">${t.skip}</a>
<header class="site-header"><nav aria-label="${lang === 'ja' ? 'メインナビゲーション' : 'Main navigation'}"><a class="brand" href="${home}" aria-label="${lang === 'ja' ? 'Izzy ホーム' : 'Izzy home'}"><img src="/assets/wordmark.svg" alt="Izzy" width="90" height="43"></a><div class="nav-links"><a href="#features">${t.nav[0]}</a><a href="#faq">${t.nav[1]}</a></div><div class="nav-actions"><a class="language" href="${t.other}" lang="${lang === 'ja' ? 'en' : 'ja'}" hreflang="${lang === 'ja' ? 'en' : 'ja'}">${lang === 'ja' ? 'EN' : 'JA'}<span class="sr-only"> · ${t.language}</span></a>${downloadURL ? `<a class="nav-cta" href="${esc(downloadURL)}">${apple}${t.download}</a>` : ''}</div></nav></header>
<main id="main">
<section class="hero" aria-labelledby="hero-title"><div class="hero-copy"><img class="hero-mark" src="/assets/mark.png" width="720" height="720" alt="" fetchpriority="high" decoding="async"><h1 id="hero-title">${t.headline}</h1><p class="hero-intro">${t.intro.replaceAll('\n','<br>')}</p><div class="hero-actions">${action}</div><p class="availability">${status}</p></div>
<div class="hero-screens">${phone('library-current',lang === 'ja' ? '450件のイディオムを一覧で探せるIzzyのPhrases画面' : 'Izzy library with 450 idioms','hero-side hero-library')}${phone('today-current',lang === 'ja' ? 'bring upと今日の学習目標を表示するIzzyのToday画面' : 'Izzy Today with bring up and the daily learning goal','hero-main',true)}${phone('idiom-current',t.features[1].alt,'hero-side hero-notes')}</div></section>
<section class="features section" id="features" aria-labelledby="features-title"><div class="section-heading"><h2 id="features-title">${t.featureTitle}</h2></div><div class="feature-grid">${t.features.map((f,i)=>`<article class="feature"><div class="feature-image feature-image-${i}">${phone(f.image,f.alt)}</div><h3>${f.title}</h3><p>${f.text}</p></article>`).join('')}</div></section>
<section class="faq section" id="faq" aria-labelledby="faq-title"><h2 id="faq-title">${t.faqTitle}</h2><div class="faq-list">${t.faqs.map(([q,a])=>`<details><summary>${q}<span class="summary-icon" aria-hidden="true">+</span></summary><p>${a}</p></details>`).join('')}</div></section>
</main><footer class="site-footer"><div class="footer-brand"><a class="brand" href="${home}"><img src="/assets/wordmark.svg" alt="Izzy" width="90" height="43"></a></div><div class="footer-links"><nav aria-label="${t.footerNavigation}"><a href="#features">${t.nav[0]}</a><a href="#faq">${t.nav[1]}</a></nav><nav aria-label="${t.footerInfo}"><a href="/support/">${t.support}</a><a href="/privacy/">${t.privacy}</a><a href="${t.other}" lang="${lang==='ja' ? 'en' : 'ja'}">${t.language}</a></nav></div><div class="footer-bottom"><a href="https://unvalley.me">${t.made} ↗</a><span>© ${new Date().getUTCFullYear()} Izzy</span></div></footer></body></html>`;
}
for (const lang of ['en','ja']) {
 const folder = lang === 'en' ? out : resolve(out,lang); await mkdir(folder,{recursive:true}); await writeFile(resolve(folder,'index.html'),page(lang));
}
// Publish the app's existing bilingual policies without changing their substance.
for (const name of ['privacy','support']) {
 const source = await readFile(resolve(root,`../AppStore/web/${name}.html`),'utf8');
 let body = source.split('<main>')[1].split('</main>')[0].replace(/<nav>[\s\S]*?<\/nav>/,'').replaceAll('href="support.html"','href="/support/"').replaceAll('href="privacy.html"','href="/privacy/"');
 if(name==='privacy') body += '<h2>This website / このウェブサイト</h2><p>This landing page uses no analytics, tracking cookies, or third-party fonts. Cloudflare hosts the website and processes network requests to deliver and protect it. / このLPはアクセス解析、トラッキングCookie、外部フォントを使用していません。ホスティングを行うCloudflareは、配信と保護のためにネットワークリクエストを処理します。</p>';
 await mkdir(resolve(out,name),{recursive:true});
 await writeFile(resolve(out,name,'index.html'),`${head('ja',`Izzy — ${name === 'privacy' ? 'Privacy' : 'Support'}`,'Izzy app help and information.',`/${name}/`)}</head><body><main class="legal"><a class="back-link" href="/">← Izzy</a>${body}<p class="legal-links"><a href="/support/">Support</a><a href="/privacy/">Privacy</a><a href="/ja/">日本語のLP</a></p></main></body></html>`);
}
await writeFile(resolve(out,'404.html'),`${head('en','Page not found — Izzy','This page could not be found.','/404.html')}<meta name="robots" content="noindex"></head><body><main class="not-found"><a href="/" class="brand"><img src="/assets/wordmark.svg" width="90" height="43" alt="Izzy"></a><p class="kicker">404</p><h1>A little lost?</h1><p>Let’s get you back to familiar words.</p><a class="button primary" href="/">Back to Izzy ${arrow}</a></main></body></html>`);
await writeFile(resolve(out,'robots.txt'),`User-agent: *\nAllow: /\nSitemap: ${origin}/sitemap.xml\n`);
await writeFile(resolve(out,'sitemap.xml'),`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${['/','/ja/','/privacy/','/support/'].map(p=>`<url><loc>${origin}${p}</loc></url>`).join('')}</urlset>`);
console.log('Built English and Japanese landing pages, privacy, support, and 404.');
