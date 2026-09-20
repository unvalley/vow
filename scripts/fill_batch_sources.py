"""Fill each lesson's `source` from a probed pool, matching on the phrase.

Authoring a batch without retyping URLs keeps transcription errors out of the
catalog. The pool is the JSON written by the candidate probe: a list of
{"phrase", "url"}. Every lesson must find a match, and any lesson that already
carries a source is left alone.

    python3 scripts/fill_batch_sources.py <batch.json> <pool.json>
"""
import json
import sys
from pathlib import Path


def main(batch_path, pool_path):
    batch = json.loads(Path(batch_path).read_text())
    pool = {row['phrase']: row['url'] for row in json.loads(Path(pool_path).read_text())}
    missing = []
    filled = 0
    for lesson in batch:
        if lesson.get('source', '').strip():
            continue
        url = pool.get(lesson['phrase']) or pool.get(lesson.get('slug', ''))
        if not url:
            missing.append(lesson['phrase'])
            continue
        lesson['source'] = url
        lesson.pop('slug', None)
        filled += 1
    if missing:
        raise SystemExit(f'no probed URL for: {missing}')
    Path(batch_path).write_text(json.dumps(batch, ensure_ascii=False, indent=2) + '\n')
    print(f'filled {filled} sources from {Path(pool_path).name}')


if __name__ == '__main__':
    main(*sys.argv[1:3])
