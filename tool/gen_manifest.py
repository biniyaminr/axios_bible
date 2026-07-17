#!/usr/bin/env python3
"""Generate assets/bible_data/manifest.json from the translation files.

Bundled translations live in assets/bible_data/ and ship inside the app.
Remote translations live in bible_data_remote/ and are downloaded on demand
from REMOTE_BASE_URL + filename (host that folder somewhere public, e.g. a
GitHub repo, and point REMOTE_BASE_URL at it).

Reads only the head of each JSON (the "translation" field is at the top in the
eBible dumps) to avoid parsing ~8MB files fully.
"""
import json
import os
import re

BUNDLED_DIR = "assets/bible_data"
REMOTE_DIR = "bible_data_remote"
# Where the files in bible_data_remote/ are hosted. Update this when the
# data repo is published (e.g. GitHub raw URL of a public data repo).
REMOTE_BASE_URL = "https://raw.githubusercontent.com/biniyaminr/axios-bible-data/main/"
# Files handled separately as app defaults
SKIP = {"amharic_bible.json", "english_kjv_bible.json", "manifest.json"}


def read_entry(path, fname, bundled):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        head = f.read(2048)

    m = re.search(r'"translation"\s*:\s*"((?:[^"\\]|\\.)*)"', head)
    if not m:
        m = re.search(r'"title"\s*:\s*"((?:[^"\\]|\\.)*)"', head)
    raw_name = json.loads('"%s"' % m.group(1)) if m else fname[:-5]

    stem = fname[:-5]
    # Names look like "ACV: A Conservative Version" -> short "ACV", name full
    if ":" in raw_name:
        short, rest = raw_name.split(":", 1)
        short = short.strip()
        name = rest.strip() or raw_name
        if len(short) > 12:
            short = stem
    else:
        short = stem
        name = raw_name

    return {
        "id": stem,
        "name": name,
        "shortName": short,
        "filename": fname,
        "bundled": bundled,
    }


entries = []
for directory, bundled in ((BUNDLED_DIR, True), (REMOTE_DIR, False)):
    if not os.path.isdir(directory):
        continue
    for fname in sorted(os.listdir(directory), key=str.lower):
        if not fname.endswith(".json") or fname in SKIP:
            continue
        entries.append(read_entry(os.path.join(directory, fname), fname, bundled))

manifest = {
    "version": 2,
    "remoteBaseUrl": REMOTE_BASE_URL,
    "translations": entries,
}
out = os.path.join(BUNDLED_DIR, "manifest.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=1)
bundled_count = sum(1 for e in entries if e["bundled"])
print(f"Wrote {out}: {bundled_count} bundled + {len(entries) - bundled_count} remote translations")
