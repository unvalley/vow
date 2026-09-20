#!/usr/bin/env python3
"""Check copy constraints and explicitly report external submission blockers."""
import json, plistlib, re, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'AppStore/metadata.json').read_text())
for locale,copy in data['localizations'].items():
 for key,limit in [('name',30),('subtitle',30),('promotionalText',170),('keywords',100),('description',4000)]:
  assert len(copy[key])<=limit, f'{locale}.{key}: {len(copy[key])}/{limit}'
for locale in ['ja','en-US']:
 assert len(data['product'][locale]['name'])<=30
 assert len(data['product'][locale]['description'])<=55, f'{locale} IAP description exceeds 55 characters'
config=json.loads((root/'Configuration/Izzy.storekit').read_text())
assert config['products'][0]['productID']==data['product']['id']
# The local StoreKit product shows what a customer pays today: the launch price while the
# early-release discount runs, the standard price once it is changed back.
assert config['products'][0]['displayPrice']==str(data['product'].get('launchPriceJPY') or data['product']['standardPriceJPY'])
assert data['product']['launchPriceJPY'] is None or data['product']['launchPriceJPY']<data['product']['standardPriceJPY']
assert config['products'][0]['type']=='NonConsumable'
assert not config['subscriptionGroups']

# Validate the source that will be submitted, not only listing copy lengths.
project=(root/'project.yml').read_text()
assert re.search(r'CURRENT_PROJECT_VERSION:\s*[\'\"]?'+re.escape(data['build'])+r'[\'\"]?\s*$',project,re.M)
assert re.search(r'MARKETING_VERSION:\s*[\'\"]?'+re.escape(data['version'])+r'[\'\"]?\s*$',project,re.M)
support=(root/'Izzy/Services/AppSupport.swift').read_text()
for key in ['supportURL','privacyPolicyURL']:
 assert 'URL(string: "'+data['requiredBeforeSubmission'][key]+'")' in support, f'{key} differs between app and listing'
assert data['requiredBeforeSubmission']['supportEmail'] in support
privacy=plistlib.loads((root/'Izzy/PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
assert privacy['NSPrivacyTrackingDomains']==[]
# Izzy's own analytics: product interaction, for analytics, not linked to a person and not
# tracking. Anything beyond this one entry is a change the store listing has to describe too.
assert privacy['NSPrivacyCollectedDataTypes']==[{
 'NSPrivacyCollectedDataType': 'NSPrivacyCollectedDataTypeProductInteraction',
 'NSPrivacyCollectedDataTypeLinked': False,
 'NSPrivacyCollectedDataTypePurposes': ['NSPrivacyCollectedDataTypePurposeAnalytics'],
 'NSPrivacyCollectedDataTypeTracking': False,
}], 'Re-answer App Privacy in App Store Connect before changing what the app collects.'
assert privacy['NSPrivacyAccessedAPITypes']==[], 'Re-audit required-reason API use before changing the manifest.'
# Recording and the microphone permission were removed in build 21 (05d1d21); validate_archive.py
# asserts the purpose string never ships, so nothing here may require one.
purpose=json.loads((root/'Izzy/Resources/InfoPlist.xcstrings').read_text())
assert 'NSMicrophoneUsageDescription' not in purpose['strings'], 'Microphone purpose string must not return.'
catalog=json.loads((root/'Izzy/Resources/Localizable.xcstrings').read_text())
for key in ['Settings','Restore purchases','Contact support','Privacy policy','Read privacy policy online','Terms of use']:
 assert catalog['strings'][key]['localizations']['ja']['stringUnit']['value'].strip(), f'Missing Japanese review-facing copy: {key}'
missing=[k for k,v in data['requiredBeforeSubmission'].items() if not v]
# Apple's price point identifier is opaque and not worth transcribing; what matters is that the
# price was set and read back in App Store Connect.
if not data['product'].get('priceConfirmedAt'): missing.append('priceConfirmedAt')
print('Local metadata limits and product consistency: PASS')
print('Version, support links, privacy manifest and review-facing localization: PASS')
print('Remaining external inputs: '+', '.join(missing))
if '--require-ready' in sys.argv and missing: sys.exit(1)
