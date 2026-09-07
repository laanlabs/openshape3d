#!/usr/bin/env python3
"""Triage the in-app bug reports as the project OWNER — never with the app's key.

The app's web API key ships inside the binary, so anything it can do, anyone
can do; the security rules (firebase/*.rules) therefore let a client CREATE a
report and nothing else. Reading, downloading attachments and marking reports
resolved go through your own Google account instead: the Firestore and Cloud
Storage REST APIs accept an OAuth access token and then check IAM, not the
rules. One-time setup on a machine:

    gcloud auth login            # the account that owns the Firebase project

after which every command below mints a short-lived token with
`gcloud auth print-access-token`. (Set BUG_REPORTS_TOKEN to supply one
yourself, e.g. from a service account, for automation.)

    scripts/bug_reports.py list [--all]          # open reports (or every report)
    scripts/bug_reports.py show <id-prefix>
    scripts/bug_reports.py fetch <id-prefix> [dir]   # download the .os3d attachment
    scripts/bug_reports.py resolve <id-prefix> <status> [note…]
    scripts/bug_reports.py probe                 # confirm the rules are closed

No third-party modules; Python 3.9+.
"""

import datetime
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT = "openshape3d"
BUCKET = "openshape3d.firebasestorage.app"
COLLECTION = "bugReports"
FIRESTORE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
DOCUMENTS = f"{FIRESTORE}/{COLLECTION}"


# MARK: - Auth

def access_token():
    token = os.environ.get("BUG_REPORTS_TOKEN")
    if token:
        return token.strip()
    try:
        out = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            capture_output=True, text=True, check=True)
    except FileNotFoundError:
        sys.exit("gcloud is not installed — `brew install --cask google-cloud-sdk`, "
                 "then `gcloud auth login`.")
    except subprocess.CalledProcessError as e:
        sys.exit("gcloud has no valid login for the Firebase project owner. Run:\n\n"
                 "    gcloud auth login\n\n" + e.stderr.strip())
    return out.stdout.strip()


def request(method, url, token=None, body=None, raw=False):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=120) as r:
        payload = r.read()
        return payload if raw else (json.loads(payload) if payload else {})


# MARK: - Firestore value helpers

def decode(value):
    if "stringValue" in value:
        return value["stringValue"]
    if "integerValue" in value:
        return int(value["integerValue"])
    if "doubleValue" in value:
        return value["doubleValue"]
    if "booleanValue" in value:
        return value["booleanValue"]
    if "timestampValue" in value:
        return value["timestampValue"]
    if "nullValue" in value:
        return None
    if "mapValue" in value:
        return {k: decode(v) for k, v in value["mapValue"].get("fields", {}).items()}
    if "arrayValue" in value:
        return [decode(v) for v in value["arrayValue"].get("values", [])]
    return value


def document_to_report(doc):
    fields = {k: decode(v) for k, v in doc.get("fields", {}).items()}
    fields["id"] = doc["name"].rsplit("/", 1)[-1]
    return fields


def fetch_all(token):
    reports, page = [], None
    while True:
        q = {"pageSize": 300}
        if page:
            q["pageToken"] = page
        d = request("GET", f"{DOCUMENTS}?{urllib.parse.urlencode(q)}", token)
        reports += [document_to_report(doc) for doc in d.get("documents", [])]
        page = d.get("nextPageToken")
        if not page:
            return sorted(reports, key=lambda r: r.get("createdAt") or "")


def find(token, prefix):
    matches = [r for r in fetch_all(token) if r["id"].startswith(prefix)]
    if len(matches) != 1:
        sys.exit(f"{len(matches)} reports match '{prefix}' — give more of the id.")
    return matches[0]


# MARK: - Commands

def cmd_list(args):
    token = access_token()
    show_all = "--all" in args
    rows = fetch_all(token)
    if not show_all:
        rows = [r for r in rows if r.get("status", "new") == "new"]
    if not rows:
        print("no open reports" if not show_all else "no reports")
        return
    for r in rows:
        ctx = r.get("context") or {}
        att = "📎" if r.get("attachment") else "  "
        print(f"{r['id'][:8]}  {(r.get('createdAt') or '')[:16]:16}  {r.get('status','new'):9} "
              f"{att} {r.get('title','')[:50]:50}  {ctx.get('deviceModel','')} {ctx.get('osVersion','')}")


