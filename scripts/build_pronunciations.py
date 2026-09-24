"""Write an American IPA transcription for every catalog phrase.

Words come from the CMU Pronouncing Dictionary (BSD-style licence), pinned to one
commit and cached under .build/. pronunciation-overrides.json supplies words the
dictionary lacks, the reading to use where a word has several (live, close, wind),
and whole transcriptions for phrases the rules cannot spell.

    python3 scripts/build_pronunciations.py

Conventions, so the output reads like a learner's dictionary:
- Stress marks only inside words of two or more syllables. A compound's last
  primary stress wins; a secondary stress is kept only when a syllable separates
  it from the primary (ˌdɪsəˈpruːv, but dɪˈsaɪd).
- Function words take their weak form (a → ə, to → tə, for → fɚ) unless they end
  the phrase, where they are stressed (look forward to → tuː).
- The someone / something placeholders carry no stress mark.
"""
import json
import re
import urllib.request
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'scripts/data'
CMUDICT_COMMIT = '74790861f652b15e4ac49015a90074ad62a27690'
CMUDICT_URL = f'https://raw.githubusercontent.com/cmusphinx/cmudict/{CMUDICT_COMMIT}/cmudict.dict'
CACHE = ROOT / f'.build/cmudict/{CMUDICT_COMMIT}.dict'

WEAK = {
    'a': 'AH0', 'an': 'AH0 N', 'and': 'AH0 N D', 'as': 'AH0 Z', 'at': 'AH0 T',
    'can': 'K AH0 N', 'for': 'F ER0', 'from': 'F R AH0 M', 'of': 'AH0 V',
    'than': 'DH AH0 N', 'the': 'DH AH0', 'to': 'T AH0',
}
UNSTRESSED = {'someone', "someone's", 'something', 'somebody', "somebody's", "one's"}
VOWELS = {
    'AA': 'ɑː', 'AE': 'æ', 'AO': 'ɔː', 'AW': 'aʊ', 'AY': 'aɪ', 'EH': 'e', 'EY': 'eɪ',
    'IH': 'ɪ', 'OW': 'oʊ', 'OY': 'ɔɪ', 'UH': 'ʊ',
}
CONSONANTS = {
    'B': 'b', 'CH': 'tʃ', 'D': 'd', 'DH': 'ð', 'F': 'f', 'G': 'ɡ', 'HH': 'h', 'JH': 'dʒ',
    'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'NG': 'ŋ', 'P': 'p', 'R': 'r', 'S': 's',
    'SH': 'ʃ', 'T': 't', 'TH': 'θ', 'V': 'v', 'W': 'w', 'Y': 'j', 'Z': 'z', 'ZH': 'ʒ',
}
# Onsets English allows at the start of a syllable; the stress mark goes before the longest one.
ONSETS = {tuple(o.split()) for o in [
    'P R', 'P L', 'B R', 'B L', 'T R', 'D R', 'K R', 'K L', 'G R', 'G L', 'F R', 'F L', 'TH R', 'SH R',
    'S P', 'S T', 'S K', 'S M', 'S N', 'S L', 'S W', 'S P R', 'S P L', 'S T R', 'S K R', 'S K W',
    'T W', 'D W', 'K W', 'G W', 'TH W', 'P Y', 'B Y', 'K Y', 'G Y', 'F Y', 'V Y', 'M Y', 'HH Y',
]}


def load_cmudict():
    if not CACHE.exists():
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_bytes(urllib.request.urlopen(CMUDICT_URL).read())
    entries = defaultdict(list)
    for line in CACHE.read_text().splitlines():
        line = line.split('#')[0].strip()
        if line:
            word, *phones = line.split()
            entries[re.sub(r'\(\d+\)$', '', word)].append(' '.join(phones))
    return entries


def onset_length(cluster):
    for n in range(min(3, len(cluster)), 0, -1):
        tail = tuple(cluster[-n:])
        if (n == 1 and tail != ('NG',)) or tail in ONSETS:
            return n
    return 0


