# Quizlet, CSV/TSV, and Markdown ↔ Open Flashcard

## Quizlet

Quizlet's export (*⋯ → Export*) and import (*Create → Import*) are both plain text. The user
chooses two separators:

- between term and definition: **Tab** (default), comma, or custom
- between rows: **New line** (default), semicolon, or custom

Quizlet's export contains no images, audio, or study history.

### Quizlet → OFC

1. Ask which separators were used, unless the file makes it obvious. Tabs plus one card per line is
   the default. People with multi-line definitions often chose a custom row separator such as `;;`
   or a blank line. If rows don't split into exactly two parts, stop and ask.
2. For each row: `front` = `[{ "type": "text", "text": term }]` and `back` =
   `[{ "type": "text", "text": definition }]`. Keep inner line breaks.
3. Quizlet sets usually pair two languages. Ask for both, set deck `lang` to the definition
   language, and put `lang` on the term block, or the other way round, whichever matches the set.
4. Card ids are `row-<n>`, 1-based, in file order.
5. Quizlet's "study both sides" is a study-mode setting. It does not create cards. Don't add reverse
   cards unless the user asks.

### OFC → Quizlet

One row per card: `term<TAB>definition`. Flatten each side to plain text:

| OFC                  | Quizlet text                                                                                  |
|----------------------|-----------------------------------------------------------------------------------------------|
| `text`, `markdown`   | The text; Markdown syntax stripped                                                            |
| `code`, `latex`      | The source as-is                                                                              |
| `cloze`              | Term = the sentence with each blank shown as `____`. Definition = the answers, `; `-joined    |
| `choice`             | Term = the question, then `A) … B) …`. Definition = the correct option(s)                     |
| `list`               | Items joined with `; `                                                                        |
| `image`, `audio`, `video`, `embed` | Dropped. Report them; the user can add images by hand in Quizlet                |
| `link`               | `text (href)`                                                                                 |
| `custom`             | Its `fallback`                                                                                |
| `hint`, `notes`      | Dropped by default. Ask whether to append them in parentheses                                 |

Newlines inside a term or definition break the default row separator. Either replace them with
` / `, or tell the user to choose a custom row separator (for example `;;`) and emit that instead.
One-sided cards have no definition: put the flattened content in the term and a single space in the
definition, and report it.

## CSV / TSV

### Spreadsheet → OFC

1. **Sniff the file.** Check the delimiter (`,`, `;`, or tab), RFC 4180 quoting (quoted fields may
   contain delimiters, newlines, and `""`), and whether there is a header row. Strip a UTF-8 BOM,
   and check the encoding; spreadsheet exports are sometimes Windows-1252.
2. **Propose a column mapping** and confirm it with a two-row preview. Map each column to `front`,
   `back`, `hint`, `notes`, `tags`, card `id`, card `lang`, or "ignore". Several columns may feed
   one side, as separate blocks in column order.
3. **Choose the block for each cell.** Plain text → `text`. A cell that clearly contains Markdown
   (`**`, backticks, `- ` bullets, `[x](y)`) → `markdown`. A cell containing HTML tags → `html`.
   A cell whose whole content is an image URL or path → `image`, with alt text written from the
   row and marked ⚑. A cell containing `{{…}}` → `cloze` (convert Anki's `{{c1::…}}` syntax as in
   `anki.md`).
4. **Tags cell.** Split it on whichever of `,`, `;`, or whitespace the file uses consistently.
5. **Card ids.** Use an id column if the file has one, with values sanitised to
   `^[A-Za-z0-9][A-Za-z0-9._~:@-]*$` and duplicates reported. Otherwise use `row-<n>`, counting
   data rows from 1.
6. Skip empty rows. Report rows with an empty front column.

### OFC → Spreadsheet

Columns: `id, front, back, hint, notes, tags`. Tags are `;`-joined. Flatten each side as for
Quizlet, but keep Markdown source as-is and put media as their `src`. Quote per RFC 4180. Default
to comma-separated UTF-8, and ask if the user wants TSV or a BOM for Excel.

## Markdown and Obsidian notes

Before converting, ask which convention the notes use, or detect it:

| Convention                                         | Parse as                                                              |
|----------------------------------------------------|-----------------------------------------------------------------------|
| `Q: …` / `A: …` pairs                              | front / back                                                          |
| A heading followed by its body                     | front = the heading text, back = the body as `markdown`               |
| A definition list, or `**term** — definition`      | front / back                                                          |
| Obsidian Spaced Repetition: `question::answer`     | One card                                                              |
| … `question:::answer`                              | Two cards (reverse suffixed `-rev`)                                   |
| … multi-line, split by a line with only `?`        | One card; the lines above are the front, the lines below the back     |
| … `??` as the separator                            | Two cards                                                             |
| … `==highlight==` or `{{text}}` inside a paragraph | A one-sided `cloze` card. Convert `==x==` to `{{x}}`                 |

For Obsidian, treat `#flashcards` and nested tags such as `#flashcards/biology` as deck tags.
Strip the `#flashcards` prefix; the remainder becomes a card tag (`biology`). Drop the plugin's
scheduling comments (`<!--SR:…-->`).

Card ids are `<note-file-slug>-<n>`. Keep each card's Markdown formatting in a `markdown` block
rather than flattening it to `text`. Embedded images (`![[x.png]]`, `![](x.png)`) become `image`
blocks with the file copied into the package.

OFC → Markdown: write `## <front, flattened>` headings, followed by the back as Markdown. Put
`hint` and `notes` under `> Hint:` and `> Notes:` blockquotes. This direction is for reading, not
round-tripping; say so.
