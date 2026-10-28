# Scheduling the loop on each host

Every host runs the same iteration; only the scheduler differs. The scratchpad
always lives in the dataroom's `SCRATCHPAD.md`, never only in a scheduler's
prompt, so that any host can pick the loop up and the user can read it.

Use this iteration prompt everywhere, with the dataroom's absolute path:

```
Use the research-loop skill to run exactly one iteration for the dataroom at PATH.
```

After you create the schedule, record its handle with
`dataroom.py seal PATH --host HOST --schedule HANDLE`. When the loop closes,
cancel the schedule with the same handle.

## Choose a cadence

Each iteration is a full agent turn, so cadence sets the cost. A one-minute
cadence for 24 hours is about 1,440 turns. The default budget of 40 iterations
at five-minute intervals runs a little over three hours. Choose the shortest
cadence the user is willing to pay for: shorter intervals finish sooner but do
not make an individual iteration better.

## Codex app

Use a thread automation (a heartbeat) when the loop should continue in the
current thread, which keeps continuity with the conversation. Create it with the
automation tool (`automation_update`), using the iteration prompt and the
cadence from the brief. Use a detached cron automation against a workspace for
loops that run for days.

- Handle: the automation's id. Record it with `seal --host codex-heartbeat`.
- Stop: delete the automation with `automation_update`.
- If an automation already owns this dataroom, update it instead of creating a
  second one.

The original version of this pattern stored the scratchpad in the automation
prompt itself. Keep the prompt short and point it at the dataroom; the file is
the authority.

## Claude Code

Choose one of the following, from shortest to longest-lived:

- **Dynamic loop (`/loop` with no interval).** The user, or you on their
  request, runs `/loop Use the research-loop skill to run exactly one iteration
  for the dataroom at PATH.` At the end of each iteration, schedule the next
  wake-up with `ScheduleWakeup`, passing the same prompt and a delay of 60 to
  3,600 seconds. Stop by calling `ScheduleWakeup` with `stop: true`. The loop
  lives in the current session.
- **Fixed interval (`/loop 5m PROMPT`).** The session wakes on a fixed
  interval while it stays open. Stop it with `CronList` and `CronDelete`, or by
  ending the session.
- **Desktop scheduled task.** In the Claude desktop app, create a scheduled task
  with the iteration prompt. Each run starts a fresh session, which suits loops
  that run for days. Stop it by deleting the task.
- **Cloud routine (`/schedule`).** Runs in a cloud container that is discarded
  after each run, so the dataroom must live in a git repository that each
  iteration commits and pushes. Cloud schedules run at most hourly.

Record the handle (`claude-dynamic`, the cron id, the task id, or the routine
id) with `seal`.

## Shell runner (Codex CLI, Pi, Cursor, and any other agent)

`scripts/run-loop.sh` runs one fresh agent session per iteration and stops when
`dataroom.py status` says `STOP` or when a check fails:

```bash
SKILL_DIR/scripts/run-loop.sh PATH --agent claude --interval 300
SKILL_DIR/scripts/run-loop.sh PATH --agent codex --interval 300
SKILL_DIR/scripts/run-loop.sh PATH --agent pi --interval 300
```

For another agent, set `RESEARCH_LOOP_CMD` to a command that accepts the prompt
as its last argument. Stop the runner with Ctrl-C. Fresh sessions make each
iteration start from the scratchpad alone, which is the cleanest test of
whether the scratchpad holds enough.

The Claude runner allows file tools, web search, web fetch, and the dataroom
helper, and no other shell commands. The Codex runner uses the
`workspace-write` sandbox with web search enabled.

## Without a scheduler

On a host with no scheduler, tell the user the loop is ready and that each
"run the next iteration" message advances it by one step.
