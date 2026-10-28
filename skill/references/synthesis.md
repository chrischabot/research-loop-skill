# Writing the synthesis

The synthesis turns the dataroom into something a newcomer can read in an hour.
Write it into `reports/` when the loop closes, and whenever the user asks for an
interim report.

## Prepare

1. Run `dataroom.py status PATH --json` and `dataroom.py check PATH`.
2. Read `findings.jsonl` and every source rated 4 or 5. Reopen any source whose
   claim carries weight in the conclusion and that you have not read in the
   current session.
3. Spend one pass looking for evidence against the main conclusion if no
   iteration did.

## Write `reports/overview.md`

Use the smallest structure that serves the brief's deliverables, normally:

1. **The short answer**: what the field looks like, in a paragraph, with your
   confidence.
2. **Where to start reading**: the 10 to 25 best sources, in reading order, each
   with one line on why. These are the rare finds the loop exists to surface.
3. **The people and organizations**: who is doing the work, through their
   public, professional output.
4. **Disagreements**: where credible sources conflict, and what would settle it.
5. **What surprised the loop**: where it ended up that the seeds did not
   predict.
6. **Gaps**: what the loop could not reach, and sources marked `suspicious`.

Cite sources inline with their links. Label claims the way `findings.jsonl`
does: say plainly what is verified, what a source claims, what is your
inference, and what is disputed. Do not cite anything the loop did not open.

## Optional outputs

Produce these when the brief asks for them:

- `reports/reading-map.md`: sources grouped by question, with a path through
  them.
- `reports/walkthrough.md`: a beginner's guide in short chapters with a
  glossary, built only from the dataroom.
- `reports/landscape.md`: a table of organizations, projects, or vendors.
