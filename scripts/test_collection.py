import csv
import hashlib
import json
import unittest

from import_collection import HEADERS, LABELS, ROOT, SOURCE, PREVIOUS_SOURCE, masked_example

# Fields create_catalog.py adds from scripts/data at generation time, not authored in the collections.
GENERATED = {'gloss', 'nuanceJapanese', 'contrastJapanese', 'exampleTranslations'}


class CollectionTests(unittest.TestCase):
    def test_idioms_have_stable_ids_complete_contexts_and_no_collisions(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        idioms = json.loads((ROOT / 'scripts/data/idioms.json').read_text())
        self.assertEqual(len(idioms), 500)
        # The gloss is applied at generation time from glosses.json, so compare the authored fields.
        self.assertEqual([{k: v for k, v in p.items() if k not in GENERATED} for p in catalog if p.get('kind') == 'idiom'], idioms)
        self.assertEqual(len({text for entry in idioms for text in (entry['cue'], entry['transferCue'])}), 1000)
        self.assertEqual(len({text for entry in idioms for text in (entry['reply'], entry['transferReply'])}), 1000)
        phrasal = [p for p in catalog if p.get('kind') != 'idiom']
        names = {p['phrase'] for p in phrasal} | {alias for p in phrasal for alias in p.get('aliases', [])}
        for entry in idioms:
            entry_names = {entry['phrase'], *entry.get('aliases', [])}
            self.assertFalse(entry_names & names, entry['id'])
            names.update(entry_names)
            self.assertEqual(entry['kind'], 'idiom')
            self.assertEqual(entry['id'], 'idiom-' + entry['phrase'].replace(' ', '-'))
            for key in ['japanese', 'easyEnglish', 'cue', 'reply', 'transferCue', 'transferReply', 'frame', 'nuance', 'source', 'difficulty']:
                self.assertTrue(entry[key].strip(), (entry['id'], key))
            self.assertNotEqual(entry['cue'], entry['transferCue'])
            self.assertNotEqual(entry['reply'], entry['transferReply'])
            self.assertFalse(entry.get('exampleRecall', False))

    def test_editorial_lessons_append_complete_distinct_contexts(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        editorial = json.loads((ROOT / 'scripts/data/editorial-phrases.json').read_text())
        self.assertEqual(len(editorial), 256)
        self.assertEqual([{k: v for k, v in p.items() if k not in GENERATED} for p in catalog if p['id'].startswith('editorial-')], editorial)
        existing = {entry['phrase'] for entry in catalog[:614]} | {alias for entry in catalog[:614] for alias in entry.get('aliases', [])}
        self.assertFalse(existing & {entry['phrase'] for entry in editorial})
        self.assertEqual(len({entry['phrase'] for entry in catalog}), 1370)
        for entry in editorial:
            with self.subTest(phrase=entry['phrase']):
                for key in ['japanese', 'easyEnglish', 'cue', 'reply', 'transferCue', 'transferReply', 'frame', 'nuance', 'source', 'difficulty']:
                    self.assertTrue(entry[key].strip(), key)
                self.assertNotEqual(entry['cue'], entry['transferCue'])
                self.assertNotEqual(entry['reply'], entry['transferReply'])
                self.assertFalse(entry.get('exampleRecall', False))

    def test_every_lesson_has_a_short_gloss(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        glosses = json.loads((ROOT / 'scripts/data/glosses.json').read_text())
        self.assertEqual([p['id'] for p in catalog], list(glosses))
        for p in catalog:
            self.assertEqual(p['gloss'], glosses[p['id']])
            self.assertTrue(1 <= len(p['gloss'].split()) <= 3, p['id'])
            self.assertNotEqual(p['gloss'].lower(), p['phrase'].lower(), p['id'])

    def test_usage_notes_have_japanese_exactly_where_english_exists(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        notes = json.loads((ROOT / 'scripts/data/usage-notes-ja.json').read_text())
        self.assertEqual(set(notes), {p['id'] for p in catalog if p['nuance'] or p['contrast']})
        for p in catalog:
            with self.subTest(id=p['id']):
                for key in ('nuance', 'contrast'):
                    self.assertEqual(bool(p[key]), bool(p.get(key + 'Japanese')))
                    if p[key]:
                        self.assertEqual(p[key + 'Japanese'], notes[p['id']][key])
                        self.assertRegex(p[key + 'Japanese'], '[ぁ-んァ-ヶ一-龠]')

    def test_expansion_preserves_prior_lessons_and_learning_order(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        # Keep the original field/ID digest; sentence translations and glosses are additive.
        original_fields = [{k: v for k, v in p.items() if k not in GENERATED} for p in catalog[:1200]]
        digest = hashlib.sha256(json.dumps(original_fields, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
        self.assertEqual(digest, 'd550080d80ddd7c6204eb55f3ff01f958b40c0d40d373699b49fd3c7a0b5c344')
        self.assertEqual(len(catalog), 1370)
        self.assertEqual(sum(p.get('kind') == 'idiom' for p in catalog[1200:]), 50)
        order = json.loads((ROOT / 'scripts/data/catalog-order.json').read_text())
        self.assertEqual(order, [p['id'] for p in catalog])

    def test_authored_meanings_match_their_exact_source_and_generated_catalog(self):
        meanings = json.loads((ROOT / 'scripts/data/example-translations.json').read_text())
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        # Every example sentence is translated in the catalog; nothing is translated on the device.
        every = {text for phrase in catalog for text in [phrase['reply'], phrase['transferReply'], phrase.get('referenceUsage', {}).get('example', '')] if text}
        self.assertEqual(set(meanings), every)
        observed = {}
        for phrase in catalog:
            examples = [phrase['reply'], phrase['transferReply'], phrase.get('referenceUsage', {}).get('example', '')]
            expected = {s: meanings[s] for s in examples if s in meanings}
            self.assertEqual(phrase.get('exampleTranslations', {}), expected)
            observed.update(expected)
        self.assertEqual(observed, meanings)
        self.assertTrue(all(value.strip() and value != key for key, value in meanings.items()))

    def test_editorial_difficulty_covers_exact_catalog_ids(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        levels = json.loads((ROOT / 'scripts/data/phrase-difficulty.json').read_text())
        self.assertEqual(set(levels), {entry['id'] for entry in catalog})
        self.assertTrue(set(levels.values()) <= {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'})
        self.assertEqual(levels, {entry['id']: entry['difficulty'] for entry in catalog})

    def test_every_source_row_keeps_its_meanings_and_example(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        by_phrase = {entry['phrase']: entry for entry in catalog}
        with SOURCE.open(encoding='utf-8-sig', newline='') as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), 601)
        for row in rows:
            label, japanese, english, example = [row[key].strip() for key in HEADERS]
            phrase, aliases = LABELS.get(label, (label, []))
            entry = by_phrase[phrase]
            with self.subTest(phrase=phrase):
                usage = entry.get('referenceUsage', entry)
                self.assertEqual(usage['japanese'], japanese)
                self.assertEqual(usage['easyEnglish'], english)
                self.assertEqual(usage.get('example', usage.get('reply')), example)
                self.assertEqual(entry.get('aliases', []), aliases)
        self.assertEqual(len(catalog), len(by_phrase))

    def test_cloze_preserves_objects_and_handles_irregular_inflections(self):
        cases = [
            ('ask out', 'He finally asked her out.', 'He finally ____ her ____.'),
            ('have on', 'She had a beautiful red dress on.', 'She ____ a beautiful red dress ____.'),
            ('talk out of', 'I tried to talk her out of quitting her job.', 'I tried to ____ her ____ ____ quitting her job.'),
            ('wear out', 'These shoes are worn out. / That hike wore me out.', 'These shoes are ____ ____. / That hike ____ me ____.'),
            ('go with', 'That shirt goes perfectly with those pants.', 'That shirt ____ perfectly ____ those pants.'),
            ('fend for oneself', 'At 18, he had to fend for himself.', 'At 18, he had to ____ ____ ____.'),
            ('chalk up to', 'We chalked the error up to inexperience.', 'We ____ the error ____ ____ inexperience.'),
            ('spin off', 'The university spun off a new tech startup.', 'The university ____ ____ a new tech startup.'),
        ]
        for phrase, example, expected in cases:
            with self.subTest(phrase=phrase):
                self.assertEqual(masked_example(phrase, example), expected)
        with self.assertRaises(ValueError):
            masked_example('look up', 'Look at me. We need to go up.')

    def test_original_ids_still_match_their_original_order(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        original = catalog[:80]
        self.assertTrue(all(not entry.get('exampleRecall') for entry in original))
        for i, entry in enumerate(original, 1):
            self.assertEqual(entry['id'], f'{i:02d}-' + entry['phrase'].replace(' ', '-'))
        self.assertTrue(all(entry['id'] == 'collection-' + entry['phrase'].replace(' ', '-') for entry in catalog[80:614]))
        self.assertTrue(all(entry['id'] == 'editorial-' + entry['phrase'].replace(' ', '-') for entry in catalog[614:700]))

    def test_earlier_collection_keeps_its_contents_and_browsing_order(self):
        catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
        with PREVIOUS_SOURCE.open(encoding='utf-8-sig', newline='') as stream:
            previous = list(csv.DictReader(stream))
        with SOURCE.open(encoding='utf-8-sig', newline='') as stream:
            current = {row[HEADERS[0]]: row for row in csv.DictReader(stream)}
        original_names = {entry['phrase'] for entry in catalog[:80]}
        previous_import_names = []
        for row in previous:
            label = row[HEADERS[0]]
            self.assertEqual(current[label], row)
            phrase = LABELS.get(label, (label, []))[0]
            if phrase not in original_names:
                previous_import_names.append(phrase)
        self.assertEqual([entry['phrase'] for entry in catalog[80:389]], previous_import_names)


if __name__ == '__main__':
    unittest.main()