def cmd_show(args):
    if not args:
        sys.exit("usage: bug_reports.py show <id-prefix>")
    r = find(access_token(), args[0])
    order = ["id", "createdAt", "status", "title", "details", "steps", "contactEmail",
             "context", "attachment", "attachmentError", "resolutionNote", "resolvedAt"]
    for key in order + [k for k in r if k not in order]:
        if key in r:
            value = r[key]
            print(f"{key}: {json.dumps(value, ensure_ascii=False) if isinstance(value, (dict, list)) else value}")


def cmd_fetch(args):
    if not args:
        sys.exit("usage: bug_reports.py fetch <id-prefix> [dir]")
    token = access_token()
    r = find(token, args[0])
    attachment = r.get("attachment")
    if not attachment:
        sys.exit(f"{r['id'][:8]} has no attachment"
                 + (f" ({r['attachmentError']})" if r.get("attachmentError") else ""))
    out_dir = args[1] if len(args) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    path = attachment["path"]
    url = (f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/"
           f"{urllib.parse.quote(path, safe='')}?alt=media")
    data = request("GET", url, token, raw=True)
    target = os.path.join(out_dir, f"{r['id'][:8]}-{os.path.basename(path)}")
    with open(target, "wb") as f:
        f.write(data)
    print(f"{target}  ({len(data):,} bytes)")


def cmd_resolve(args):
    if len(args) < 2:
        sys.exit("usage: bug_reports.py resolve <id-prefix> <status> [note…]\n"
                 "status is free text: fixed, answered, duplicate, wontfix, new …")
    token = access_token()
    r = find(token, args[0])
    status, note = args[1], " ".join(args[2:])
    fields = {"status": {"stringValue": status}}
    mask = [("updateMask.fieldPaths", "status")]
    if note:
        fields["resolutionNote"] = {"stringValue": note}
        mask.append(("updateMask.fieldPaths", "resolutionNote"))
    if status != "new":
        now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
        fields["resolvedAt"] = {"timestampValue": now}
        mask.append(("updateMask.fieldPaths", "resolvedAt"))
    d = request("PATCH", f"{DOCUMENTS}/{r['id']}?{urllib.parse.urlencode(mask)}",
                token, {"fields": fields})
    print(f"{r['id'][:8]} → {decode(d['fields']['status'])}  {r.get('title','')}")


def cmd_probe(_args):
    """The rules are closed iff every anonymous read/list/write is refused."""
    checks = [
        ("anonymous LIST of bugReports", "GET", f"{DOCUMENTS}?pageSize=1", None),
        ("anonymous READ of a report", "GET", f"{DOCUMENTS}/curl-probe-safe-to-delete", None),
        ("anonymous UPDATE of a report", "PATCH",
         f"{DOCUMENTS}/curl-probe-safe-to-delete?updateMask.fieldPaths=status",
         {"fields": {"status": {"stringValue": "new"}}}),
        ("anonymous storage LIST", "GET",
         f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o?prefix=bugReports/", None),
    ]
    closed = True
    for label, method, url, body in checks:
        try:
            request(method, url, None, body)
            print(f"OPEN    {label} — succeeded without credentials")
            closed = False
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                print(f"closed  {label} ({e.code})")
            else:
                print(f"?       {label} answered {e.code}")
                closed = False
    if not closed:
        sys.exit("\nThe rules are NOT locked down. Deploy them:\n"
                 "    firebase deploy --only firestore:rules,storage --project openshape3d")
    print("\nall clear: clients can only create reports")


COMMANDS = {"list": cmd_list, "show": cmd_show, "fetch": cmd_fetch,
            "resolve": cmd_resolve, "probe": cmd_probe}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        sys.exit(__doc__)
    try:
        COMMANDS[sys.argv[1]](sys.argv[2:])
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:400]
        if e.code == 403:
            sys.exit(f"403 from Google: the signed-in account has no access to project "
                     f"'{PROJECT}'. It needs a Firebase/IAM role there (Editor, or "
                     f"Cloud Datastore User + Storage Object Viewer).\n{detail}")
        sys.exit(f"HTTP {e.code}: {detail}")
