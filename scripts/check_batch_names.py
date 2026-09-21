"""Pre-merge batch checks: existing names, glosses, and core-image coverage."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from add_expressions import core_images, links_to_core_image

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
    images = core_images()
    imageless = [l['phrase'] for l in batch
                 if l['kind'] == 'phrasal' and not links_to_core_image(l['phrase'], images)]
    for phrase in imageless:
        print(f'  note: {phrase} has no core-image particle, so it shows no core-image card')
    for lesson in batch:
        gloss = lesson.get('gloss', '').strip()
        if not gloss or len(gloss.split()) > 3 or gloss.lower() == lesson['phrase'].lower():
            print(f"  {lesson['phrase']}: gloss {gloss!r} must be one to three words and not itself")
    print(f'{Path(path).name}: {len(batch) - len(clashes)}/{len(batch)} lessons are new, '
          f'{len(imageless)} show no core image')
