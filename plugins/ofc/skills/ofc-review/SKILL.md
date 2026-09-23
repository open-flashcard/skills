---
name: ofc-review
description: Review an Open Flashcard Standard (OFC) deck (.ofc.json, deck folder, or .ofc archive) for learning quality, accessibility, and correct use of the standard. Finds cards that pack in several facts, prompts with more than one right answer, overloaded answers, list-memorisation cards, weak multiple-choice distractors, prompts that give the answer away, missing alt text, transcripts or language tags, and misused block types, then proposes concrete JSON rewrites. Use when the user asks to review, critique, audit, improve, or clean up a flashcard deck.
license: Apache-2.0
compatibility: Fetches the normative schema from raw.githubusercontent.com. Without network access it falls back to a bundled v1.0.0 checklist and says so.
metadata:
  author: open-flashcard
  version: "1.0.0"
  ofc-spec: "1.0.0"
allowed-tools: Bash(curl -fsSL https://raw.githubusercontent.com/open-flashcard/*) Bash(unzip -l *)
---

# Review an Open Flashcard deck

Judge the deck the way a learner will experience it, card by card. The rubric is
[references/card-quality.md](references/card-quality.md) (rules Q1–Q14). Read it first. What makes
a deck valid is in [references/spec-rules.md](references/spec-rules.md).

A review **proposes** changes. Don't edit the deck until the user says which changes to apply.

## 1. Read the deck

Load it. For a folder, read `deck.json`. For an archive, check the entries with `unzip -l` before
extracting. Note the deck's languages, subject, and apparent audience, because they change what
"good" means. An exam-prep deck earns more `choice` cards. A beginner language deck needs
`speech` on its vocabulary.

## 2. Validity first, briefly

Fetch the normative schema verbatim:

```bash
curl -fsSL https://raw.githubusercontent.com/open-flashcard/schema/main/versions/v1.0.0/schema.json
```

Use a shell fetch so you get the file exactly as published. Without a shell, use your web-fetch
tool and ask it for the raw contents. Check the deck against it, using the rules file as the guide.
If the schema can't be fetched, use the bundled checklist and say so.

Spec errors go at the top of the report as their own section: path, problem, and spec section.
They block publishing, but they don't stop the review.

## 3. Review every card

Go through every card. For each one, check:

- **Formulation**: Q1 one fact; Q2 one right answer; Q3 short answer; Q4 no sets; Q7 no yes/no;
  Q9 no giveaways.
- **Form**: Q5 cloze use; Q6 choice quality; Q8 directions; Q10 block choice.
- **Accessibility and language**: Q11 images, Q12 `lang` and `speech`, Q13 alt text, transcripts,
  and fallbacks.
- **Deck level**: Q14 tags, ids, source, and licence. Also look for duplicate or near-duplicate
  cards, and topic gaps the deck's own title implies it should cover.

Flag **factual** problems only when you are confident, and keep them in a separate "Check these
facts" section with a one-line reason each. Don't restyle cards that already follow the rules. If a
card is fine, say nothing about it.

## 4. Report

Order findings by impact on the learner:

1. Wrong or ambiguous cards
2. Non-atomic cards
3. Missing accessibility
4. Everything else

```
Review: Spanish Core (212 cards) — 41 cards with findings

Spec errors (2)            … path · problem · §
Check these facts (1)      /cards/88  "Ser is used for location" — location uses estar

By rule                    Q1 ×12 · Q2 ×7 · Q8 ×9 · Q12 ×6 · Q13 ×5 · Q6 ×2

Findings
#1  cards/14  "ser-vs-estar"  Q1 — the back holds three separate uses
    Proposed: split into 3 cards
    { "id": "ser-vs-estar", "front": … }
    { "id": "ser-vs-estar-2", "front": … }
    { "id": "ser-vs-estar-3", "front": … }
```

- Number the findings so the user can reply "apply 1–5 and 9".
- For each finding, show only the JSON that changes: the rewritten card or cards, or the one field.
  Don't reprint the whole deck.
- When a rule is broken across many cards the same way (for example, 30 vocabulary cards without
  `speech`), make it one finding with a bulk fix and a list of the affected card ids.
- End with the three changes that would help most, in one line each.

## 5. Apply (after the user chooses)

- Apply exactly what the user chose, as rewritten in the report.
- **Splitting a card:** the first new card keeps the original `id`, and the rest get `<id>-2`,
  `<id>-3`, and so on. Reverse cards get `<id>-rev`.
- Never change the deck `id` or rename existing ids. Keep every `x-` property. Keep card order, and
  insert split-off cards directly after their original.
- Set `updated` on each changed card and on the deck, to the current RFC 3339 time.
- Validate again after applying. Report the new card count and anything marked ⚑: alt text you
  wrote for an image you could not see, and facts you rewrote.
