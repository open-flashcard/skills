# Anki ↔ Open Flashcard

## Reading Anki

### Which input you have

| Input                                     | How to read it                                                                                                                                   |
|-------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `.txt` from *Export → Notes in Plain Text* | Tab-separated rows. Leading `#key:value` header lines (`#separator:tab`, `#html:true`, `#notetype column:N`, `#deck column:N`, `#tags column:N`, `#guid column:N`) say what each column is. Easiest input; no media. |
| `.apkg` / `.colpkg` containing `collection.anki2` or `collection.anki21` | A Zip. The collection is a SQLite database; read it with Python's `sqlite3`. A file named `media` is JSON mapping zip entry names (`"0"`, `"1"`, …) to real filenames. |
| `.apkg` / `.colpkg` containing `collection.anki21b` | Newer format. The database **and every media file** are zstd-compressed, and the `media` map is protobuf. Decompress the database with `zstd -d`. If that fails, or the media is needed, ask the user to re-export with **"Support older Anki versions"** ticked, or to use the plain-text export for text-only decks. |

In a newer package, a `collection.anki2` sitting next to `collection.anki21b` is a stub that only
says "please update Anki". Ignore it.

### Database tables (legacy schema)

- `col.models`: JSON, keyed by note-type id. Each note type has `name`, `type` (`0` = standard,
  `1` = cloze), `flds` (a list of `{name, ord}`), and `tmpls` (a list of `{name, ord, qfmt, afmt}`).
- `col.decks`: JSON, keyed by deck id → `{name}`. Nested decks are named `Parent::Child`.
- `notes`: `id`, `guid`, `mid` (note type), `tags` (space-separated, padded with spaces), and `flds`
  (field values joined by `\x1f`).
- `cards`: `id`, `nid` (note), `did` (deck), `ord` (which template, or which cloze number minus 1).

If `col.models` is empty, the collection uses the newer schema. Read note-type names from
`notetypes`, field names from `fields` (`ntid`, `ord`, `name`), and template names from
`templates`. Template HTML is inside a protobuf blob, so infer the mapping from the note-type and
field names, and confirm it with the user.

**Generate one OFC card per row of `cards`**, not per note. That way reversed and optional-reverse
note types expand exactly as Anki expanded them.

### Mapping note types

| Anki note type                     | OFC                                                                                                                          |
|------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| Basic                              | `front` ← Front, `back` ← Back                                                                                               |
| Basic (and reversed card)          | Two cards: `ord 0` as Basic; `ord 1` with the fields swapped, id suffixed `-rev`                                             |
| Basic (optional reversed card)     | As above; the reverse exists only where Anki created a card for it                                                           |
| Basic (type in the answer)         | As Basic. OFC has no typed answers, so report it as lossy                                                                    |
| Cloze                              | One card per cloze number. In card *N*: `{{cN::ans::hint}}` → `{{ans\|hint}}`; every other `{{cM::ans}}` → plain `ans`. `Back Extra` → `notes`. No `back`. |
| Image Occlusion                    | Skip, and list the notes as lossy (OFC has no occlusion block)                                                               |
| Any other                          | Read `qfmt`/`afmt`. `{{Field}}` placeholders in `qfmt` → `front`. `afmt` minus `{{FrontSide}}` and the `<hr id=answer>` → `back`. Confirm the mapping with the user on two sample cards. |

A cloze answer containing `{`, `}`, or `|` cannot be an OFC blank: `|` would be read as the start of
a hint. Leave the text unblanked and report the card.

### Mapping field HTML to blocks

Split each field into blocks, in order:

| Anki field content                                  | OFC block                                                                  |
|-----------------------------------------------------|----------------------------------------------------------------------------|
| Plain text (entities decoded, `<br>` → newline)     | `text`                                                                     |
| Simple formatting: `b`, `i`, `u`, `a`, `ul`/`ol`, `code` | `markdown`, converted                                                 |
| Tables, coloured spans, anything else               | `html`, kept as-is                                                         |
| `<img src="f.jpg">`                                  | `image`, `src: "img/f.jpg"`. `alt` from the tag; if it has none, write it from context and mark ⚑ |
| `[sound:f.mp3]`                                     | `audio`, `src: "audio/f.mp3"`. A video extension (`.mp4`, `.webm`) → `video` |
| `\( … \)` or `[$] … [/$]`                           | `latex`, `display: "inline"`                                               |
| `\[ … \]`, `[$$] … [/$$]`, or `[latex] … [/latex]` | `latex`, `display: "block"`                                                |
| `<pre><code>` blocks                                | `code`. Guess `syntax` only when it is obvious                             |

