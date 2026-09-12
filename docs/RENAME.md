# vow repository and rename — 12 September 2026

The iOS app is now maintained in the standalone `unvalley/vow` repository.
The visible app name is **vow**, the Swift module and Xcode project are **Vow**,
and **1.0.0 (2)** is distributed through internal TestFlight. Purchase-screen copy, StoreKit test metadata,
support/privacy drafts, and prepared App Store metadata use the new name.

Compatibility identifiers intentionally retain their original values:

- Bundle ID: `me.unvalley.verve`.
- Non-consumable product: `me.unvalley.verve.complete.lifetime`.
- App Store SKU: `verve-ios-001`.
- Learning data: `Application Support/Verve/learning.json`.
- The temporary-recording prefix remains `verve-` so abandoned recordings from
  earlier builds are still reclaimed.

## Initial rename verification

- Release Swift Package: 27 tests passed, zero failures.
- CSV import: four tests passed, zero failures.
- Metadata consistency and copy limits passed; the pre-existing external
  submission fields are still outstanding.
- Simulator Release build passed. Built Info.plist reports display name `vow`,
  build `2`, and the unchanged bundle ID. Its 614-phrase JSON resource is
  byte-for-byte identical to the previous version.
- Installed over the existing simulator app and launched successfully. Visually
  checked Today and the Settings section labeled `vow Complete`.
- Source secret scan passed with no findings. Signing keys, certificates,
  provisioning profiles, local progress, build products, and local test logs are
  excluded from the repository. Public support contact remains studio@unvalley.me.

Previous performance and TestFlight records describe the earlier Verve checkout.
Their local `.build` artifacts are retained there and are not committed here.
The follow-up release uploaded build 2 and verified its **Testing** state in the
existing Internal group. Apple rejected the exact store name `vow` as taken;
the Japanese listing now uses `vow：句動詞を会話に`. The installed app remains `vow`.
See [TestFlight build 2](../AppStore/TESTFLIGHT.md) for the source revision,
artifact checks, and distribution evidence. Live IAP localization changes are
separate from the binary rename; the existing product identifier is unchanged.
