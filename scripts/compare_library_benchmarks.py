#!/usr/bin/env python3
"""Alternate warm baseline/after binaries; retain raw samples and p50/p95.

Usage: compare_library_benchmarks.py BASELINE AFTER CATALOG OUTPUT_DIRECTORY
The Swift benchmark accepts CATALOG QUERY SAMPLE_COUNT. Build both with -O.
"""
import csv
import io
import json
import math
from pathlib import Path
import statistics
import subprocess
import sys

baseline, after, catalog, destination = sys.argv[1:]
output = Path(destination)
output.mkdir(parents=True, exist_ok=False)
rows = []
queries = ["", "   ", "l", "look", "look into", "調べ", "round", "zzzz-no-match"]
for batch in range(5):
    for query in queries:
        order = [("baseline", baseline), ("after", after)]
        if batch % 2:
            order.reverse()
        counts = {}
        for label, executable in order:
            result = subprocess.run([executable, catalog, query, "20"], check=True, capture_output=True, text=True)
            values = list(csv.DictReader(io.StringIO(result.stdout)))
            counts[label] = [(r["operation"], r["count"]) for r in values]
            rows.extend(dict(version=label, batch=batch, **row) for row in values)
        if counts["baseline"] != counts["after"]:
            raise RuntimeError(f"Result counts changed for {query!r}")
    print(f"Completed batch {batch + 1}/5", flush=True)
with (output / "samples.csv").open("w") as file:
    writer = csv.DictWriter(file, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
summary = []
for query in queries:
    for operation in ["all-view-results", "verb-view-results"]:
        row = dict(query=query, operation=operation)
        for version in ["baseline", "after"]:
            samples = sorted(float(r["milliseconds"]) for r in rows if r["query"] == query and r["operation"] == operation and r["version"] == version)
            row[version] = dict(n=len(samples), p50_ms=statistics.median(samples), p95_ms=samples[math.ceil(len(samples) * .95) - 1])
        summary.append(row)
(output / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(summary, ensure_ascii=False, indent=2))
