"""Read-only source check. Keep audit output separate from the teaching copy."""
import concurrent.futures
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
phrases = json.loads((root / 'Izzy/Resources/phrases.json').read_text())
phrases = [p for p in phrases if p['source'].startswith('https://')]
selected = set(sys.argv[1:])
if selected:
    phrases = [p for p in phrases if p['phrase'] in selected]

def plain(value):
    return html.unescape(re.sub('<[^>]+>', '', value)).strip()

def check(phrase):
    try:
        request = urllib.request.Request(phrase['source'], headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(request, timeout=25) as response:
            body = response.read().decode()
            title = re.search(r'<title>(.*?)</title>', body, re.S)
            definitions = re.findall(r'<span class="def"[^>]*>(.*?)</span>', body, re.S)
            return dict(phrase=phrase['phrase'], url=phrase['source'], finalURL=response.url,
                        status=response.status, title=plain(title.group(1)) if title else '',
                        definitions=[plain(d) for d in definitions])
    except Exception as error:
        return dict(phrase=phrase['phrase'], url=phrase['source'], error=str(error))

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(check, phrases))
(root / '.build').mkdir(exist_ok=True)
cache = root / '.build/dictionary-definitions.json'
if selected and cache.exists():
    prior = {r['phrase']: r for r in json.loads(cache.read_text())}
    prior.update({r['phrase']: r for r in results})
    results = list(prior.values())
cache.write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
public = [{k: v for k, v in result.items() if k != 'definitions'} for result in results]
(root / 'docs/dictionary-links.json').write_text(json.dumps(public, ensure_ascii=False, indent=2)+'\n')
for result in results:
    print(result['phrase'], result.get('status', result.get('error')), result.get('title', ''))
print(f"{sum(r.get('status') == 200 for r in results)}/{len(results)} HTTP 200")
