# Open Flashcard Standard 1.0.0 — rules checklist

A condensed snapshot of every rule in the v1.0.0 schema and specification, ordered for checking a
deck top-down. **The live `schema.json` is normative.** Fetch it (URLs below) and treat this file as
a guide to reading it; if the two ever disagree, the schema wins and this file is stale.

- Schema: `https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json`
- Spec:   `https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.md`

For a deck declaring another `1.x.y`, replace `v1.0.0` in both URLs with `v<that version>`.

Cite violations by JSON Pointer (`/cards/4/back/1/alt`) and spec section (`§6.7`).

## 0. Closed world

Every object rejects properties it does not define, **except** names starting with `x-`, which are
allowed anywhere and never validated. One exception: `cover` accepts no `x-` properties either.

Block properties are **per type**. A field that is valid on one block type is invalid on another:
`speech` on `html`, `alt` on `audio`, `caption` on `embed`, `syntax` on `markdown` are all errors.

## 1. Document (§3)

- UTF-8, no byte order mark, a single JSON object.
- Bare document: `<name>.ofc.json`. Package folder: `<name>/deck.json`. Archive: `<name>.ofc`
  (Zip with `deck.json` at the archive root, no absolute or `..` entry names).
- In a **bare** `.ofc.json`, every `src`, `poster`, `thumbnail`, `cover.src` MUST be an absolute
  URL or a `data:` URI — there is no folder for a relative path to resolve against.
- In a package, relative paths resolve against the package root and MUST NOT escape it.

## 2. Deck object (§4.1)

| Field           | Rule                                                                           |
|-----------------|--------------------------------------------------------------------------------|
| `openflashcard` | **Required.** Matches `^1\.[0-9]+\.[0-9]+$`. Major ≠ 1 → unsupported, stop.    |
| `id`            | **Required.** Absolute URI: `^[A-Za-z][A-Za-z0-9+.\-]*:[^\s]+$`, 3–2048 chars. |
| `name`          | **Required.** String, 1–300 chars.                                             |
| `cards`         | **Required.** Array of cards; MAY be empty.                                    |
| `$schema`       | Optional string. Informative only.                                             |
| `description`   | ≤ 5000 chars.                                                                  |
| `version`       | ≤ 64 chars. The author's deck version, unrelated to `openflashcard`.           |
| `lang` / `dir`  | See §4 of this file.                                                           |
| `authors`       | Array of `{ name (1–200, required), email? (≤320), url? (≤2048), x-* }`.       |
| `license`       | ≤ 300 chars. SPDX id (`CC-BY-4.0`) or a license URL.                           |
| `homepage`      | 1–2048 chars.                                                                  |
| `source`        | ≤ 2000 chars. Free-text attribution.                                           |
| `cover`         | `{ src (required), alt? (≤1000), mediaType?, integrity? }` — no `x-` allowed.  |
| `tags`          | Unique strings, each 1–100 chars.                                              |
| `created`/`updated` | RFC 3339 timestamps (§4 of this file).                                     |

There are no subdecks. Hierarchy is expressed with tags.

Deck `id` guidance: `urn:ofc:deck:<publisher>/<slug>` when the publisher owns no domain,
`https://<their-domain>/…` when they do, `urn:uuid:…` when it need not be readable. **Never change
a deck's `id` when editing its cards; mint a new one when forking into a separate work** (§5.1).

## 3. Card object (§4.2)

| Field                | Rule                                                        |
|----------------------|-------------------------------------------------------------|
| `front`              | **Required.** Side = non-empty array of blocks.             |
| `back`               | Optional side. Absent = one-sided card (valid).             |
| `hint`               | Optional side, revealed on demand before the back.          |
| `notes`              | Optional side, shown with or after the back.                |
| `id`                 | Optional local id (§4). Unique among the deck's cards.      |
| `tags`               | Unique strings, each 1–100 chars.                           |
| `lang` / `dir`       | Override the deck's values.                                 |
| `created`/`updated`  | RFC 3339 timestamps.                                        |

No other card fields exist: `sides`, `type`, `due`, `interval`, `ease`, `reviews` are all errors.
Scheduling and review state are out of scope (§1.2) and may only live in `x-` properties.

