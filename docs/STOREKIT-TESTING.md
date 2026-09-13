# StoreKit verification — 13 September 2026

The production app uses verified StoreKit 2 entitlements. The historical
investigation below used the payment implementation from **1.0.0 (7)**. The
current working tree includes later localization and App Review preparation; it
must not be described as identical to an uploaded build. No payment bypass or
fixed price was added. Local Xcode StoreKit transactions do not prove
TestFlight or production behavior.

## App Review preparation retest

On 13 September, the two transaction tests were rerun serially on iPhone 17 Pro
(iOS 26.5). Both failed at the test-configuration precondition in approximately
1.2 seconds total: `SKInternalErrorDomain Code=3` prevented applying configuration
and verifying `disableDialogs`. No purchase was attempted. Evidence:
`.build/app-review-readiness/StoreKit.xcresult` and `storekit.log`.

The session helper now verifies dialog suppression before returning a session.
This makes the existing environment failure explicit; it does not skip tests or
turn a failed transaction check into a pass. Purchase, restore, refund and
pending approval still require a working StoreKit environment and final-device
Sandbox verification.

## Current evidence

| Boundary | Result | Evidence |
| --- | --- | --- |
| Native ¥900 product and Japanese/English purchase screens | Passed | `.build/BrandRelease/Purchase-IDE-Warmed.xcresult`; `AppStore/review-assets/` |
| Local Xcode payment confirmation and unlocked app | Observed inside a later failing test | `.build/BrandRelease/Purchase-UI-Transaction.xcresult` |
| Purchased access after app termination/relaunch | Observed inside that same failing test | The unlocked assertion after relaunch passed before the restore assertion |
| Restore completion notice | Not verified; UI test failed waiting for the notice | `purchase-ui-transaction.log`, experimental test line 210 |
| Host purchase/restore/refund and Ask to Buy | Not verified | `StoreKit-IDE-Warmed.xcresult` interrupted; `StoreKit-IDE-Direct.xcresult` failed/cancelled |
| Physical-device TestFlight/sandbox transaction, refund and offline purchase state | Not verified | Requires the processed build installed on a test device |

The current iPad simulator contains the local test purchase. Clear it in Xcode's
StoreKit transaction manager before another fresh-purchase scenario. Do not
interpret that simulator entitlement as a production purchase.

## Product loading workaround observed here

Initial CLI runs returned no Product. StoreKitTest configuration changes logged
`SKInternalErrorDomain Code=3`; simulator logs showed a sandbox product request.
The same production app successfully loaded the local configured product after
this sequence:

1. Open `Vow.xcodeproj` in Xcode.
2. Select **VowStore** and **Verve Store iPad 13**. Confirm the destination in the
   toolbar; Xcode's AppleScript active-destination getter was unreliable here.
3. Run the app and wait for it to appear, then Stop. The successful IDE action
   was `97597-1` on simulator `B63A7AF0-8225-4EEE-A305-0A038CCBE547`.
4. Run the focused screenshot test on that same simulator:

```sh
xcodebuild -project Vow.xcodeproj -scheme VowStore \
  -destination 'platform=iOS Simulator,id=B63A7AF0-8225-4EEE-A305-0A038CCBE547' \
  -derivedDataPath .build/BrandRelease/DerivedData \
  -resultBundlePath /tmp/Vow-Purchase-Capture-NEW.xcresult \
  -parallel-testing-enabled NO \
  -only-testing:VowUITests/VowUITests/testNativePurchaseReviewScreenshots test
```

Choose a new result-bundle path for each run. This test expects an unpurchased
local product. It does not complete a transaction. The successful run's images
are untouched captures of the native Product price and purchase view.

The warmup resolved **product loading**, not all StoreKitTest operations. The
successful UI log still includes configuration mutation errors. Do not claim
that setting/resetting storefronts or clearing transactions succeeded merely
because those void APIs returned.

## Transaction investigation

The existing `VowStoreTests/PurchaseStoreTests.swift` has two integration
scenarios: purchase/new-store-instance/restore/refund and Ask to Buy approval.
After warmup, CLI execution still could not configure dialog suppression and
waited on an Xcode payment sheet. It was explicitly interrupted, with logs and
result preserved. A temporary IDE scheme selected only these tests; direct IDE
execution did not prove them either. Its result is copied to
`.build/BrandRelease/StoreKit-IDE-Direct.xcresult`; the temporary scheme was
removed from the project and retained with the evidence.

A separate exploratory UI test confirmed only a payment sheet labeled **Xcode**,
then tapped Purchase, asserted `purchaseUnlocked`, terminated/relaunched the app
and asserted purchased access again. It failed waiting 10 seconds for the restore notice. The failure hierarchy still
showed purchased access, a processing indicator and a disabled Restore button;
no error notice was shown. This timeout does not establish the cause.
The exact experimental source is retained as
`.build/BrandRelease/Purchase-UI-Transaction-Test.swift`; it was removed from the
regular UI suite because its fresh-purchase precondition cannot currently be
reset reliably in this environment. Its result is retained as failure evidence,
not counted as a passing test.

The remaining transaction behavior needs verification in a working test
environment. These observations do not justify changing the app's entitlement
logic to trust unverified transactions or adding a Release test unlock.
