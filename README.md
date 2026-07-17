# Axios Bible (የአማርኛ መጽሐፍ ቅዱስ)

A fully offline, multi-translation Bible app built with Flutter. Ships with the
Amharic 1954 Bible and the English KJV as defaults, plus a Translation Store
with 140 additional translations in dozens of languages — all bundled with the
app, no network required.

## Features

- **Premium reading experience** — glassmorphism UI, OLED-black dark mode and
  cream light mode, gold accent theme, adjustable font size and line spacing.
- **Dynamic multi-translation engine** — translations are registered from
  `assets/bible_data/manifest.json` at startup and loaded lazily on demand.
- **Translation Store** — search the full catalog, install translations with
  one tap, and remove them to free memory.
- **Split-screen parallel reading** — read two translations side by side with
  synchronized scrolling.
- **Search** — full-text verse search with filters (verses / chapters / texts)
  and highlighted matches; results jump straight to the reader.
- **Journal ("Revelations")** — attach categorized notes (Personal / Sermon /
  Prayer) to verse selections; swipe to delete.
- **Highlights & bookmarks** — multi-verse selection with color highlights,
  bookmarks, copy, and share.
- **Study Hub** — continue-reading card, recent journal entries, saved
  bookmarks, and per-book reading progress.
- **Verse of the day** — deterministic daily verse from a curated list of 40
  references, with an optional morning notification (a rolling week is
  scheduled ahead in the current translation and app language).
- **Reading plans & streaks** — five built-in plans (Bible in a Year, NT in
  90 Days, Gospels in 30, Psalms in 30, Proverbs in a Month) generated from
  the canonical book catalog; day-by-day progress and the daily reading
  streak are stored in SQLite, and tapping a reading jumps straight into the
  reader in the current translation.
- **Daily reading reminder** — optional local notification at a user-chosen
  time (Settings → Daily reading reminder), localized to the app language,
  timezone-aware, and survives reboots on Android.
- **Prayer list** — keep active prayer requests and mark them answered
  (opened from the Study Hub); stored in SQLite with swipe-to-delete.
- **Localized UI** — full Amharic and English interface via
  `flutter_localizations` (ARB files in `lib/l10n/`); language is switchable
  in Settings (System / አማርኛ / English) and persisted.

## Project layout

| File | Purpose |
| --- | --- |
| `lib/main.dart` | `BibleProvider` (state, data engine), app shell, bookmarks, settings, search delegate |
| `lib/premium_bible_screen.dart` | Main reading screen (split view, selection toolbar, journal sheet) |
| `lib/search_screen.dart` | Search tab |
| `lib/study_hub_screen.dart` | Dashboard tab |
| `lib/journal_screen.dart` | Journal list |
| `lib/translation_store_screen.dart` | Translation catalog / installer |
| `assets/bible_data/` | Translation JSON files + generated `manifest.json` |

## Bible data

Each translation is a single JSON file in one of two supported shapes, both
normalized by `BibleProvider._transformBibleData`:

1. eBible dump: `{"translation": "...", "books": [{"name", "chapters": [{"chapter", "verses": [{"verse", "text"}]}]}]}`
2. Nested map: `{"Genesis": {"1": {"1": "In the beginning..."}}}`

Translations live in two places:

- `assets/bible_data/` — the curated **bundled** set shipped inside the app
  (~28 MB): Amharic 1954, English KJV, BSB, and KJVA (with Apocrypha).
- `bible_data_remote/` — the remaining ~138 translations (~1 GB, gitignored).
  These are **downloaded on demand** from `remoteBaseUrl` (set in
  `tool/gen_manifest.py`) + filename. Host that folder's contents somewhere
  public — e.g. push it to a dedicated GitHub data repo — and point
  `REMOTE_BASE_URL` in the generator at it.

`manifest.json` is generated from the files on disk (both folders). If you add,
remove, or move translation files, regenerate it with:

```sh
python3 tool/gen_manifest.py
```

New translations then appear in the Translation Store automatically; remote
ones show a download button and are cached in the app documents directory.

## Development

```sh
flutter pub get
flutter run            # run the app
flutter test           # provider/data-engine tests
flutter analyze        # lint (should be clean)
```
