# Research loop skill

A skill for coding agents that turns open-ended research into a long-running,
self-steering loop. You give it a few seeds that show what good material looks
like, such as a post that drew experts into the replies, a niche newsletter, or
a government project list. The loop wakes on a schedule, follows one lead
carefully each time, records what it found in a dataroom on disk, and rewrites
its own scratchpad to decide where to look next. When it runs out of budget or
stops finding strong sources, it writes a synthesis: a reading map of the best
sources, the people doing the work, and where they disagree.

It works with Codex, Claude Code, Pi, Cursor, and any agent that can read a
skill and run a Python script.

## When to use it

Use the research loop when you want to get from zero to a working understanding
of an unfamiliar field, and you care about finding the rare, information-dense
sources that a quick search misses. Typical runs last a few hours to a day.

For a defined question that should be answered in one sitting, use a
single-session research skill such as
[deep-research](https://github.com/chrischabot/deep-research-skill) instead.
The two complement each other: the research loop follows deep-research's
evidence rules and, when it's installed, uses deep-research's report rules
for its final overview.

## How it works

Each iteration follows the same steps:

1. Read the brief, the scratchpad, and the end of the log.
2. Take the top next action, which is usually the top-ranked lead. Every fifth
   iteration takes a deprioritized lead instead.
3. Open the actual pages and work through one to three items by hand.
4. Record each source and each material claim through the dataroom helper,
   which assigns ids, rejects duplicates, and enforces claim labels.
5. Add the new leads it found, rerank them, and rewrite the scratchpad.
6. Close the iteration with a log line and a validity check.

The design rests on two observations from the article that inspired it. First,
agents work carefully on a handful of items and switch to shallow bulk
processing when given many, so each iteration handles very little. Second,
what the loop reads changes what it looks for next, so it reaches sources that
nobody would have planned for at the start.

The skill adds three things to that pattern:

- **Memory in files.** The scratchpad lives in `SCRATCHPAD.md` instead of the
  scheduler's prompt, so any host can run the loop, nothing is lost to context
  compaction, and you can read what the loop is thinking at any time.
- **A sealed brief.** Your instructions and guardrails live in `BRIEF.md`,
  which the loop can't edit. Its hash is checked every iteration, so a prompt
  injection planted in a web page can't rewrite the loop's rules.
- **Evidence discipline.** Every finding is labeled as verified, a source's
  claim, an inference, or a conflict, and must cite a source the loop actually
  opened.

For the reasoning behind each rule, see
[Why the research loop works the way it does](skill/references/design.md).

## What to expect

A loop costs one full agent turn per iteration. The default budget is 40
iterations, which at a five-minute cadence runs a little over three hours. A
one-minute cadence for a full day is about 1,440 turns, so set the budget and
cadence in proportion to how much the topic matters to you.

The dataroom is a plain directory that you can open in any editor:

```
research/neo-philanthropy/
  BRIEF.md          your instructions, seeds, and guardrails
  SCRATCHPAD.md     what the loop currently believes and plans to do next
  sources.jsonl     every source opened, rated 1 to 5
  findings.jsonl    every material claim, labeled and cited
  log.md            one line per iteration
  backlog.md        leads parked for later
  notes/            longer notes and translations
  artifacts/        saved extracts
  reports/          the final synthesis
```

The loop interrupts you only when something crosses the threshold you set in
the brief, such as a source that changes the picture. Everything else waits for
the final report.

## Install

Clone the repository once:

```sh
git clone https://github.com/chrischabot/research-loop-skill.git ~/Projects/research-loop
```

The skill needs Python 3.9 or later, which ships with macOS and most Linux
distributions. Link the `skill` directory into your agent's skill directory.

### Codex

```sh
mkdir -p ~/.agents/skills
ln -s ~/Projects/research-loop/skill ~/.agents/skills/research-loop
```

Invoke with `$research-loop`.

### Claude Code

```sh
mkdir -p ~/.claude/skills
ln -s ~/Projects/research-loop/skill ~/.claude/skills/research-loop
```

Invoke with `/research-loop`, or ask Claude to start a research loop.

### Pi

```sh
mkdir -p ~/.pi/agent/skills
ln -s ~/Projects/research-loop/skill ~/.pi/agent/skills/research-loop
```

Invoke with `/skill:research-loop`, or ask Pi to use the skill.

### Cursor

```sh
mkdir -p ~/.cursor/skills
ln -s ~/Projects/research-loop/skill ~/.cursor/skills/research-loop
```

Invoke with `/research-loop`. Cursor also discovers Codex and Claude skill
directories, so install only one visible copy.

To update any installation:

```sh
git -C ~/Projects/research-loop pull --ff-only
```

## Run a loop

Ask your agent to start one, naming the topic, the seeds, and any budget:

```
Start a research loop on new philanthropic institutions. Seed it with
https://nanransohoff.substack.com/p/the-third-wave-of-american-philanthropy
and the replies to it on X. Run every five minutes, at most 60 iterations,
and tell me only if you find something that changes the picture.
```

The agent creates the dataroom, writes the brief and the first scratchpad,
schedules the loop on its host, runs the first iteration while you watch, and
tells you where everything is and how to stop it.

How the loop is scheduled depends on the host:

- **Codex app**: a thread heartbeat automation.
- **Claude Code**: `/loop` in the current session, a scheduled task in the
  desktop app, or a cloud routine.
- **Codex CLI, Pi, Cursor, or a terminal**: the shell runner, which starts a
  fresh agent session for each iteration:

  ```sh
  ~/Projects/research-loop/skill/scripts/run-loop.sh research/neo-philanthropy --agent claude --interval 300
  ```

For the details of each host, including how to stop a loop, see
[Scheduling the loop on each host](skill/references/hosts.md).

To check on a loop at any time, read `SCRATCHPAD.md`, or run:

```sh
python3 ~/Projects/research-loop/skill/scripts/dataroom.py status research/neo-philanthropy
```

To stop a loop early, ask the agent to close it. The agent cancels the schedule
and writes the synthesis from whatever the dataroom holds.

## Test

The unit tests cover the dataroom helper and the shell runner, run in a few
seconds, and need no model:

```sh
python3 -m unittest discover -s tests
```

The smoke tests run real agents against real datarooms and cost a little money:

```sh
tests/smoke.sh injection claude
tests/smoke.sh web claude
```

For what each test proves and how to judge a real run, see
[Testing the research loop](docs/testing.md).

## Repository layout

The repository has the following layout:

```
skill/
  SKILL.md                  the instructions the agent follows
  references/design.md      why each rule exists
  references/dataroom.md    file formats and helper commands
  references/hosts.md       scheduling on each agent host
  references/synthesis.md   how to write the final report
  scripts/dataroom.py       the dataroom helper (standard library only)
  scripts/run-loop.sh       the shell runner
  templates/                the brief and scratchpad templates
  agents/openai.yaml        Codex display metadata
tests/
  test_dataroom.py          unit tests
  smoke.sh                  live agent tests
  fixtures/injection/       a saved page with a hidden prompt injection
docs/testing.md             the testing guide
```

## Credits

The loop pattern comes from the essay
[Alpha generation p1: self-editing heartbeats with seeds](https://docs.google.com/document/d/14qXSLPBZENOTmYJMJPQ7xFRtMzm00qCF9foTKqque70/mobilebasic),
which describes the approach running on Codex
automations and includes the `heartbeat-scratchpad-loop` skill. This skill is a
fresh implementation of that idea with file-based memory, injection
resistance, structured evidence, and support for more hosts.

## License

MIT
