"""Resolve the dictionary URL of every lesson in an unmerged batch file.

Reports the status and the final URL after redirects, and with --rewrite stores
the final URL back into the batch so the merged catalog records the page a
reader actually lands on. Read-only against the dictionaries.

    python3 scripts/check_batch_sources.py scripts/data/batches/<file>.json [--rewrite]
"""
import concurrent.futures
import json
import sys
import urllib.request
from pathlib import Path


def check(lesson):
    url = lesson['source']
    try:
        request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(request, timeout=25) as response:
            return dict(phrase=lesson['phrase'], url=url, finalURL=response.url, status=response.status)
    except Exception as error:
        return dict(phrase=lesson['phrase'], url=url, error=str(error))


def main(argv):
    rewrite = '--rewrite' in argv
    paths = [a for a in argv if not a.startswith('--')]
    for path in paths:
        path = Path(path)
        batch = json.loads(path.read_text())
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(check, batch))
        finals = {}
        for result in results:
            if result.get('status') == 200:
                if result['finalURL'] != result['url']:
                    print(f"  redirect {result['phrase']}: {result['finalURL']}")
                finals[result['phrase']] = result['finalURL']
            else:
                print(f"  FAILED   {result['phrase']}: {result.get('error', result.get('status'))} {result['url']}")
        if rewrite:
            for lesson in batch:
                if lesson['phrase'] in finals:
                    lesson['source'] = finals[lesson['phrase']]
            path.write_text(json.dumps(batch, ensure_ascii=False, indent=2) + '\n')
        print(f"{path.name}: {len(finals)}/{len(batch)} HTTP 200")


if __name__ == '__main__':
    main(sys.argv[1:])
