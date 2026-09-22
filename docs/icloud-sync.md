# Learning data in iCloud

Learning history is the part of Izzy that cannot be rebuilt: months of reviews, the phrases
someone saved, what they wrote about them. Until now it lived in one file on one device, and
Settings said so. **Sync with iCloud** keeps that file in the learner's own private iCloud
database as well, so it follows them to a new phone and stays the same on an iPhone and an iPad.

It is on unless it is turned off in Settings → iCloud. There is no account to make: CloudKit uses
the Apple Account the device is already signed in to, and the developer cannot read a private
database.

## What is stored

One record, `Learning`, in a custom zone `Learning` of the private database of the container
`iCloud.me.unvalley.izzy`:

| Field | |
| --- | --- |
| `data` | `CKAsset`: the whole learning file as JSON, compressed with LZFSE |
| `format` | The layout of that JSON, `LearningMerge.format` |

The whole file rather than a record per phrase: it is one learner's own data, a few hundred
kilobytes, and a single record is one upload, one conflict and one merge rather than thousands.

`format` is what an older build reads first. A record written by a newer build — a new field or a
new enum case in `LearningData` — is left alone, nothing is uploaded over it, and Settings says to
update Izzy. So **adding a field or a case to `LearningData` means handling it in `LearningMerge`
and raising `LearningMerge.format`.** `LearningMergeTests` pins the field list; it fails until both
are done.

## Merging

Two devices may both have changed the file while offline, so nothing is overwritten by whoever
uploads last. `LearningMerge.merge(base:local:remote:)` is a three-way merge against `base`: the
copy this device last saw on the server, kept beside the learning file in `sync-base.json`.

- A field changed on one side only takes that side's value.
- Reviews and meaning reviews are merged per phrase; a phrase rated on both keeps the later one.
- Practice events are merged by ID, so a day's answer changed on another device replaces that
  day's record instead of adding one, and everything else from both sides is kept.
- Saved phrases are a set: an addition on one side and a removal on the other both apply.
- A note written on both sides keeps both, one after the other, rather than losing either.
- Anything else changed on both sides keeps this device's value. The device that loses the race to
  upload is the one that merges, and the other then takes the result unchanged, so the two agree.
- The reading voice stays on its device, because voices are installed per device.

With no base — the first sync, or after the iCloud account changed — settings come from the copy
with more history, so a fresh install picks up the learner's choices instead of the defaults it
just set for itself, and the histories are combined.

## How it runs

`CloudSync` owns a `CKSyncEngine`, which decides when to fetch and send and retries what it should.

- Every save in `LearningStore` marks the record as changed; the engine sends it soon after. An
  upload that would match the server copy is dropped instead of sent.
- A copy that arrives, by push or by fetch, is merged and written back to the learning file. The
  merge result is uploaded only when it differs from what the server holds.
- Returning to the foreground fetches, in case a push was missed. Leaving it sends what is
  pending, with background time, so a review reaches iCloud before the app is suspended.
- A conflict comes back with the server's record, which is merged the same way.
- Deleting Izzy's data from iCloud storage in the Settings app turns sync off on every device and
  keeps each device's own copy.
- Signing out keeps the local file; signing in to another account merges into that account's copy.
- Unit and UI tests run unsigned, without the entitlement, and never construct the engine.

`sync-state.json` holds the engine's state, the last server copy's system fields and the time of
the last sync. `sync-base.json` holds the base described above. Neither leaves the device.

## Before it works for customers

- The container `iCloud.me.unvalley.izzy` has to exist in the developer account; automatic signing
  registers it while building with a team. `validate_archive.py` fails a signed archive whose
  profile has no iCloud container, so an archive cannot reach TestFlight without it.
- TestFlight and the App Store use the **production** CloudKit environment. The `Learning` record
  type is created in the development environment by the first save from a development build, and
  has to be deployed to production in CloudKit Console before any TestFlight build can sync.

## Not verified yet

Two devices syncing has not been run. The merge is covered by `LearningMergeTests`; everything
above about CloudKit itself — the container, the schema, pushes, conflicts between two real
devices — is untested until a signed build runs on two simulators or devices signed in to the same
Apple Account.
