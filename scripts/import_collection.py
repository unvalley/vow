"""Merge the user's CSV without renumbering existing lessons or inventing examples."""
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'scripts/data/phrasal_verbs_complete_550.csv'
PREVIOUS_SOURCE = ROOT / 'scripts/data/phrasal_verbs_list_extended.csv'
HEADERS = ['句動詞', '意味（日本語）', '意味（簡単な英英訳）', '例文']
LABELS = {
    'cut back (on)': ('cut back on', ['cut back']),
    'drop by / in': ('drop by', ['drop in']),
    'get about / around': ('get around', ['get about']),
    'hang around / about': ('hang around', ['hang about']),
    'run out (of)': ('run out of', ['run out']),
    'log off/out': ('log off', ['log out']),
}
IRREGULAR = {
    'bear': 'bore borne born', 'blow': 'blew blown', 'break': 'broke broken',
    'bring': 'brought', 'build': 'built', 'burn': 'burnt', 'burst': 'burst',
    'buy': 'bought', 'catch': 'caught', 'come': 'came', 'cut': 'cut cutting',
    'deal': 'dealt', 'do': 'did done doing does', 'draw': 'drew drawn',
    'eat': 'ate eaten', 'fall': 'fell fallen', 'feel': 'felt', 'find': 'found',
    'get': 'got gotten getting', 'give': 'gave given', 'go': 'went gone goes',
    'grow': 'grew grown', 'hang': 'hung', 'have': 'had has having',
    'hear': 'heard', 'hit': 'hit hitting', 'hold': 'held', 'keep': 'kept',
    'lay': 'laid', 'leave': 'left', 'let': 'let letting', 'make': 'made making',
    'pay': 'paid', 'put': 'put putting', 'run': 'ran running',
    'see': 'saw seen', 'sell': 'sold', 'send': 'sent', 'set': 'set setting',
    'shut': 'shut shutting', 'sit': 'sat sitting', 'sleep': 'slept',
    'speak': 'spoke spoken', 'stand': 'stood', 'stick': 'stuck',
    'take': 'took taken taking', 'tear': 'tore torn', 'tell': 'told',
    'think': 'thought', 'throw': 'threw thrown', 'wake': 'woke woken',
    'wear': 'wore worn', 'write': 'wrote written writing',
    'read': 'read', 'shake': 'shook shaken', 'show': 'showed shown',
    'sink': 'sank sunk', 'spin': 'spun spinning', 'spit': 'spat spit spitting',
    'split': 'split splitting', 'spring': 'sprang sprung', 'strike': 'struck stricken',
    'swear': 'swore sworn', 'wind': 'wound',
}


def forms(verb):
    variants = {verb, verb + 's', verb + 'ed', verb + 'ing'}
    if verb.endswith('e'):
        variants.update([verb + 'd', verb[:-1] + 'ing'])
    if verb.endswith('y') and verb[-2] not in 'aeiou':
        variants.update([verb[:-1] + 'ies', verb[:-1] + 'ied'])
    if verb.endswith(('s', 'sh', 'ch', 'x', 'z', 'o')):
        variants.add(verb + 'es')
    if len(verb) > 2 and verb[-1] not in 'aeiouwxy' and verb[-2] in 'aeiou' and verb[-3] not in 'aeiou':
        variants.update([verb + verb[-1] + 'ed', verb + verb[-1] + 'ing'])
    return variants | set(IRREGULAR.get(verb, '').split())


