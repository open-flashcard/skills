---
name: ofc-convert
description: Convert flashcards to and from the Open Flashcard Standard (OFC: .ofc.json, deck folders, .ofc archives). Imports and exports Anki (.apkg, .colpkg, plain-text .txt exports), Quizlet exports, CSV/TSV spreadsheets, and Markdown or Obsidian flashcard notes. Maps cloze deletions, reversed cards, images, audio, maths, and tags, and reports exactly what could not be carried across. Use when the user wants to import, export, migrate, or move a deck between Anki, Quizlet, a spreadsheet, or notes and OFC.
license: Apache-2.0
compatibility: Fetches the normative schema from raw.githubusercontent.com (falls back to a bundled checklist offline). Reading .apkg files needs Python 3 with the sqlite3 module, and zstd for decks exported by newer Anki versions.
metadata:
  author: open-flashcard
  version: "1.0.0"
  ofc-spec: "1.0.0"
allowed-tools: Bash(curl -fsSL https://raw.githubusercontent.com/open-flashcard/*) Bash(unzip -l *)
---

# Convert between Open Flashcard and other formats

A conversion should carry the content across faithfully and report whatever it could not. It
should not rewrite the cards. Improving them is a separate step, which you offer at the end.

The per-format mappings are in the references. Read the one you need:

- [references/anki.md](references/anki.md): `.apkg`, `.colpkg`, and Anki's plain-text export, in
  both directions
- [references/quizlet-csv-markdown.md](references/quizlet-csv-markdown.md): Quizlet, CSV/TSV,
  Markdown, and Obsidian notes, in both directions
- [references/spec-rules.md](references/spec-rules.md): what a valid OFC deck must satisfy

## 1. Identify the source

Look at the actual bytes, not only the extension. A `.apkg` is a Zip archive (check with
`unzip -l`). Quizlet exports are plain text with separators the user chose. A "CSV" may really be
tab-separated. Work out the direction: into OFC, out of OFC, or OFC → OFC re-packaging.

## 2. Ask once, then work

Ask everything you can't infer **in one message**:

- **Target packaging**, when the target is OFC. Always ask:
  - `<slug>.ofc.json`: a single file. Media must be URLs or `data:` URIs.
  - `<slug>/deck.json` plus media: a folder.
  - `<slug>.ofc`: that folder as a Zip.

  If the source contains media files, recommend the folder or `.ofc`.
- **Deck id**: `urn:ofc:deck:<publisher>/<slug>`. Ask for the publisher handle.
- **Languages** of the front and back content, used to set `lang`.
- **Column mapping, separators, or note-type mapping**, whenever the reference says it is ambiguous.
  Show the user a two-card preview of your proposed mapping.
- **Splitting**: whether a multi-deck source becomes one OFC deck with tags (the default) or one OFC
  deck per source deck.

## 3. Convert

Follow the reference mapping exactly. General rules:

- **Faithful content.** Keep the wording. Convert markup to the closest block (reference tables). Do
  not merge, split, or "fix" cards, except where the format's own card generation requires it: Anki
  cloze numbers and reversed note types produce several cards.
- **No study history.** Scheduling, intervals, due dates, ease, review logs, and suspension flags
  are out of scope for OFC (§1.2). Publishing them would also disclose the learner's history. Drop
  them and say so. Keep only the source identifiers needed for round-tripping, as `x-` properties
  (for example, `x-anki-guid`).
- **Stable ids.** Derive card ids from source ids (`anki-1496359529721`, `row-17`), so that
  re-running the conversion produces the same ids.
- **Media.** Copy the referenced files into the package, under `img/`, `audio/`, and `video/`. A
  missing file is reported, never silently dropped. Where the target format needs `alt` text the
  source lacks, write it from context and mark it ⚑.
- **Throwaway code is fine.** For binary formats, write a short script in a temporary directory,
  using only the Python standard library where possible. Don't leave it in the user's project.
- For a large source, convert a sample of about five cards first, show it to the user, and then do
  the rest.

## 4. Validate (when the target is OFC)

Fetch the normative schema verbatim:

```bash
curl -fsSL https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json
```

Use a shell fetch so you get the file exactly as published. Without a shell, use your web-fetch
tool and ask it for the raw contents. Check every card against it, using `references/spec-rules.md`
as the guide, then the prose rules in its section 6. Fix conversion mistakes and check again. If the
schema can't be fetched, check against the bundled checklist and say so.

When exporting **from** OFC, read the source deck with the same rules first. Report source errors
before converting, so they aren't blamed on the conversion.

## 5. Report

- Output path(s), and the count of cards in and cards out. When they differ, explain why: "212
  notes → 247 cards: 31 reversed notes and 4 multi-cloze notes expanded."
- A **lossy** section listing each thing that didn't survive, with the affected card ids. Examples:
  "8 image-occlusion notes skipped", "hints appended to the front, since Quizlet has no hint
  field", "study history dropped".
- Items marked ⚑ for human review.
- An offer to review card quality. Conversions often surface cards that break the one-fact rule or
  are ambiguous. Offer this; don't do it unasked.
