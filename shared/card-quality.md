# Card quality rules

Opinionated rules for flashcards that are quick to review and hard to get wrong. They draw on
spaced-repetition practice (Wozniak's *20 rules of formulating knowledge*, Matuschak's work on
prompt writing) and apply it to the Open Flashcard block vocabulary.

Cite rules by id (Q1–Q14) in reviews. Every rule states the *signal* that it has been broken, so it
can be checked card by card.

## Q1 — One fact per card

Signal: the answer contains "and", a comma-separated series, or two sentences that could each be
forgotten independently.

Split the card. Tag the pieces together so they stay grouped.

```json
// Before: two facts
{ "front": [{ "type": "text", "text": "What does the mitochondrion do and what is its membrane called?" }],
  "back":  [{ "type": "text", "text": "Produces ATP; it has a double membrane (inner + outer)." }] }

// After: two cards
{ "id": "mito-function", "tags": ["biology/cell"],
  "front": [{ "type": "text", "text": "Main function of the mitochondrion?" }],
  "back":  [{ "type": "text", "text": "Producing ATP (cellular respiration)" }] }
{ "id": "mito-membrane", "tags": ["biology/cell"],
  "front": [{ "type": "text", "text": "How many membranes does a mitochondrion have?" }],
  "back":  [{ "type": "text", "text": "Two — an inner and an outer membrane" }] }
```

## Q2 — Exactly one right answer

Signal: a knowledgeable person could give a different correct answer from the one on the back.

Add the missing context to the prompt: the domain ("In Python 3…"), the scope ("…in the OSI model"),
or the form of answer expected ("…(one word)").

## Q3 — Short answers

Signal: the back takes more than a few seconds to recall, or runs past about one sentence.

Keep the recall target on `back`. Move explanation, derivation, and background to `notes`, which
the learner reads after answering but is not graded on.

## Q4 — Don't make sets into a single card

Signal: "List the…", "Name all…", or an unordered `list` block as the entire answer.

Unordered sets are the hardest thing to memorise. Use one card per member, framed so each has a
single answer ("Which OSI layer handles routing?"). For an **ordered** sequence, use overlapping
cloze cards — each card blanks one item and shows its neighbours. A `list` block is fine in
`notes` as a reference.

## Q5 — Cloze for facts that live in a sentence

Signal: a Q&A card whose prompt is a sentence with a hole, rewritten awkwardly as a question.

Use a one-sided card whose front is a single `cloze` block. Keep it to **one** blank — at most two
blanks that are only meaningful together. All blanks in a block are concealed and revealed
together, so independent facts belong on separate cards. Blank the key term, never filler words.
Use `{{answer|hint}}` when the sentence alone is ambiguous.

```json
{ "front": [{ "type": "cloze", "text": "The {{mitochondria}} is the powerhouse of the cell." }] }
```

## Q6 — Multiple choice sparingly, and done well

Use `choice` when discriminating between easily confused options *is* the skill, or when the
learner is preparing for a multiple-choice exam. Otherwise prefer free recall (Q&A or cloze).

When you do use it:

- give 3–5 options, all plausible and from the same category
- no "all of the above", "none of the above", or joke options
- `shuffle: true` unless the order carries meaning
- an `explanation`, plus per-option `feedback` for distractors that match a common misconception

## Q7 — No yes/no or true/false prompts

Signal: the answer is "Yes", "No", "True", or "False".

A coin flip gets these right half the time. Rephrase so the learner has to produce the fact.

## Q8 — Both directions are two cards

The standard does not generate reverse cards. For vocabulary, and for term ↔ definition pairs where
recall both ways matters, write a second card with front and back swapped. Give it a related id:
`mariposa` and `mariposa-rev`.

Language decks get both directions by default. Concept decks get them only when the user wants
them.

## Q9 — The prompt must not give the answer away

Signal: the prompt contains the answer, its word stem, or an image whose `alt` names it.

Put cues in `hint`, not on the front. On the **front**, image `alt` describes what is visible without
naming the answer ("a small bird with an orange-red breast", not "a robin"), so a screen-reader user
faces the same question as everyone else.

## Q10 — Use the right block

| Content                                 | Block                                                                 |
|-----------------------------------------|-----------------------------------------------------------------------|
| A plain string or word                  | `text` (use `style` for headings and emphasis)                        |
| Formatted prose, inline code, emphasis  | `markdown`                                                            |
| Tables or markup nothing else covers    | `html` — last resort                                                  |
| Maths                                   | `latex` (`display: "inline"` for short expressions)                   |
| Source code                             | `code` with a lowercase `syntax`                                      |
| Diagrams, flows, sequences              | `mermaid` with `alt`                                                  |
| A picture                               | `image` with meaningful `alt`                                         |
| Pronunciation                           | `speech` on the `text` block, or `audio` for recorded speech          |
| A media file the app plays itself       | `video` / `audio`                                                     |
| YouTube, Vimeo, TikTok, Instagram, X…   | `embed` with `provider` and a real `fallback`                         |
| Fill-in-the-blank                       | `cloze`                                                               |
| A reference to read more                | `link`, usually in `notes`                                            |

## Q11 — Pictures where the subject is visual

Anatomy, geography, art, UI, plants, birds, circuit symbols: put an image on the card. Q9 applies to
its `alt` if it sits on the front.

Never invent a media URL. Only reference images the user supplied, files that exist in the package,
or URLs you have verified resolve.

## Q12 — Language on every block that needs it

Set deck `lang` to the most common language. Give every block in another language its own `lang`.
Add `speech` to target-language vocabulary so apps can pronounce it; slow it down
(`"rate": 0.8`) for beginners. A missing `lang` breaks text-to-speech, fonts, and right-to-left
rendering.

## Q13 — Accessible by default

Every `image` has real `alt` (`""` only when it is purely decorative). Every `mermaid` has `alt`.
Every `audio` of speech has a `transcript`. `video` has a `caption` or `transcript`. `embed` and
`custom` fallbacks describe the content itself, not "Video unavailable".

## Q14 — Structure and attribution

Tags describe topics, kept lowercase and consistent, with `/` for hierarchy (`anatomy/heart`) — one
separator per deck. Card ids are short, readable slugs, unique and never renamed. When material
comes from a book, course, or site, set the deck `source` and put a `link` in `notes` pointing to
the exact place. Set `license` and `authors` before a deck is published.
