# Open Flashcard skills

Agent skills for the [Open Flashcard Standard](https://github.com/open-flashcard/schema). With them, Claude
(or any agent that supports [Agent Skills](https://agentskills.io)) can write, check, convert, and review
`.ofc.json` flashcard decks.

| Skill          | What it does                                                                                              |
|----------------|-----------------------------------------------------------------------------------------------------------|
| `ofc-author`   | Turns notes, documents, PDFs, web pages, code, or a topic into a deck of atomic, well-formed cards         |
| `ofc-validate` | Checks a deck against the normative schema, reports each error by path and spec section, fixes it, and migrates draft-era decks |
| `ofc-convert`  | Converts to and from Anki (`.apkg`, `.txt`), Quizlet, CSV/TSV, and Markdown/Obsidian, and reports anything lossy |
| `ofc-review`   | Critiques a deck for learning quality and accessibility, and proposes JSON rewrites                        |

Each skill fetches the normative [`schema.json`](https://github.com/open-flashcard/schema/blob/main/versions/v1.0.0/schema.json)
at runtime. If there is no network access, it falls back to a bundled v1.0.0 checklist and says so.

## Install

### Claude Code (plugin)

```
/plugin marketplace add open-flashcard/skills
/plugin install ofc@open-flashcard
```

Claude uses the skills automatically when you ask it to make, check, convert, or review flashcards. You can
also call them directly: `/ofc:ofc-author`, `/ofc:ofc-validate`, `/ofc:ofc-convert`, `/ofc:ofc-review`.

### A single skill, anywhere Agent Skills are supported

Every folder under [`plugins/ofc/skills/`](plugins/ofc/skills) is a self-contained skill that uses only the
portable Agent Skills frontmatter.

- **Claude Code, without the plugin:** copy the folder to `~/.claude/skills/` (personal) or
  `.claude/skills/` (project). It is then available as `/ofc-author`.
- **claude.ai:** zip the folder (`cd plugins/ofc/skills && zip -r ofc-author.zip ofc-author`) and upload it
  in your skills settings.
- **Other agents:** copy the folder to wherever the agent loads skills from.

## Examples

```
Make flashcards from chapter 3 of ./notes/biology.pdf
Is ./decks/spanish.ofc.json valid? Fix whatever isn't.
Convert my Anki deck ~/Downloads/Japanese.apkg to an .ofc package
Review ./decks/aws-saa.ofc.json. Which cards would trip me up?
```

## Layout

```
.claude-plugin/marketplace.json     marketplace manifest (this repo)
plugins/ofc/
  .claude-plugin/plugin.json        plugin manifest
  skills/<skill>/SKILL.md           instructions
  skills/<skill>/references/        loaded on demand
shared/                             source of truth for references used by several skills
scripts/sync-shared.sh              copies shared/ into each skill (--check for CI)
```

## Contributing

- Edit shared references in `shared/`, never the copies in `references/`, then run `scripts/sync-shared.sh`.
  CI fails if the copies drift.
- When the standard gets a new version, update `shared/spec-rules.md`, the `ofc-spec` metadata in each
  `SKILL.md`, and the schema URLs.
- Bump `version` in `plugins/ofc/.claude-plugin/plugin.json` on every release. Installed plugins only
  update when it changes.
- Before a release: `claude plugin validate --strict .` and `claude plugin validate --strict plugins/ofc`.

## License

Apache-2.0
