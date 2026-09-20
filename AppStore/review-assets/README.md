# In-App Purchase review images

- [Japanese purchase screen](purchase-ja.png)
- [English purchase screen](purchase-en.png)

Both are unmodified, opaque 2064 × 2752 iPad captures of the native purchase
screen. They show Izzy Pro, the full 1,200-expression collection, a localized
¥900 button, no subscription, the free plan and restore purchases.

Use `purchase-ja.png` for the App Review Screenshot on existing non-consumable
`me.unvalley.izzy.complete.lifetime` (App Store Connect ID `6811354276`). This
is an IAP review asset, separate from the consumer product-page screenshots.
The English image is an alternative, not a second required upload.

The price was supplied by Apple's local Xcode StoreKit configuration. No price
was painted into the screenshot or hardcoded into the app. The passing result
`.build/BrandRelease/Purchase-IDE-Warmed.xcresult` verifies the native Product
button and both language views. `manifest.json` records hashes and provenance.
This is not evidence of a production or TestFlight transaction.

Apple accepts a supported app screenshot size for the IAP review image:
[In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information).
These images are prepared locally and have not been saved to App Store Connect.
