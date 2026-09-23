---
name: ofc-author
description: Create flashcard decks in the Open Flashcard Standard (OFC) format (.ofc.json, deck folders, .ofc archives) from notes, documents, PDFs, web pages, source code, transcripts, or just a topic. Writes atomic, unambiguous cards using the right block types (text, cloze, choice, code, latex, mermaid, image, audio) and checks the result against the normative schema before saving. Use when the user asks to make flashcards, study cards, a flashcard deck, or an OFC / .ofc.json file, or to turn material into something they can memorise.
license: Apache-2.0
compatibility: Fetches the normative schema from raw.githubusercontent.com. Without network access it falls back to a bundled v1.0.0 checklist and says so.
metadata:
  author: open-flashcard
  version: "1.0.0"
  ofc-spec: "1.0.0"
allowed-tools: Bash(curl -fsSL https://raw.githubusercontent.com/open-flashcard/*)
---

# Author an Open Flashcard deck

You are writing a deck in the Open Flashcard Standard: one JSON object per deck, where each card
has a `front`, and optionally a `back`, `hint`, and `notes`. Each of those is an ordered array of
content blocks.

Two references ship with this skill. Read both before you write any cards:

- [references/card-quality.md](references/card-quality.md): how to write cards that are worth
  studying (rules Q1–Q14). Follow them; they are not optional style advice.
- [references/spec-rules.md](references/spec-rules.md): what makes a deck valid.

## 1. Settle the inputs

Infer what you can from the request and the material. Ask for everything else **in one message**,
never one question at a time.

1. **Material and scope.** What to cover, and roughly how many cards. By default, write one card per
   fact that is worth remembering; don't pad and don't compress.
2. **Packaging.** Always ask. Offer:
   - `<slug>.ofc.json`: a single file, good for git. Media must be `https:` URLs or `data:` URIs.
   - `<slug>/deck.json` plus media files: a folder, good for continued editing.
   - `<slug>.ofc`: that folder as a Zip, good for sharing one file.
3. **Deck id.** `urn:ofc:deck:<publisher>/<slug>`. Ask for the publisher handle if you don't know
   it. Use an `https:` id only on a domain the user says they control.
4. **Languages.** The language being studied and the language of explanations. This sets deck
   `lang` and per-block `lang` (rule Q12).
5. **Directions** (vocabulary and term decks). Both directions by default for language decks (Q8).
6. **Publishing.** If the deck will be shared, ask for `license` and `authors`. Otherwise leave them
   out rather than guessing.

## 2. Plan before writing

Extract the facts worth remembering from the material. Group them into topics; the topics become
tags (Q14).

For more than 20 cards, show the user the outline (topics, planned card count, and which card
styles you'll use) and get a go-ahead before writing them all.

## 3. Write the cards

For each fact, pick the form:

- **A fact inside a sentence** → one-sided card with a single `cloze` block (Q5).
- **A question with a short answer** → `front` question, `back` answer (Q2, Q3).
- **Distinguishing between confusable options, or practice for a multiple-choice exam** → `choice`
  (Q6).
- **Vocabulary** → the term on the front with `speech`, the translation on the back, plus a reverse
  card (Q8, Q12).
- **Visual subjects** → an `image` on the front or back (Q9, Q11).

Choose blocks with the Q10 table. Put explanations in `notes`, and cues in `hint`. Give each card a
short readable `id` slug. The skeleton, with keys in the order to emit them:

```json
{
  "$schema": "https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json",
  "openflashcard": "1.0.0",
  "id": "urn:ofc:deck:<publisher>/<slug>",
  "name": "<Title>",
  "description": "<One or two sentences>",
  "lang": "<bcp-47>",
  "tags": [],
  "created": "<RFC 3339, e.g. 2026-09-23T10:00:00Z>",
  "cards": [
    {
      "id": "<slug>",
      "tags": ["<topic>"],
      "front": [{ "type": "text", "text": "<prompt>" }],
      "back": [{ "type": "text", "text": "<answer>" }],
      "hint": [{ "type": "text", "text": "<optional cue>" }],
      "notes": [{ "type": "markdown", "text": "<optional explanation>" }]
    }
  ]
}
```

Omit every optional field you have nothing to put in. Empty sides are invalid, so a card with no
hint has no `hint` key at all. Deck keys go in this order: `$schema`, `openflashcard`, `id`, `name`,
`description`, `version`, `lang`, `dir`, `authors`, `license`, `homepage`, `source`, `cover`, `tags`,
`created`, `updated`, `cards`. Card keys go: `id`, `tags`, `lang`, `dir`, `front`, `back`, `hint`,
`notes`, `created`, `updated`. Blocks start with `type`.

Worked examples of every common card style are in [references/examples.md](references/examples.md).

**Media.** Never invent a URL. Only reference files the user gave you, files you place in the
package, or URLs you have checked resolve. For the folder and archive packagings, copy media into
`img/`, `audio/`, and `video/`, and reference them relatively. For a bare `.ofc.json`, use the
verified `https:` URL, or a `data:` URI if the file is small (under about 100 KB).

## 4. Check it against the standard

Fetch the normative schema, verbatim:

```bash
curl -fsSL https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json
```

Use a shell fetch so you get the file exactly as published. Without a shell, use your web-fetch
tool and ask it for the raw file contents. Walk the deck against the schema using
`references/spec-rules.md` as the guide to reading it: every card, every block, nothing sampled.
Then check the section 6 prose rules in that file. Fix anything that fails, and re-check what you
changed.

If the schema can't be fetched, check against `references/spec-rules.md` alone. Tell the user the
deck was checked against the bundled v1.0.0 checklist, not the live schema.

## 5. Save and report

- Write 2-space-indented JSON with a trailing newline, in UTF-8 without a BOM.
- Folder packaging: `<slug>/deck.json` with media beside it. Archive packaging: build the folder,
  then zip its *contents* so that `deck.json` sits at the archive root
  (`cd <slug> && zip -r ../<slug>.ofc .`).
- Do not paste the deck into the chat. Report:
  - the path
  - the card count, by style
  - the tags
  - how validation went, and against which schema (live or bundled)
  - anything you wrote that a human should check. Mark those items ⚑. Examples are alt text you
    wrote for an image you could not see, and facts you were unsure of.

## Editing an existing deck

The same rules apply, plus these:

- Never change the deck `id` (§5.1).
- Never rename existing card or block ids.
- Keep every `x-` property you didn't write.
- Append new cards rather than reordering existing ones.
- Set `updated` to now.
- If the user wants a separate deck based on this one (a fork), mint a new deck `id`.
