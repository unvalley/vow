"""List every name in a batch that already exists in the catalog, all at once."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / 'Izzy/Resources/phrases.json').read_text())
known = {entry['phrase'] for entry in catalog} | {alias for entry in catalog for alias in entry.get('aliases', [])}

for path in sys.argv[1:]:
    batch = json.loads(Path(path).read_text())
    clashes = {}
    earlier = set()
    for lesson in batch:
        names = [lesson['phrase'], *lesson.get('aliases', [])]
        for name in names:
            if name in known:
                clashes.setdefault(lesson['phrase'], []).append(name)
            elif name in earlier:
                clashes.setdefault(lesson['phrase'], []).append(f'{name} (repeated in batch)')
        earlier.update(names)
    for phrase, names in clashes.items():
        print(f'  {phrase}: collides on {sorted(set(names))}')
    print(f'{Path(path).name}: {len(batch) - len(clashes)}/{len(batch)} lessons are new')
