#!/usr/bin/env python3
"""Check copy constraints and explicitly report external submission blockers."""
import json, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'AppStore/metadata.json').read_text())
for locale,copy in data['localizations'].items():
 for key,limit in [('name',30),('subtitle',30),('promotionalText',170),('keywords',100),('description',4000)]:
  assert len(copy[key])<=limit, f'{locale}.{key}: {len(copy[key])}/{limit}'
for locale in ['ja','en-US']:
 assert len(data['product'][locale]['name'])<=30
 assert len(data['product'][locale]['description'])<=55, f'{locale} IAP description exceeds 55 characters'
config=json.loads((root/'Configuration/Vow.storekit').read_text())
assert config['products'][0]['productID']==data['product']['id']
assert config['products'][0]['displayPrice']==str(data['product']['intendedCustomerPriceJPY'])
assert config['products'][0]['type']=='NonConsumable'
assert not config['subscriptionGroups']
missing=[k for k,v in data['requiredBeforeSubmission'].items() if not v]
if data['product']['confirmedPricePointID'] is None: missing.append('confirmedPricePointID')
print('Local metadata limits and product consistency: PASS')
print('Remaining external inputs: '+', '.join(missing))
if '--require-ready' in sys.argv and missing: sys.exit(1)