def masked_example(phrase, example):
    """Mask inflected verbs and particles, preserving intervening objects."""
    verb, *particles = phrase.split()
    words = list(re.finditer(r"[A-Za-z]+(?:'[A-Za-z]+)?", example))
    hidden = set()
    for start, word in enumerate(words):
        if word.group().lower() not in forms(verb):
            continue
        cursor = start + 1
        matched = [start]
        for particle in particles:
            found = next((i for i in range(cursor, min(start + 10, len(words)))
                          if (words[i].group().lower() == particle or
                              particle == 'oneself' and words[i].group().lower() in
                              {'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves', 'yourselves', 'themselves'})
                          and not re.search(r'[.!?;/]', example[words[start].end():words[i].start()])), None)
            if found is None:
                break
            matched.append(found)
            cursor = found + 1
        if len(matched) == len(particles) + 1:
            hidden.update(matched)
    if not hidden:
        raise ValueError(f'No phrase found in example: {phrase}: {example}')
    result = example
    for i in sorted(hidden, reverse=True):
        result = result[:words[i].start()] + '____' + result[words[i].end():]
    return result


def merge_collection(lessons):
    original_ids = [p['id'] for p in lessons]
    by_phrase = {p['phrase']: p for p in lessons}
    with SOURCE.open(encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != HEADERS:
            raise ValueError(f'Unexpected columns: {reader.fieldnames}')
        rows = list(reader)
    # Keep the earlier collection's browsing order; new expressions append after it.
    # The complete CSV must retain all previous rows unchanged.
    with PREVIOUS_SOURCE.open(encoding='utf-8-sig', newline='') as stream:
        previous = list(csv.DictReader(stream))
    current = {row[HEADERS[0]]: row for row in rows}
    if len(current) != len(rows):
        raise ValueError('Duplicate source labels')
    if any(current.get(row[HEADERS[0]]) != row for row in previous):
        raise ValueError('Complete collection changed or omitted an earlier row; review the merge explicitly')
    previous_labels = {row[HEADERS[0]] for row in previous}
    source_lines = {row[HEADERS[0]]: i for i, row in enumerate(rows, 2)}
    rows = previous + [row for row in rows if row[HEADERS[0]] not in previous_labels]
    seen = set()
    report = []
    for row in rows:
        number = source_lines[row[HEADERS[0]]]
        if set(row) != set(HEADERS) or any(not value or not value.strip() for value in row.values()):
            raise ValueError(f'Incomplete row {number}')
        label, japanese, english, example = [row[key].strip() for key in HEADERS]
        phrase, aliases = LABELS.get(label, (label, []))
        if phrase in seen:
            raise ValueError(f'Duplicate normalized phrase at row {number}: {phrase}')
        seen.add(phrase)
        usage = dict(japanese=japanese, easyEnglish=english, example=example)
        existing = by_phrase.get(phrase)
        if existing:
            existing['referenceUsage'] = usage
            if aliases:
                existing['aliases'] = aliases
            action = 'supplemented'
            entry = existing
        else:
            entry = dict(
                id='collection-' + phrase.replace(' ', '-'), phrase=phrase,
                meaning=english, easyEnglish=english, japanese=japanese,
                scene='everyday', cue=masked_example(phrase, example), reply=example,
                transferCue='Use the phrase in a different sentence about a real or imagined situation.',
                transferReply='', frame='', nuance='', contrast='', source='',
                exampleRecall=True, aliases=aliases,
            )
            lessons.append(entry)
            by_phrase[phrase] = entry
            action = 'added'
        report.append(dict(row=number, originalLabel=label, phrase=phrase,
                           id=entry['id'], action=action, aliases=aliases))
    assert [p['id'] for p in lessons[:len(original_ids)]] == original_ids
    assert len({p['id'] for p in lessons}) == len(lessons)
    audit = dict(source=SOURCE.name, sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                 sourceRows=len(rows), added=sum(r['action'] == 'added' for r in report),
                 supplemented=sum(r['action'] == 'supplemented' for r in report),
                 total=len(lessons), verbFamilies=len({p['phrase'].split()[0] for p in lessons}),
                 previousSource=PREVIOUS_SOURCE.name, previousRows=len(previous),
                 additionalSourceRows=len(rows) - len(previous), entries=report)
    (ROOT / 'docs/collection-import.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n')
    return lessons
