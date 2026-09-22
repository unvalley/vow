# In-App Purchase review images

- [Japanese purchase screen](purchase-ja.png)
- [English purchase screen](purchase-en.png)

Both are unmodified, opaque 1320 × 2868 iPhone captures of the native purchase
screen in app `6814155678`, taken on 23 September 2026 from the current build.
They show Izzy Pro, the plan table, a localized ¥1,920 button, no subscription,
what stays free and restore purchases. Upload the Japanese one as the App Review
Screenshot for `me.unvalley.izzy.pro.lifetime`; the English image is an
alternative, not a second required upload.

The price was supplied by Apple's local StoreKit configuration
(`Configuration/Izzy.storekit`, the ¥1,920 early-release price). No price was
painted into the screenshot or hardcoded into the app. The passing result
`.build/shots/PurchasePhone.xcresult` verifies the native Product button and both
language views; `manifest.json` records hashes and provenance. This is not
evidence of a production or TestFlight transaction.

`xcodebuild` does not apply a scheme's StoreKit configuration to the app under
test, so `Product.products(for:)` returns nothing and the screen offers to reload
the price. Xcode's Run action installs the configuration into the simulator's
StoreKit test store, which is what the earlier runs relied on. Installing the same
repository file there directly has the same effect and needs no Xcode session:

```sh
DEVICE=24928272-6458-4EA9-9058-07C5EC1C73A2   # Izzy Store iPhone 17 Pro Max
OCTANE=$(find ~/Library/Developer/CoreSimulator/Devices/$DEVICE \
  -path "*Documents/Persistence/Octane" -maxdepth 12)
mkdir -p "$OCTANE/me.unvalley.izzy"
python3 -c 'import json,sys; c=json.load(open("Configuration/Izzy.storekit")); c["appName"]="Izzy"; json.dump(c,open(sys.argv[1],"w"),indent=2,ensure_ascii=False)' \
  "$OCTANE/me.unvalley.izzy/Configuration.storekit"
xcodebuild -project Izzy.xcodeproj -scheme IzzyStore \
  -destination "platform=iOS Simulator,id=$DEVICE" \
  -derivedDataPath .build/shots/StoreDerivedData \
  -resultBundlePath .build/shots/PurchasePhone.xcresult \
  -parallel-testing-enabled NO \
  -only-testing:IzzyUITests/IzzyUITests/testNativePurchaseReviewScreenshots test
```

The file installed there is the repository's own configuration, so the price the
screenshot shows is still StoreKit's formatting of the configured ¥1,920.

Apple accepts a supported app screenshot size for the IAP review image:
[In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information).
These images are prepared locally and have not been saved to App Store Connect.
