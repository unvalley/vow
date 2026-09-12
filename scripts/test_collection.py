import csv
import json
import unittest

from import_collection import HEADERS, LABELS, ROOT, SOURCE, PREVIOUS_SOURCE, masked_example


class CollectionTests(unittest.TestCase):
    def test_every_source_row_keeps_its_meanings_and_example(self):
        catalog = json.loads((ROOT / 'Vow/Resources/phrases.json').read_text())
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
        catalog = json.loads((ROOT / 'Vow/Resources/phrases.json').read_text())
        original = catalog[:80]
        self.assertTrue(all(not entry.get('exampleRecall') for entry in original))
        for i, entry in enumerate(original, 1):
            self.assertEqual(entry['id'], f'{i:02d}-' + entry['phrase'].replace(' ', '-'))
        self.assertTrue(all(entry['id'] == 'collection-' + entry['phrase'].replace(' ', '-') for entry in catalog[80:]))

    def test_earlier_collection_keeps_its_contents_and_browsing_order(self):
        catalog = json.loads((ROOT / 'Vow/Resources/phrases.json').read_text())
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