def vowel_ipa(base, stress, before_r):
    if base == 'AH':
        return 'ə' if stress == '0' else 'ʌ'
    if base == 'ER':
        return 'ɚ' if stress == '0' else 'ɝː'
    if base == 'IY':
        return 'ɪ' if before_r else ('i' if stress == '0' else 'iː')
    if base == 'UW':
        return 'ʊ' if before_r else ('u' if stress == '0' else 'uː')
    return VOWELS[base]


def normalize(arpabet):
    phones = []
    for phone in arpabet.split():
        # An unstressed ER before a vowel is ə plus the next syllable's r: around → əˈraʊnd.
        if phones and phones[-1] == 'ER0' and phone[-1].isdigit():
            phones[-1:] = ['AH0', 'R']
        phones.append(phone)
    vowels = [i for i, p in enumerate(phones) if p[-1].isdigit()]
    primaries = [i for i in vowels if phones[i].endswith('1')]
    for i in primaries[:-1]:
        phones[i] = phones[i][:-1] + '2'
    primary = primaries[-1] if primaries else None
    for n, i in enumerate(vowels):
        if phones[i].endswith('2'):
            adjacent = n + 1 < len(vowels) and vowels[n + 1] == primary
            if primary is None or i > primary or adjacent:
                phones[i] = phones[i][:-1] + ('0' if phones[i].startswith('IY') and i > (primary or 0) else '3')
    return phones, vowels


def word_ipa(arpabet, mark_stress):
    # Stress 3 is a secondary stress that keeps its full vowel but gets no mark.
    phones, vowels = normalize(arpabet)
    marks = {}
    if mark_stress and len(vowels) > 1:
        previous = -1
        for i in vowels:
            stress = phones[i][-1]
            if stress in '12':
                start = 0 if previous == -1 else i - onset_length(phones[previous + 1:i])
                marks[start] = 'ˈ' if stress == '1' else 'ˌ'
            previous = i
    out = []
    for i, phone in enumerate(phones):
        out.append(marks.get(i, ''))
        if phone[-1].isdigit():
            out.append(vowel_ipa(phone[:-1], phone[-1], i + 1 < len(phones) and phones[i + 1] == 'R'))
        else:
            # A t that ends one syllable before ʃ starts the next is not the affricate tʃ.
            out.append('.ʃ' if phone == 'SH' and i and phones[i - 1] == 'T' and not marks.get(i) else CONSONANTS[phone])
    return ''.join(out)


def transcribe(phrase, cmudict, words, chosen):
    tokens = [t for t in re.split(r'[\s\-]+', phrase.lower().replace(',', ' , ')) if t]

    def lexical(token):
        if token in chosen:
            return chosen[token]
        if token in words:
            return words[token]
        if token in cmudict:
            return cmudict[token][0]
        raise ValueError(f'No pronunciation for {token!r} in {phrase!r}; add it to pronunciation-overrides.json')

    out = []
    for n, token in enumerate(tokens):
        if token == ',':
            out[-1] += ','
            continue
        following = next((t for t in tokens[n + 1:] if t != ','), None)
        if token in WEAK and token not in chosen and following:
            arpabet = WEAK[token]
            if token == 'the' and lexical(following)[0] in 'AEIOU':
                arpabet = 'DH IY0'
        else:
            arpabet = lexical(token)
        out.append(word_ipa(arpabet, token not in UNSTRESSED))
    return ' '.join(out)


def main():
    catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
    overrides = json.loads((DATA / 'pronunciation-overrides.json').read_text())
    ids = {p['id'] for p in catalog}
    unknown = (set(overrides['phrases']) | set(overrides['ipa'])) - ids
    if unknown:
        raise ValueError(f'Overrides name IDs outside the catalog: {sorted(unknown)}')
    cmudict = load_cmudict()
    words = overrides['words']
    result = {}
    for phrase in catalog:
        lesson_id = phrase['id']
        result[lesson_id] = overrides['ipa'].get(lesson_id) or transcribe(
            phrase['phrase'], cmudict, words, overrides['phrases'].get(lesson_id, {}))
    (DATA / 'pronunciations.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(result)} pronunciations')


if __name__ == '__main__':
    main()