Deck names (`Languages::Spanish::Verbs`) → a card tag (`languages/spanish/verbs`). Anki tags: `::`
→ `/`. Put the note id and guid on each card as `x-anki-note-id` and `x-anki-guid`. Card ids are
`anki-<note id>`, plus `-c<N>` for cloze card *N* or `-rev` for a reverse card.

Drop everything in `cards` and `revlog` apart from `nid`, `did`, and `ord`: intervals, due dates,
ease, lapses, flags, suspension, and review history.

## Writing Anki

Produce a plain-text import file that Anki reads with **File → Import**:

```
#separator:tab
#html:true
#notetype column:1
#deck column:2
#tags column:5
Basic	Spanish	<span lang="es">mariposa</span>	butterfly	spanish::animals
Cloze	Biology	ATP is mostly produced in the {{c1::mitochondria::organelle}}.		biology::cell
```

Columns: note type, deck, field 1, field 2, tags. Use **Basic** for Q&A cards (Front, Back). Use
**Cloze** for cloze cards (Text, Back Extra). OFC reverse cards are already separate cards, so don't
use a reversed note type.

Field text rules, which avoid Anki's quoting rules altogether: escape `&`, `<`, `>`, and `"` as HTML
entities, turn newlines into `<br>`, and turn tabs into `&#9;`.

| OFC                          | Anki field HTML                                                                                     |
|------------------------------|------------------------------------------------------------------------------------------------------|
| `text`                       | Escaped text. `style` → `<h1>`–`<h3>`, `<b>`, `<i>`, `<blockquote>`, `<small>`                      |
| `markdown`                   | Rendered to HTML                                                                                     |
| `html`                       | As-is                                                                                                |
| `latex`                      | `\(…\)` if inline, `\[…\]` if block                                                                 |
| `code`                       | `<pre><code>…</code></pre>`, escaped                                                                 |
| `mermaid`                    | `<pre>` with the source, plus the `alt` as a paragraph. Lossy: Anki does not render Mermaid          |
| `image`                      | `<img src="<flat name>" alt="…">`                                                                    |
| `audio`, local `video`       | `[sound:<flat name>]`                                                                                |
| Remote `video`, `embed`, `link` | `<a href="…">title or text</a>`, then the `fallback` or `caption`                                 |
| `list`                       | `<ul>` or `<ol start>`                                                                               |
| `choice`                     | Front: the question, then `<ol type="A">` of options. Back: the correct letter(s), the option content, and the `explanation`. Lossy: shuffle and per-option feedback |
| `cloze`                      | **Every** blank → `{{c1::answer::hint}}`, all numbered `c1`, so they hide together as OFC intends. `\{\{` → `{{` |
| `custom`                     | Its `fallback`                                                                                       |
| `lang` / `dir` on a block    | Wrap in `<span lang="…" dir="…">`                                                                    |
| `hint` side                  | Append to the front: `<details><summary>Hint</summary>…</details>`                                  |
| `notes` side                 | Append to the back after `<hr>` (for Cloze, put it in Back Extra)                                    |
| `speech`                     | Dropped. Anki's TTS is set in templates. Report it as lossy                                          |
| Card `tags`                  | `/` → `::`, spaces → `_`                                                                             |

**Media.** Anki's media folder is flat, so rename each file to `<deck-slug>-<basename>` to avoid
collisions. Copy the files, or tell the user to copy them, into their profile's
`collection.media` folder:

- macOS: `~/Library/Application Support/Anki2/<Profile>/collection.media`
- Windows: `%APPDATA%\Anki2\<Profile>\collection.media`
- Linux: `~/.local/share/Anki2/<Profile>/collection.media`

If the user wants a single `.apkg` instead, offer to build one with the `genanki` Python package.
Ask before installing it.
