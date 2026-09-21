"""Move lessons between the phrasal-verb and idiom sources, or remove them.

This rewrites the split sources so a lesson changes kind, keeping its position in
the catalog order, or drops it entirely. Moving to phrasal restores the look-alike
comparison from `--contrast`, which takes `phrase=English|Japanese`.

    python3 scripts/reclassify_lessons.py --to-idiom "loom large" --drop "lean towards"
    python3 scripts/reclassify_lessons.py --to-phrasal "rein in" \
        --contrast "rein in=Rein in slows something down; hold back keeps it from starting.|rein in は勢いを抑える。hold back は始めさせない。"
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
    parser.add_argument('--to-phrasal', action='append', default=[])
    parser.add_argument('--drop', action='append', default=[])
    parser.add_argument('--contrast', action='append', default=[])
    args = parser.parse_args()
    contrasts = dict(pair.split('=', 1) for pair in args.contrast)

    idioms, editorial = load('idioms.json'), load('editorial-phrases.json')
    order, levels = load('catalog-order.json'), load('phrase-difficulty.json')
    glosses, translations = load('glosses.json'), load('example-translations.json')
    usage = load('usage-notes-ja.json')

    kept_idioms, promoted = [], []
    for entry in idioms:
        (promoted if entry['phrase'] in args.to_phrasal else kept_idioms).append(entry)
    absent = set(args.to_phrasal) - {e['phrase'] for e in promoted}
    if absent:
        raise SystemExit(f'not found among the idiom lessons: {sorted(absent)}')
    idioms = kept_idioms

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
    for entry in promoted:
        remap[entry['id']] = 'editorial-' + entry['phrase']
        entry['id'] = remap[entry['id']]
        entry.pop('kind', None)
        english, japanese = contrasts[entry['phrase']].split('|', 1)
        entry['contrast'] = english
        keep.append(entry)

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
    for entry in moved:
        usage[entry['id']].pop('contrast', None)
    for entry in promoted:
        usage[entry['id']]['contrast'] = contrasts[entry['phrase']].split('|', 1)[1]

    idioms.sort(key=lambda e: rank[e['id']])
    keep.sort(key=lambda e: rank[e['id']])
    dump('idioms.json', idioms)
    dump('editorial-phrases.json', keep)
    dump('catalog-order.json', order)
    for name, table in (('phrase-difficulty.json', levels), ('glosses.json', glosses),
                        ('usage-notes-ja.json', usage)):
        dump(name, {i: table[i] for i in order if i in table})
    dump('example-translations.json', translations)
    print(f'moved {len(moved)} to idioms, {len(promoted)} to phrasal verbs, '
          f'dropped {len(dropped)}; order now {len(order)}')


if __name__ == '__main__':
    main()
