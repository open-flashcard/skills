---
name: ofc-validate
description: Validate and repair Open Flashcard Standard (OFC) decks (.ofc.json files, deck.json folders, .ofc archives) against the normative JSON Schema and specification. Reports every violation with its JSON path and spec section, fixes mechanical errors, migrates pre-1.0 draft decks (sides[], tts blocks, {{c1::}} cloze, multiple-choice with correct ids, base64 media) to 1.0.0, and marks judgement fixes for human review. Use when the user asks whether a deck is valid or conformant, hits a validation error, or wants a deck fixed or upgraded.
license: Apache-2.0
compatibility: Fetches the normative schema from raw.githubusercontent.com. Without network access it falls back to a bundled v1.0.0 checklist and says so. Reading .ofc archives needs unzip.
metadata:
  author: open-flashcard
  version: "1.0.0"
  ofc-spec: "1.0.0"
allowed-tools: Bash(curl -fsSL https://raw.githubusercontent.com/open-flashcard/*) Bash(unzip -l *)
---

# Validate (and fix) an Open Flashcard deck

You are the validator. There is no validation script: read the normative schema and check the
deck against it yourself, exhaustively. [references/spec-rules.md](references/spec-rules.md)
condenses every rule in the order you should check them. Read it first.

## 1. Load the deck

- **`.ofc.json` / `.json`**: read the file.
- **Folder**: read `<folder>/deck.json`, and note which media files exist beside it.
- **`.ofc` archive**: list the entries first (`unzip -l`). If any entry name is absolute or
  contains `..`, report it as an error and **do not extract**. Otherwise extract into a temporary
  directory and continue as for a folder. Check that `deck.json` is at the archive root.

If the file is not valid JSON, report the parser's line and column, and stop unless the user asked
for fixes. A byte order mark at the start of the file is an error (§3.1).

## 2. Decide what to check against

Read `openflashcard`:

- **`1.x.y`**: fetch that version's schema:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v<x.y.z>/schema.json
  ```
  Use a shell fetch so you get the file exactly as published. Without a shell, use your web-fetch
  tool and ask it for the raw contents. If that version's file does not exist, fetch `v1.0.0`
  instead. Report block types or fields the older schema doesn't know as **warnings** ("unknown to
  1.0.0; may be valid in <x.y>"), not errors (§9).
- **Major version other than 1**: report "unsupported major version" and stop. Do not attempt a
  partial read (§3.2).
- **Missing**: this is probably a pre-1.0 draft deck. Report it, then see section 7 of
  `references/spec-rules.md`.

If nothing can be fetched, check against `references/spec-rules.md` alone. Label the result
"checked against the bundled v1.0.0 checklist; the live schema could not be fetched".

## 3. Check everything

Walk the deck top-down: document, deck fields, then every card and every side, block, list item,
choice option, and nested block, recursing through `list.items`, `choice.options[].content`,
`feedback`, and `explanation`. For every object check:

1. required fields are present
2. no fields outside the allowed set, except `x-*` (§0 of the rules file: blocks are per-type)
3. types, enums, patterns, lengths, numeric ranges
4. "exactly one of `text` / `src`" on `markdown`, `html`, `latex`, `code`, `mermaid`

Then check the prose rules in section 6 of the rules file: `lang` coverage, relative paths in bare
files, sibling id uniqueness, `video` versus `embed`, fallbacks, and path traversal. For folders and
archives, also confirm that every relative `src`, `poster`, `thumbnail`, and `cover.src` names a file
that exists.

Do not sample. On a large deck, work through the cards in order, keep running counts, and finish
the pass. For decks over a few hundred cards, you can mention that the user can run an independent
machine check with `npx ajv-cli validate --spec=draft2020 -c ajv-formats -s schema.json -d deck.json`.

## 4. Report

```
spanish.ofc.json — INVALID · 3 errors, 2 warnings · checked against live schema v1.0.0

Errors
 1. /cards/4/back/1          image is missing required `alt`                         §6.7
 2. /cards/9/front/0         `speech` is not allowed on `html` blocks                §6.3
 3. /cards/12/front/0/src    YouTube page URL in a `video` block; must be `embed`    §6.9

Warnings
 1. /cards/2/notes/0         mermaid block has no `alt`                              §6.6
 2. /cards/7/back/0          block is in English but the deck `lang` is "es"; add `lang: "en"`  §7.3
```

- Group repeated violations of the same rule: "`alt` missing on 14 images: /cards/4/back/1,
  /cards/6/front/1, …", listing every path.
- A deck with no errors is **VALID**, even if it has warnings.
- End with one line that says what you can fix automatically and what needs a human.

## 5. Fix (when asked)

Apply fixes only if the user asked for them ("fix it", "make it valid", "upgrade it"), or after
they say yes to your offer.

**Mechanical fixes**: apply them and list each one.

- move block fields to the correct shape (for example, remove `speech` from `html`)
- normalise the case of enum values (`"H1"` → `"h1"`, `"RTL"` → `"rtl"`) and of `syntax` and
  `provider` slugs
- pad timestamps to full RFC 3339 (`2026-09-23` → `2026-09-23T00:00:00Z`)
- `video` holding a provider page URL → `embed` with the `provider` slug
- remove duplicate tags
- set missing `openflashcard`
- draft-era migrations from section 7 of the rules file

**Judgement fixes**: apply them, mark each with ⚑ in the report, and ask the user to check.

- writing `alt` text, `embed` or `custom` fallbacks, or `mermaid` alt
- choosing a `lang` tag
- choosing a deck `id` for a deck that has none. Ask for the publisher handle rather than inventing
  one.

**Never:**

- change an existing deck `id`
- rename card or block ids (for a duplicate id, rename only the later one and report it)
- delete content or `x-` properties
- reorder cards

If a fix would lose information (for example, scheduling fields on a card), move that data into an
`x-` property (`x-legacy-due`), or ask the user.

Write the result back with the original indentation and key order, UTF-8, and a trailing newline.
For archives, rebuild the Zip with `deck.json` at the root. Then **validate again from step 3**, and
repeat until the deck has no errors. Finish with a before/after summary: the error count, and every
fix grouped as mechanical or ⚑.