## 4. Shared formats (§5)

| Format       | Rule                                                                                              |
|--------------|---------------------------------------------------------------------------------------------------|
| Local `id`   | 1–64 chars, `^[A-Za-z0-9][A-Za-z0-9._~:@-]*$`. Unique among siblings. Stable across edits.         |
| `lang`       | BCP-47, 2–35 chars, `^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$` (`en`, `es-MX`, `zh-Hans`).            |
| `dir`        | `ltr`, `rtl`, or `auto`. Only to override what `lang` implies; prefer a correct `lang`.            |
| Timestamp    | `YYYY-MM-DDTHH:MM:SS[.fff](Z\|±HH:MM)`. Seconds and zone are required: `2026-09-23T10:00:00Z`.    |
| `mediaType`  | `type/subtype`, e.g. `image/png`, ≤ 255 chars.                                                     |
| `integrity`  | `^sha(256\|384\|512)-[A-Za-z0-9+/]+={0,2}$`. There is no bare `base64` field anywhere.             |
| URI ref      | `src`, `href`, `poster`, `thumbnail`: absolute URL, `data:` URI, or relative path. Non-empty.     |

**Producer rule (§7.3):** `lang` MUST be set on the deck, or on every block carrying natural
language. Bilingual decks set `lang` per block for the second language.

## 5. Blocks (§6)

Every block: `type` (**required**, one of the 15 below), and optionally `id`, `lang`, `dir`,
`fallback` (≤ 5000 chars). "text XOR src" means **exactly one** of the two — both or neither is an
error.

| `type`     | Required                       | Optional (type-specific)                                                                                             |
|------------|--------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `text`     | `text` (≤100 000)              | `style`: `normal` `h1` `h2` `h3` `strong` `em` `quote` `small`; `speech`                                            |
| `markdown` | `text` XOR `src`               | `integrity`, `speech`                                                                                                |
| `html`     | `text` XOR `src`               | `integrity`                                                                                                          |
| `latex`    | `text` XOR `src`               | `display`: `block` (default) or `inline`                                                                             |
| `code`     | `text` XOR `src`               | `syntax` (lowercase, `^[a-z0-9][a-z0-9+#._-]*$`, ≤50), `filename` (≤255), `integrity`                              |
| `mermaid`  | `text` XOR `src`               | `alt` (≤1000, SHOULD be present), `theme` (≤50), `integrity`                                                         |
| `image`    | `src`, `alt` (≤1000)           | `caption` (≤2000), `mediaType`, `integrity`, `width`, `height` (integers ≥ 1)                                       |
| `audio`    | `src`                          | `start`, `end` (≥ 0), `controls`, `autoplay`, `loop` (booleans), `caption`, `transcript`, `mediaType`, `integrity` |
| `video`    | `src`                          | as `audio`, plus `poster`, `width`, `height`                                                                         |
| `embed`    | `src` (absolute), `provider`, `fallback` | `thumbnail`, `title` (≤1000), `author` (≤200), `start`, `end`, `width`, `height`                         |
| `list`     | `items` (≥ 1)                  | `marker`: `bullet` (default) `number` `none`; `start` (integer)                                                      |
| `choice`   | `options` (≥ 2, ≥ 1 `correct: true`) | `shuffle` (boolean), `explanation` (non-empty block array)                                                     |
| `cloze`    | `text` with ≥ 1 blank          | `speech`                                                                                                             |
| `link`     | `href`                         | `text` (≤1000), `title` (≤1000)                                                                                      |
| `custom`   | `plugin` (1–200), `fallback`   | `data` (object, opaque)                                                                                              |

Details the table cannot hold:

- **`speech`** (only on `text`, `markdown`, `cloze`): `{ lang?, voice? (≤100), rate? (0.1–4),
  pitch? (0–2), autoplay?, text? (≤5000) }`. `speech.text` only for unpronounceable written forms.
- **`image.alt`**: `""` is allowed and asserts the image is purely decorative. Anything that carries
  information needs real alt text.
