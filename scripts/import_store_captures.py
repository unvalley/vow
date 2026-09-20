#!/usr/bin/env python3
"""Import a complete passing iPhone/iPad capture test; retain raw PNGs unchanged."""
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
root = Path(__file__).resolve().parents[1]
base = root / 'AppStore/screenshots'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--phone')
parser.add_argument('--ipad')
args = parser.parse_args()
assert args.phone or args.ipad, 'Provide --phone and/or --ipad result bundles'
requested = {device: result for device, result in [('iPhone-6.9', args.phone), ('iPad-13', args.ipad)] if result}
catalog_sha = hashlib.sha256((root/'Izzy/Resources/phrases.json').read_bytes()).hexdigest()
existing = json.loads((base/'captures.json').read_text()) if (base/'captures.json').exists() else []
rows = [row for row in existing if row['device'] not in requested]
for device, result_arg in requested.items():
    result = Path(result_arg).resolve()
    summary = json.loads(subprocess.check_output(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(result), '--compact']))
    # A run can contain unrelated tests. Require this exact capture test to pass,
    # then check every expected attachment below; do not inherit the suite result.
    tree = json.loads(subprocess.check_output(['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', str(result), '--compact']))
    capture_tests = []
    def visit(node):
        if isinstance(node, dict):
            if node.get('nodeType') == 'Test Case' and node.get('nodeIdentifier') == 'BrandScreenshotsUITests/testCurrentStoreScreenshots()':
                capture_tests.append(node)
            for value in node.values():
                visit(value)
        elif isinstance(node, list):
            for value in node:
                visit(value)
    visit(tree)
    assert len(capture_tests) == 1 and capture_tests[0]['result'] == 'Passed', 'The store capture test must pass'
    assert not any('BrandScreenshotsUITests/' in failure['testIdentifierString'] for failure in summary.get('testFailures', []))
    export_root = root / '.build/BrandRelease'
    export_root.mkdir(parents=True, exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix=f'{result.stem}-{device}-', dir=export_root))
    subprocess.run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(result), '--output-path', str(out)], check=True)
    found = {}
    for test in json.loads((out/'manifest.json').read_text()):
        if not test['testIdentifier'].startswith('BrandScreenshotsUITests/testCurrentStoreScreenshots'):
            continue
        for attachment in test['attachments']:
            match = re.match(r'brand-(ja|en)-(\d\d-[a-z]+)_', attachment['suggestedHumanReadableName'])
            if not match:
                continue
            assert not attachment['isAssociatedWithFailure']
            lang, key = match.groups()
            assert (lang, key) not in found, f'Duplicate capture: {lang}/{key}'
            raw = (out/attachment['exportedFileName']).read_bytes()
            found[(lang, key)] = (raw, attachment, test['testIdentifier'])
    expected = {(lang, row['key']) for lang, content in json.loads((base/'copy.json').read_text()).items() for row in content}
    assert set(found) == expected, f'Incomplete {device}: {expected-set(found)}'
    for (lang, key), (raw, attachment, test_id) in sorted(found.items()):
        file = f'raw/{device}/{lang}-{key}.png'
        dest = base/file
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(raw)
        rows.append({'file': file, 'device': device, 'language': lang, 'key': key,
                     'sha256': hashlib.sha256(raw).hexdigest(),
                     'resultBundle': str(result.relative_to(root)), 'test': test_id,
                     'deviceID': attachment['deviceId'], 'deviceName': attachment['deviceName'],
                     'capturedAt': attachment['timestamp'], 'catalogSHA256': catalog_sha,
                     'captureTestResult': 'Passed', 'containingRunResult': summary['result']})
(base/'captures.json').write_text(json.dumps(rows, indent=2)+'\n')
print(f'Imported {len(rows)} unmodified captures from passing capture tests.')
