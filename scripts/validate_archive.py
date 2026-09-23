#!/usr/bin/env python3
"""Validate the archive boundary; unsigned archives are not uploadable."""
import hashlib, json, plistlib, subprocess, sys
from pathlib import Path
archive=Path(sys.argv[1]).resolve()
mode=sys.argv[2] if len(sys.argv)>2 else 'unsigned'
root=Path(__file__).resolve().parents[1]
metadata=json.loads((root/'AppStore/metadata.json').read_text())
app=archive/'Products/Applications/Izzy.app'
info=plistlib.loads((app/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']==metadata['bundleID']
assert info['CFBundleShortVersionString']==metadata['version']
assert info['CFBundleVersion']==metadata['build']
assert info['CFBundleDisplayName']=='Izzy'
assert info['MinimumOSVersion']=='17.0'
assert info['ITSAppUsesNonExemptEncryption'] is False
assert 'NSMicrophoneUsageDescription' not in info, 'Microphone purpose string must not ship.'
for locale in ['en','ja']:
 purpose=app/f'{locale}.lproj/InfoPlist.strings'
 assert not purpose.exists() or 'NSMicrophoneUsageDescription' not in plistlib.loads(purpose.read_bytes()), 'Microphone purpose string must not ship.'
translations=json.loads((root/'Izzy/Resources/Localizable.xcstrings').read_text())['strings']
japanese=plistlib.loads((app/'ja.lproj/Localizable.strings').read_bytes())
for key in ['Settings','Restore purchases','Contact support','Privacy policy','Read privacy policy online','Terms of use']:
 assert japanese[key]==translations[key]['localizations']['ja']['stringUnit']['value'], f'Missing or stale shipped localization: {key}'
assert set(info['UIDeviceFamily'])=={1,2}
assert set(info['UISupportedInterfaceOrientations~ipad'])=={'UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'}
assert 'UILaunchScreen' in info
assert (app/'Assets.car').is_file()
privacy=plistlib.loads((app/'PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
# Izzy's own analytics and nothing else: product interaction, for analytics, not linked to a
# person and not tracking. The shipped manifest has to match what App Store Connect declares.
assert privacy['NSPrivacyCollectedDataTypes']==[{
 'NSPrivacyCollectedDataType': 'NSPrivacyCollectedDataTypeProductInteraction',
 'NSPrivacyCollectedDataTypeLinked': False,
 'NSPrivacyCollectedDataTypePurposes': ['NSPrivacyCollectedDataTypePurposeAnalytics'],
 'NSPrivacyCollectedDataTypeTracking': False,
}], 'Shipped privacy manifest does not match the declared App Privacy answer.'
assert privacy['NSPrivacyTrackingDomains']==[]
assert privacy['NSPrivacyAccessedAPITypes']==[]
expected_catalog=json.loads(Path(__file__).resolve().parents[1].joinpath('Izzy/Resources/phrases.json').read_bytes())
assert json.loads((app/'phrases.json').read_bytes())==expected_catalog, 'Archive catalog differs from reviewed source.'
assert not list(app.rglob('*.storekit')), 'Test purchase config must not ship.'
assert not list(app.rglob('*.xctest')), 'Test bundles must not ship.'
exe=app/info['CFBundleExecutable']
strings=subprocess.check_output(['/usr/bin/strings',str(exe)],text=True)
assert '--free-access' not in strings and '--reset-ui-tests' not in strings, 'Debug launch overrides leaked into Release.'
assert '--stats-fixture' not in strings, 'Debug statistics fixture leaked into Release.'
assert metadata['product']['id'] in strings
archs=subprocess.check_output(['xcrun','lipo','-archs',str(exe)],text=True).strip()
assert archs=='arm64'
if mode=='signed':
 subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
 assert (app/'embedded.mobileprovision').exists(), 'Missing provisioning profile.'
 # Sync needs the container in the profile; without it CloudKit fails for every customer.
 entitlements=plistlib.loads(subprocess.check_output(['codesign','-d','--entitlements','-','--xml',str(app)]))
 assert entitlements.get('com.apple.developer.icloud-services')==['CloudKit'], 'The profile lacks iCloud (CloudKit).'
 assert entitlements.get('com.apple.developer.icloud-container-identifiers')==['iCloud.me.unvalley.izzy'], 'The profile lacks the Izzy iCloud container.'
 assert entitlements.get('aps-environment') in ('development','production'), 'CloudKit pushes need aps-environment.'
report={'archive':str(archive),'mode':mode,'version':f"{metadata['version']} ({metadata['build']})",'architectures':archs,'executableSHA256':hashlib.sha256(exe.read_bytes()).hexdigest(),'uploadable':False,'note':'Archive checks only. App Store export, Distribution signing and server validation are separate.'}
(archive/'izzy-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
