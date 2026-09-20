"""Merge an authored batch of lessons into the split catalog source files.

A batch file is a JSON list of self-contained lessons, each carrying its own
Japanese example meanings, gloss and usage note so one file can be reviewed as a
unit. This script fans those fields out into the files create_catalog.py reads
and leaves every existing entry untouched.

    python3 scripts/add_expressions.py scripts/data/batches/idioms-2026-09-21-a.json

Required per lesson: kind (idiom|phrasal), phrase, meaning, japanese, scene,
cue, reply, replyJapanese, transferCue, transferReply, transferReplyJapanese,
frame, nuance, nuanceJapanese, source, difficulty, gloss. Optional: aliases,
easyEnglish (defaults to meaning), contrast + contrastJapanese.
"""
import json
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parent / 'data'
SCENES = {'work', 'connect', 'plans', 'perspective', 'everyday'}
LEVELS = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}
REQUIRED = (
    'kind', 'phrase', 'meaning', 'japanese', 'scene', 'cue', 'reply',
    'replyJapanese', 'transferCue', 'transferReply', 'transferReplyJapanese',
    'frame', 'nuance', 'nuanceJapanese', 'source', 'difficulty', 'gloss',
)


def load(name):
    return json.loads((DATA / name).read_text())


def dump(name, value):
    (DATA / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def slug(phrase):
    # Matches create_catalog.py's stable-ID rule exactly; apostrophes are kept.
    return phrase.replace(' ', '-')


def main(paths):
    idioms = load('idioms.json')
    editorial = load('editorial-phrases.json')
    order = load('catalog-order.json')
    levels = load('phrase-difficulty.json')
    glosses = load('glosses.json')
    translations = load('example-translations.json')
    usage_ja = load('usage-notes-ja.json')

    known_ids = set(order)
    known_names = {entry['phrase'] for entry in idioms + editorial}
    known_names |= {alias for entry in idioms + editorial for alias in entry.get('aliases', [])}
    # Names outside the two authored files (the original 80 and the CSV import)
    # only exist in the generated catalog, so read them from there as well.
    generated = Path(__file__).resolve().parents[1] / 'Izzy/Resources/phrases.json'
    if generated.exists():
        for entry in json.loads(generated.read_text()):
            known_names.add(entry['phrase'])
            known_names.update(entry.get('aliases', []))

    added = 0
    for path in paths:
        batch = json.loads(Path(path).read_text())
        for lesson in batch:
            missing = [key for key in REQUIRED if not str(lesson.get(key, '')).strip()]
            if missing:
                raise ValueError(f"{lesson.get('phrase')!r} is missing {missing}")
            if lesson['kind'] not in {'idiom', 'phrasal'}:
                raise ValueError(f"{lesson['phrase']!r} has an unknown kind")
            if lesson['scene'] not in SCENES:
                raise ValueError(f"{lesson['phrase']!r} has an unknown scene")
            if lesson['difficulty'] not in LEVELS:
                raise ValueError(f"{lesson['phrase']!r} has an unknown difficulty")
            # A stray CJK character in an English field slips past every other check.
            for key in ('phrase', 'meaning', 'easyEnglish', 'cue', 'reply', 'transferCue',
                        'transferReply', 'frame', 'nuance', 'contrast', 'gloss'):
                text = lesson.get(key, '')
                stray = [ch for ch in text if '\u3000' <= ch <= '\u9fff' or '\uff00' <= ch <= '\uffef']
                if stray:
                    raise ValueError(f"{lesson['phrase']!r} has Japanese characters in {key}: {''.join(stray)!r}")
            gloss = lesson['gloss'].strip()
            if len(gloss.split()) > 3 or gloss.endswith('.') or gloss.lower() == lesson['phrase'].lower():
                raise ValueError(f"{lesson['phrase']!r} needs a one to three word gloss that is not itself")
            if bool(lesson.get('contrast', '').strip()) != bool(lesson.get('contrastJapanese', '').strip()):
                raise ValueError(f"{lesson['phrase']!r} needs both or neither of contrast and contrastJapanese")

            names = {lesson['phrase'], *lesson.get('aliases', [])}
            clash = names & known_names
            if clash:
                raise ValueError(f"{lesson['phrase']!r} collides with existing names {sorted(clash)}")
            prefix = 'idiom-' if lesson['kind'] == 'idiom' else 'editorial-'
            lesson_id = prefix + slug(lesson['phrase'])
            if lesson_id in known_ids:
                raise ValueError(f'Duplicate lesson ID {lesson_id}')

            for text, japanese in ((lesson['reply'], lesson['replyJapanese']),
                                   (lesson['transferReply'], lesson['transferReplyJapanese'])):
                if translations.get(text, japanese) != japanese:
                    raise ValueError(f'Conflicting Japanese meaning for the example {text!r}')
                translations[text] = japanese

            entry = {
                'id': lesson_id,
                'phrase': lesson['phrase'],
                'meaning': lesson['meaning'],
                'easyEnglish': lesson.get('easyEnglish') or lesson['meaning'],
                'japanese': lesson['japanese'],
                'scene': lesson['scene'],
                'cue': lesson['cue'],
                'reply': lesson['reply'],
                'transferCue': lesson['transferCue'],
                'transferReply': lesson['transferReply'],
                'frame': lesson['frame'],
                'nuance': lesson['nuance'],
                'contrast': lesson.get('contrast', ''),
                'source': lesson['source'],
            }
            if lesson.get('aliases'):
                entry['aliases'] = lesson['aliases']
            if lesson['kind'] == 'idiom':
                entry['kind'] = 'idiom'
            entry['difficulty'] = lesson['difficulty']
            (idioms if lesson['kind'] == 'idiom' else editorial).append(entry)

            order.append(lesson_id)
            levels[lesson_id] = lesson['difficulty']
            glosses[lesson_id] = gloss
            notes = {'nuance': lesson['nuanceJapanese']}
            if lesson.get('contrastJapanese', '').strip():
                notes['contrast'] = lesson['contrastJapanese']
            usage_ja[lesson_id] = notes
            known_ids.add(lesson_id)
            known_names |= names
            added += 1

    dump('idioms.json', idioms)
    dump('editorial-phrases.json', editorial)
    dump('catalog-order.json', order)
    dump('phrase-difficulty.json', levels)
    dump('glosses.json', glosses)
    dump('example-translations.json', translations)
    dump('usage-notes-ja.json', usage_ja)
    print(f'Added {added} lessons; the catalog order now holds {len(order)}')


if __name__ == '__main__':
    main(sys.argv[1:])