- **`video` vs `embed`** (§6.9): a page on YouTube, Vimeo, TikTok, Instagram, X, SoundCloud, CodePen,
  etc. is an `embed`, never a `video`. `video.src` is a direct media file (`.mp4`, `.webm`) or a
  packaged path.
- **`embed.provider`**: lowercase slug `^[a-z0-9][a-z0-9.\-]*$` (≤50). Open list — `youtube`,
  `vimeo`, `instagram`, `x`, `tiktok`, `soundcloud`, … `embed.src` MUST be absolute.
  `embed.fallback` must convey the content, because it is all an offline learner sees.
- **`list.items`**: each item is one block **or** a non-empty array of blocks.
- **`choice` options**: `{ content (required, non-empty block array), correct? (boolean),
  feedback? (non-empty block array), id? }`. Two or more `correct: true` makes it multi-select.
  There is no `correct: [ids]` array on the block.
- **`cloze.text`**: blanks are `{{answer}}` or `{{answer|hint}}`; at least one must match
  `\{\{[^{}]+\}\}`. Blank content MUST NOT contain `{` or `}`. A literal `{{` is written `\{\{` in
  the text — which is `"\\{\\{"` inside a JSON string. There is no `{{c1::…}}` numbering: all blanks
  in one block are concealed and revealed together.
- **`custom.fallback`** must be a genuine substitute for the content, not a placeholder like
  "Custom block".

## 6. Rules the schema cannot check

These are normative prose. Check them by reading, after the schema pass.

1. `lang` set on the deck or every natural-language block (§7.3).
2. Bare `.ofc.json` uses no relative media paths (§3.4).
3. Ids unique among siblings: card ids across `cards`, block ids within a side, option ids within a
   choice (§5.2).
4. No provider page URL in a `video` block (§6.9).
5. `embed` and `custom` fallbacks are real substitutes (§6.10, §6.15).
6. `mermaid` blocks have `alt` (SHOULD, §6.6).
7. Relative paths do not escape the package root (`..`, leading `/`) (§8).
8. Deck `id` unchanged by edits; card and other local ids unchanged by edits (§5.1, §5.2).
9. `x-` properties from other tools preserved when rewriting a deck (§5.5, §7.3).

Severity when reporting: anything in §0–§5 of this file, and items 1–5 and 7 of this section, are
**errors**. Items 6, 8 and 9 are **warnings** unless the user's task makes them errors (for
example, 8 is an error while editing someone else's published deck).

## 7. Migrating pre-1.0 ("draft-era") decks (Appendix C)

A document with no `openflashcard` field, or with any field in the left column, is draft-era.

| Draft construct                              | 1.0.0 replacement                                                                       |
|----------------------------------------------|-----------------------------------------------------------------------------------------|
| `sides[]` with `type: term \| definition`    | `front` = the first side's blocks, `back` = the second's. More than two sides → ask.    |
| `inline` / `file` / `url` source fields      | `text` (inline content) or `src` (file path or URL).                                    |
| `base64` + a separate media type             | `src: "data:<mediaType>;base64,<payload>"`.                                             |
| `tts` block                                  | `speech` object on the `text`/`markdown`/`cloze` block holding the same string.         |
| `"cloze": true` with `{{c1::answer::hint}}`  | `cloze` block with `{{answer\|hint}}`. Distinct `cN` groups → one card per group.       |
| `multiple-choice` with `correct: [ids]`      | `choice` block; `correct: true` on each correct option.                                 |
| `"sanitize": true` on `html`                 | Remove the field — sanitization is mandatory and not configurable.                      |
| Required ULIDs everywhere                    | Keep existing ids (they stay stable); the deck id becomes a URI such as `urn:ofc:deck:…`. |
| `direction: "rtl"`                           | Correct `lang`, plus `dir` only if the language does not imply the direction.           |
| Deck-level `language`                        | `lang` (a BCP-47 tag), set per block where a second language appears.                  |
| `url` block                                  | `link` block with `href`.                                                               |
| `provider` on a `video` block                | `embed` block with the same `provider` and `src`, plus a written `fallback`.            |

After migrating, set `"openflashcard": "1.0.0"` and re-validate from the top.
