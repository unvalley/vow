#!/usr/bin/env python3
"""Validate the archive boundary; unsigned archives are not uploadable."""
import hashlib, json, plistlib, subprocess, sys
from pathlib import Path
archive=Path(sys.argv[1]).resolve()
mode=sys.argv[2] if len(sys.argv)>2 else 'unsigned'
app=archive/'Products/Applications/Vow.app'
info=plistlib.loads((app/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='me.unvalley.verve'
assert info['CFBundleShortVersionString']=='1.0.0'
assert info['CFBundleVersion']=='3'
assert info['CFBundleDisplayName']=='vow'
assert info['MinimumOSVersion']=='17.0'
assert info['ITSAppUsesNonExemptEncryption'] is False
assert info.get('NSMicrophoneUsageDescription')
assert set(info['UIDeviceFamily'])=={1,2}
assert set(info['UISupportedInterfaceOrientations~ipad'])=={'UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'}
assert 'UILaunchScreen' in info
assert (app/'Assets.car').is_file()
privacy=plistlib.loads((app/'PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
assert privacy['NSPrivacyCollectedDataTypes']==[]
assert len(json.loads((app/'phrases.json').read_bytes()))==614
assert not list(app.rglob('*.storekit')), 'Test purchase config must not ship.'
assert not list(app.rglob('*.xctest')), 'Test bundles must not ship.'
exe=app/info['CFBundleExecutable']
strings=subprocess.check_output(['/usr/bin/strings',str(exe)],text=True)
assert '--free-access' not in strings and '--reset-ui-tests' not in strings, 'Debug launch overrides leaked into Release.'
assert 'me.unvalley.verve.complete.lifetime' in strings
archs=subprocess.check_output(['xcrun','lipo','-archs',str(exe)],text=True).strip()
assert archs=='arm64'
if mode=='signed':
 subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
 assert (app/'embedded.mobileprovision').exists(), 'Missing provisioning profile.'
report={'archive':str(archive),'mode':mode,'version':'1.0.0 (3)','architectures':archs,'executableSHA256':hashlib.sha256(exe.read_bytes()).hexdigest(),'uploadable':False,'note':'Archive checks only. App Store export, Distribution signing and server validation are separate.'}
(archive/'vow-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
