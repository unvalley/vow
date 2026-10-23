"""Find a dictionary page of its own for each candidate expression.

Tries Cambridge, then Oxford Learner's, then Merriam-Webster, and keeps the first
page whose headword is the candidate itself. The headword may add object slots
(`take something for granted`), optional parts in brackets and slash alternatives,
but a search redirect to a longer or merely related entry does not count
(`take a seat` -> `take a back seat`), and neither does a hyphenated headword,
which is the adjective or noun rather than the phrase (`in-person`).

    python3 scripts/probe_candidates.py <candidates.json> <pool.json>

Candidates are a JSON list of {"phrase", ...}; other keys are carried through. The
pool gains url, headword and definitions (the page's senses, joined by ` || `), so a
lesson can be written to a sense the page lists. fill_batch_sources.py reads the
same file. Candidates with no page are printed and left out.

Read-only against the dictionaries. Requests go out one at a time with a pause, and
responses are cached under .build/dictionary-probe/, because both Cambridge and
Merriam-Webster refuse a client that asks too quickly (429 and 403).
"""
import hashlib
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / '.build/dictionary-probe'
PAUSE = 1.5
USER_AGENT = ('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
              '(KHTML, like Gecko) Version/17.0 Safari/605.1.15')
# Words a headword may add or drop without becoming a different expression.
PLACEHOLDERS = {'someone', 'something', 'somebody', 'sb', 'sth', 'your', 'my', 'his', 'her', 'their', 'our',
                "someone's", "one's", "somebody's", 'yourself', 'oneself', 'etc', 'or', 'be', 'a', 'an', 'the'}
POSSESSIVES = {'your', 'my', "someone's", "one's"}


def fetch(url):
    CACHE.mkdir(parents=True, exist_ok=True)
    key = CACHE / (hashlib.sha1(url.encode()).hexdigest() + '.json')
    if key.exists():
        return json.loads(key.read_text())
    result = {'url': url, 'status': 0, 'final': url, 'body': ''}
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': USER_AGENT, 'Accept-Language': 'en-GB,en;q=0.9'})
            with urllib.request.urlopen(request, timeout=25) as response:
                result.update(status=response.status, final=response.url,
                              body=response.read(600_000).decode('utf-8', 'replace'))
            break
        except urllib.error.HTTPError as error:
            result['status'] = error.code
            if error.code in (404, 410):
                break
            time.sleep(10 * (attempt + 1))  # 403 and 429 mean slow down, not gone
        except OSError as error:
            result['error'] = str(error)
            time.sleep(10 * (attempt + 1))
    # A refusal is not an answer about the page, so only real answers are kept.
    if result['status'] in (200, 404, 410):
        key.write_text(json.dumps(result))
    time.sleep(PAUSE)
    return result


def text(fragment):
    return ' '.join(html.unescape(re.sub(r'<[^>]+>', ' ', fragment)).split())


def words(value):
    return re.findall(r"[a-z]+(?:'[a-z]+)?", value.lower().replace('’', "'"))


def is_headword(candidate, headword):
    head = headword.lower().replace('’', "'")
    if '-' in head:
        return False
    wanted = [w for w in words(candidate) if w not in PLACEHOLDERS]
    if len(wanted) < 2:
        wanted = words(candidate)  # my pleasure, help yourself: every word has to be there
    if any(w not in words(head) for w in wanted):
        return False
    # Every required word of the headword has to be one of the candidate's.
    for token in re.sub(r'\([^)]*\)', ' ', head).split():
        alternatives = [w for w in words(token.replace('/', ' ')) if w not in PLACEHOLDERS]
        if alternatives and not any(w in wanted for w in alternatives):
            return False
    return True


def cambridge(phrase):
    tokens = phrase.lower().replace('’', "'").split()
    slugs = ['-'.join(tokens).replace("'", '-')]
    without_possessive = [t for t in tokens if t not in POSSESSIVES]
    if without_possessive != tokens:
        slugs.append('-'.join(without_possessive).replace("'", '-'))
    for slug in slugs:
        page = fetch('https://dictionary.cambridge.org/dictionary/english/' + slug)
        final = page['final']
        if page['status'] != 200 or final.rstrip('/').endswith('/dictionary/english') or 'spellcheck' in final:
            continue
        title = re.search(r'<title>(.*?)</title>', page['body'], re.S)
        if not title:
            continue
        headword = text(title.group(1)).split('|')[0].replace(' - Cambridge English Dictionary', '').strip()
        senses = []
        for sense in re.findall(r'<div class="def ddef_d db">(.*?)</div>', page['body'], re.S):
            sense = text(sense).rstrip(':').strip()
            if sense and sense not in senses:
                senses.append(sense)
        yield final.split('?')[0], headword, ' || '.join(senses[:5])


def oxford(phrase):
    slug = '-'.join(phrase.lower().replace("'", '-').split())
    page = fetch('https://www.oxfordlearnersdictionaries.com/definition/english/' + slug)
    title = re.search(r'<title>(.*?)</title>', page['body'], re.S)
    if page['status'] != 200 or not title:
        return
    headword = text(title.group(1)).split(' - ')[0]
    headword = re.sub(r'\b(phrasal verb|verb|noun|adverb|adjective|idiom|preposition|exclamation)\b', '', headword)
    headword = re.sub(r'\d+', '', headword.replace('-', ' ').replace('_', ' ')).strip()
    sense = re.search(r'<span class="def"[^>]*>(.*?)</span>\s*(?:<|$)', page['body'], re.S)
    yield page['final'], headword, text(sense.group(1)) if sense else ''


def merriam_webster(phrase):
    page = fetch('https://www.merriam-webster.com/dictionary/' + urllib.parse.quote(phrase))
    # The description names the entry the page is really about: "The meaning of WALK-AROUND is ...".
    described = re.search(r'<meta name="description" content="The meaning of (.*?) is (.*?)(?:\. How to use|")',
                          page['body'], re.S)
    if page['status'] != 200 or not described:
        return
    yield page['final'], html.unescape(described.group(1)), html.unescape(described.group(2)).lstrip('—').strip()


def probe(candidate):
    for dictionary in (cambridge, oxford, merriam_webster):
        for url, headword, definitions in dictionary(candidate['phrase']):
            if is_headword(candidate['phrase'], headword):
                return dict(candidate, url=url, headword=headword, definitions=definitions)
    return None


def main(candidates_path, pool_path):
    candidates = json.loads(Path(candidates_path).read_text())
    found, missing = [], []
    for candidate in candidates:
        result = probe(candidate)
        if result:
            found.append(result)
        else:
            missing.append(candidate['phrase'])
    Path(pool_path).write_text(json.dumps(found, ensure_ascii=False, indent=2) + '\n')
    if missing:
        print('no page of its own: ' + '; '.join(missing))
    print(f'{len(found)}/{len(candidates)} candidates have a dictionary page of their own')


if __name__ == '__main__':
    main(*sys.argv[1:3])
