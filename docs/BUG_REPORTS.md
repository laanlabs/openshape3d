# In-app bug reports

The ladybug button at the right end of the editor toolbar (and "Report a
Bug…" under the gallery's ⋯ menu) opens a form: summary, what happened,
steps, optional email, and in the editor a toggle to attach the open design
as an `.os3d` archive. Send writes one document to the Firestore collection
`bugReports` and, when attached, one object to Cloud Storage under
`bugReports/<reportID>/<name>.os3d`.

## What ships in the app

No Firebase SDK. `openshape3d/App/BugReporting.swift` makes two plain
HTTPS calls to the Firestore and Cloud Storage REST APIs. There is no
analytics, crash reporting, or device identifier of any kind; nothing
leaves the device until the user presses Send, and the form's footer lists
exactly what goes along:

| Field | Source |
|---|---|
| `title`, `details`, `steps`, `contactEmail` | typed by the user (trimmed) |
| `createdAt`, `status: "new"`, `reportID` | set at send time |
| `context.appVersion`, `context.build` | `CFBundleShortVersionString` / `CFBundleVersion` |
| `context.osVersion`, `context.deviceModel` | `UIDevice` (e.g. "iOS 26.0", "iPad") |
| `context.documentName`, `bodyCount`, `featureCount`, `lastAction` | the open design (editor only) |
| `attachment.path`, `attachment.bytes` | when the design was attached |
| `attachmentError` | when an attachment was requested but could not be uploaded (report still filed) |

Attachments are capped at 40 MB (`BugAttachment.maxBytes`); a larger design
is refused with a message before anything uploads.

## Configuration (not in git)

The reporter reads three keys — `API_KEY`, `PROJECT_ID`, `STORAGE_BUCKET` —
from `openshape3d/GoogleService-Info.plist`, which is **git-ignored**. Copy
`docs/GoogleService-Info.example.plist` there and fill it in from the
Firebase console (Project settings → Your apps → the iOS app's plist). The
file sits in the app target's synchronized folder, so Xcode bundles it
automatically. A build without it still shows the button; the sheet then
says reporting isn't configured and Send stays disabled
(`FirebaseConfig.bundled == nil`). The placeholder values in the example
are rejected on purpose, so a copied-but-unedited example also reads as
"not configured".

The web API key is not a secret in the usual sense (it identifies the
project; Firebase security rules do the gating) but it is still kept out of
the repository as asked.

## One-time Firebase setup (project owner)

Done on 2026-09-05: Firestore and Storage are both provisioned for
`openshape3d`, and a report sent from the simulator landed end to end.
Two probe artifacts are labeled "safe to delete": Firestore document
`curl-probe-safe-to-delete` and Storage object
`bugReports/curl-probe/probe.txt`.

For a fresh project the steps are: Firestore Database → Create database
(Native mode), Storage → Get started (Blaze plan), then deploy the rules
below. If only Firestore is set up, reports still arrive: a failed upload
is recorded in the document's `attachmentError` and the sender is told the
design was not attached.

## Security model

The app writes as an unauthenticated client holding only the web API key,
and that key ships inside the binary — assume it is public. So the
**rules are the entire security model** on the client side, and triage
never uses the key at all:

| Who | Credential | May |
|---|---|---|
| The app (anyone with the key) | API key + rules | CREATE one report document with exactly the reporter's fields, and upload one `.os3d` under that report's prefix. Nothing else — no read, list, update, delete. |
| The project owner | Own Google account (`gcloud auth login`), through IAM | Read, download, mark resolved — `scripts/bug_reports.py`. IAM-authenticated REST calls are not subject to the rules. |

The rules are committed at `firebase/firestore.rules` and
`firebase/storage.rules`; `firebase.json` and `.firebaserc` point the CLI at
them and at the project. Publish (and re-publish after any change) with:

```
firebase login --reauth          # once per machine, interactive
firebase deploy --only firestore:rules,storage
```

Then confirm from the outside that the door is shut:

```
scripts/bug_reports.py probe
```

`probe` tries an anonymous list, read, update and bucket listing and exits
non-zero while any of them succeeds (all four did on 2026-09-05, before
deployment). The Firestore rules check every field's type and size, refuse
unknown keys, require `status == "new"`, require the document ID to be the
UUID the app mints, and pin `attachment.path` to `bugReports/<thatID>/…`.
The Storage rules accept one `.os3d` ≤ 40 MB with content type
`application/octet-stream` under a UUID prefix and refuse everything else.
Neither allows a client to read or list.

What the rules do NOT stop is spam: anyone with the key can file reports.
If that ever matters, Firebase App Check (attesting the iOS binary) is the
next layer; it needs the SDK, which the reporter deliberately avoids today.

## Triage from the terminal

`scripts/bug_reports.py` (plain Python, no packages) does everything the
console does, as you:

```
scripts/bug_reports.py list            # open reports; --all for every one
scripts/bug_reports.py show 6cb10527   # any unique id prefix
scripts/bug_reports.py fetch 6cb10527 /tmp/reports   # download the .os3d
scripts/bug_reports.py resolve 6cb10527 fixed Shell rebuilt without CSG
```

It mints a short-lived token with `gcloud auth print-access-token`, so the
one-time setup is `gcloud auth login` with the account that owns the
project (or any account holding Editor, or Cloud Datastore User + Storage
Object Viewer, on it). `BUG_REPORTS_TOKEN` overrides that for automation
(a service-account token). `resolve` writes `status`, `resolutionNote` and
`resolvedAt` with an update mask, so the report's own fields are untouched.

An attachment is a binary plist (`ProjectArchive`); `plutil -p` shows the
bodies and features, and each body's `mesh` is a `MeshBlob` (`D3SO`) the
tests load with `MeshBlob.decode` — the way the 2026-09-05 shell crash was
reproduced from its attachment (`CylinderShellCrashTests`).

## Verifying

- `BugReportingTests` covers config parsing, the Firestore document shape
  (integers as decimal strings, RFC 3339 timestamps, optional context and
  attachment maps), attachment-path sanitising, and server-error extraction.
- `BugReportUITests` opens the sheet from the toolbar, checks Send is
  disabled until a summary is typed, that the attach toggle is offered in
  the editor, and cancels. It never presses Send.
- A real send is a manual check: fill the form on the simulator, press
  Send, and confirm the document (and object) appear in the console. The
  success alert shows the report ID, which is also the document ID.
