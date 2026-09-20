"""Move lessons between the phrasal-verb and idiom sources, or remove them.

A verb-initial expression with no core-image particle cannot be a phrasal-verb
lesson, because the app links every one of them to a diagram. This rewrites the
split sources so such a lesson becomes an idiom, keeping its position in the
catalog order, or drops it entirely.

    python3 scripts/reclassify_lessons.py --to-idiom "loom large" --drop "lean towards"
"""
import argparse
import json
from pathlib import Path

DATA = Path(__file__).resolve().parent / 'data'


def load(name):
    return json.loads((DATA / name).read_text())


def dump(name, value):
    (DATA / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--to-idiom', action='append', default=[])
    parser.add_argument('--drop', action='append', default=[])
    args = parser.parse_args()

    idioms, editorial = load('idioms.json'), load('editorial-phrases.json')
    order, levels = load('catalog-order.json'), load('phrase-difficulty.json')
    glosses, translations = load('glosses.json'), load('example-translations.json')
    usage = load('usage-notes-ja.json')

    keep, moved, dropped = [], [], []
    for entry in editorial:
        if entry['phrase'] in args.drop:
            dropped.append(entry)
        elif entry['phrase'] in args.to_idiom:
            moved.append(entry)
        else:
            keep.append(entry)
    missing = (set(args.drop) | set(args.to_idiom)) - {e['phrase'] for e in moved + dropped}
    if missing:
        raise SystemExit(f'not found among the phrasal-verb lessons: {sorted(missing)}')

    remap = {}
    for entry in moved:
        remap[entry['id']] = 'idiom-' + entry['phrase'].replace(' ', '-')
        entry['id'] = remap[entry['id']]
        # Idioms are taught whole, so they carry no look-alike comparison.
        entry['contrast'] = ''
        entry['kind'] = 'idiom'
        entry['difficulty'] = entry.pop('difficulty')
        idioms.append(entry)

    for entry in dropped:
        for text in (entry['reply'], entry['transferReply']):
            translations.pop(text, None)

    gone = {e['id'] for e in dropped}
    order = [remap.get(i, i) for i in order if i not in gone]
    rank = {i: n for n, i in enumerate(order)}
    for table in (levels, glosses, usage):
        for old, new in remap.items():
            table[new] = table.pop(old)
        for i in gone:
            table.pop(i, None)
    for new in remap.values():
        usage[new].pop('contrast', None)

    idioms.sort(key=lambda e: rank[e['id']])
    keep.sort(key=lambda e: rank[e['id']])
    dump('idioms.json', idioms)
    dump('editorial-phrases.json', keep)
    dump('catalog-order.json', order)
    for name, table in (('phrase-difficulty.json', levels), ('glosses.json', glosses),
                        ('usage-notes-ja.json', usage)):
        dump(name, {i: table[i] for i in order if i in table})
    dump('example-translations.json', translations)
    print(f'moved {len(moved)} to idioms, dropped {len(dropped)}; order now {len(order)}')


if __name__ == '__main__':
    main()
