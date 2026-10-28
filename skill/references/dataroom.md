# Dataroom format

A dataroom is a directory of Markdown and JSON Lines files. People read the
Markdown files; `scripts/dataroom.py` writes and checks the structured ones.
Create one with `dataroom.py init PATH --title TITLE`.

```
PATH/
  BRIEF.md          the user's instructions; sealed, never edited by the loop
  SCRATCHPAD.md     working memory, rewritten every iteration (under 12 KB)
  loop.json         machine state
  sources.jsonl     one record per source opened
  findings.jsonl    one record per material claim
  log.md            one line per iteration
  backlog.md        parked leads with their reasons
  notes/            long notes, translations, profiles of public work
  artifacts/        saved extracts, tables, downloaded text
  reports/          the synthesis written when the loop closes
```

## Commands

The `dataroom.py` helper has the following commands:

- `init PATH [--title T] [--max-iterations N] [--until YYYY-MM-DD]`: create the
  dataroom from the templates. It refuses to overwrite an existing one.
- `seal PATH [--host H] [--schedule HANDLE]`: record the hash of `BRIEF.md` and
  set the status to `running`. Run it again after the user changes the brief.
- `add-source PATH --json '{...}'`: validate and append a source. It prints the
  new id, or the existing id followed by `duplicate`.
- `add-finding PATH --json '{...}'`: validate and append a finding and print
  its id.
- `log PATH --summary "..."`: close an iteration. It refuses if the brief
  changed, increments the counter, appends to `log.md`, and prints the status.
- `status PATH [--json]`: print counts, budget, saturation, and `STOP` or
  `continue`.
- `finish PATH`: set the status to `done` after the synthesis is written.
- `check PATH [--json]`: validate everything. It exits with status 1 on errors
  and prints warnings for anything that needs a look.

## Source records

Each line of `sources.jsonl` is one JSON object:

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | assigned | `S0001`, `S0002`, and so on. |
| `url` | yes | The page opened. Duplicates are detected after normalizing the URL. |
| `title` | yes | The page's own title. |
| `kind` | yes | `primary`, `paper`, `dataset`, `filing`, `patent`, `government`, `analysis`, `essay`, `news`, `social`, `profile`, `aggregator`, `search-engine`, or `other`. |
| `rating` | yes | 1 to 5 against the brief's rubric. |
| `why` | yes | One line: what makes it valuable, or why it is suspicious. |
| `status` | yes | `read`, `skimmed`, `unreachable`, or `suspicious`. Defaults to `read`. |
| `author` | no | Person or organization. |
| `published` | no | `YYYY-MM-DD` or null. |
| `found` | assigned | Date recorded. |
| `iteration` | assigned | The iteration that recorded it. |
| `via` | no | The source id, seed, or search query that led here. |
| `language` | no | Language code, such as `zh`. |
| `note` | no | Path of a note in `notes/` about this source. |

Example:

```json
{"url": "https://example.com/report.pdf", "title": "Regional pilot project list", "kind": "government", "rating": 5, "why": "143 named projects with concrete technical problems", "status": "read", "via": "S0004", "language": "zh", "note": "notes/regional-pilot-list.md"}
```

## Finding records

Each line of `findings.jsonl` is one JSON object:

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | assigned | `F0001`, `F0002`, and so on. |
| `claim` | yes | One sentence in your own words. |
| `label` | yes | `verified`, `source_claim`, `inference`, or `conflict`. |
| `sources` | yes | List of source ids. A `verified` finding needs at least one source with status `read`. |
| `note` | no | Path of a longer note. |
| `date` | assigned | Date recorded. |
| `iteration` | assigned | The iteration that recorded it. |

## Scratchpad

`SCRATCHPAD.md` must keep these headings, in this order:

- `## Objective`
- `## Current state`
- `## Ranked leads` (at most 12)
- `## Deprioritized` (at most 10)
- `## Open questions`
- `## Next actions` (one to three)

Use `YYYY-MM-DD` dates, never "today" or "last week": the next iteration runs at
a different time and may run in a different session.

## Checks

`check` reports these errors:

- a required file or directory is missing;
- `BRIEF.md` changed since it was sealed;
- a record is not valid JSON, lacks a required field, or has a value outside
  its allowed set;
- two sources share an id or a normalized URL;
- a finding cites a source id that does not exist;
- the scratchpad lacks a required heading or exceeds 12 KB.

It warns about these:

- text in the scratchpad or a finding that reads like an injected instruction;
- relative dates in the scratchpad;
- sources marked `suspicious`, so they reach the next report;
- an iteration count that does not match `log.md`.

## Stop advice

`status` prints `STOP` when the status is `done`, the iteration budget is used,
the `until` date has passed, or the loop is saturated. Saturation means that the
last five iterations added no source rated 4 or higher; change `window` and
`min_rating` under `saturation` in `loop.json` to tune it.
