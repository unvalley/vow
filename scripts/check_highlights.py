"""Mirror PhraseHighlight so an unmerged batch can be checked without a build.

Every teaching example has to contain its own expression, or one of its aliases,
in a form the app can highlight. Idioms match without gaps; phrasal verbs may
have an object between the verb and the particle.

    python3 scripts/check_highlights.py scripts/data/batches/<file>.json
    python3 scripts/check_highlights.py --catalog
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORDS = re.compile(r"[^\W\d_]+(?:['’][^\W\d_]+)?", re.UNICODE)
BOUNDARIES = set(".!?;:/,\n\r—")
REFLEXIVES = {'oneself', 'myself', 'yourself', 'himself', 'herself', 'itself',
              'ourselves', 'yourselves', 'themselves'}
IRREGULAR = json.loads((Path(__file__).resolve().parent / 'data/irregular-verbs.json').read_text())


def forms(verb):
    variants = {verb, verb + 's', verb + 'ed', verb + 'ing'}
    if verb.endswith('e'):
        variants |= {verb + 'd', verb[:-1] + 'ing'}
    if verb.endswith('ie'):
        variants.add(verb[:-2] + 'ying')
    if len(verb) > 1 and verb[-1] == 'y' and verb[-2] not in 'aeiou':
        variants |= {verb[:-1] + 'ies', verb[:-1] + 'ied'}
    if any(verb.endswith(tail) for tail in ('s', 'sh', 'ch', 'x', 'z', 'o')):
        variants.add(verb + 'es')
    if len(verb) > 2 and verb[-1] not in 'aeiouwxy' and verb[-2] in 'aeiou' and verb[-3] not in 'aeiou':
        variants |= {verb + verb[-1] + 'ed', verb + verb[-1] + 'ing'}
    variants |= set(IRREGULAR.get(verb, []))
    return variants


def matches(text, expressions, allows_gaps):
    tokens = [(m.group(0).lower(), m.start(), m.end()) for m in WORDS.finditer(text)]
    for expression in expressions:
        parts = [m.group(0).lower() for m in WORDS.finditer(expression)]
        if len(parts) < 2:
            continue
        variants = forms(parts[0])
        for start in range(len(tokens)):
            if tokens[start][0] not in variants:
                continue
            cursor = start + 1
            found_all = True
            for particle in parts[1:]:
                found = None
                while cursor < min(start + 10, len(tokens)):
                    between = text[tokens[start][2]:tokens[cursor][1]]
                    if any(ch in BOUNDARIES for ch in between):
                        break
                    word = tokens[cursor][0]
                    if word == particle or (particle == 'oneself' and word in REFLEXIVES):
                        found = cursor
                        cursor += 1
                        break
                    if not allows_gaps or word in variants:
                        break
                    cursor += 1
                if found is None:
                    found_all = False
                    break
            if found_all:
                return True
    return False


def check(lessons, is_idiom):
    problems = []
    for lesson in lessons:
        expressions = [lesson['phrase'], *lesson.get('aliases', [])]
        gaps = not is_idiom(lesson)
        for key in ('reply', 'transferReply'):
            # Imported CSV lessons teach with a single example and leave the second blank.
            if not lesson.get(key, '').strip():
                continue
            if not matches(lesson[key], expressions, gaps):
                problems.append(f"{lesson['phrase']}: {key} does not contain a highlightable form -> {lesson[key]!r}")
    return problems


def main(argv):
    problems = []
    total = 0
    if '--catalog' in argv:
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        total = len(catalog)
        problems += check(catalog, lambda lesson: lesson.get('kind') == 'idiom')
    for path in (a for a in argv if not a.startswith('--')):
        batch = json.loads(Path(path).read_text())
        total += len(batch)
        problems += check(batch, lambda lesson: lesson['kind'] == 'idiom')
    for problem in problems:
        print('  ' + problem)
    print(f'{total - len(problems)}/{total} lessons highlight in both examples')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
