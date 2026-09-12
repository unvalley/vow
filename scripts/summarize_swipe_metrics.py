#!/usr/bin/env python3
"""Extract raw XCTest UI metric samples without mixing them with driver logs."""
import json
import math
from pathlib import Path
import re
import statistics
import sys

results = {}
for name in sys.argv[1:]:
    metrics = {}
    for line in Path(name).read_text().splitlines():
        match = re.search(r"measured \[(.*?)\].*?values: \[(.*?)\].*?performanceMetricID:([^,]+)", line)
        if match:
            values = [float(value) for value in match[2].split(",")]
            metrics[match[3]] = dict(label=match[1], values=values, n=len(values),
                                     p50=statistics.median(values), p95=sorted(values)[math.ceil(len(values) * .95) - 1])
    results[Path(name).name] = metrics
print(json.dumps(results, ensure_ascii=False, indent=2))
