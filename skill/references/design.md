# Why the research loop works the way it does

This document explains the reasoning behind each part of the skill, so that you
can change a rule knowing what it protects.

## The problem

Agents asked to research a topic tend to return consensus: the articles that
rank well, summarized competently. A person following a good rabbit hole for an
afternoon often does better, reaching a practitioner's newsletter, a
second-order academic paper, or a government list that no English-language
search would surface. The loop tries to give an agent that afternoon, repeated
many times.

The pattern comes from Alpha generation p1: self-editing heartbeats with seeds,
which describes a Codex thread that wakes every minute, keeps its working memory
in its own automation prompt, and builds a dataroom from seed posts and sites.
This skill keeps that core and changes how memory, safety, and evidence are
handled.

## Seeds instead of queries

A query tells the agent what to look for; a seed shows it what good looks like.
A post that drew experts into its replies is a map of who matters in a field. A
provincial project list is a template: once the agent has seen one, it can look
for the same document in other provinces, years, and countries. Seeds carry
taste that is hard to put into words, which is why the brief asks for a line on
why each seed is a good example.

## One lead per iteration

Agents behave differently with five items than with a hundred. With five, they
open each one and read it. With a hundred, they write a script or a bulk query
and skim the results. The careful behavior produces better sources, so the loop
keeps every iteration small: one to three items, opened by hand, recorded
before moving on. Over a long run the small steps add up to a large dataroom
without the quality drop of bulk enrichment.

## A self-rewriting scratchpad

Each iteration ends by rewriting the scratchpad: reranking leads, adding the
ones it has found, and setting the next actions. This is what lets the loop
go somewhere a plan written at the start would not have named, because what it
read in iteration 12 changes what it looks for in iteration 13. Every fifth
iteration follows a deprioritized lead instead of the top one, so an early
ranking mistake cannot fix the direction of the whole run. Independent runs from
the same seeds diverge, which is useful when you want breadth.

## The scratchpad lives in a file

The original pattern keeps the scratchpad in the scheduler's prompt. This skill
keeps it in `SCRATCHPAD.md` and points the scheduler at it, for three reasons:

- Not every host lets a loop rewrite its own prompt. Claude Code's `/loop`
  passes the same prompt to every wake-up, and a shell runner has no prompt to
  rewrite. A file works on every host.
- A file survives context compaction and fresh sessions, and a different agent
  can resume the loop from it.
- The user can open it at any time and see exactly what the loop believes and
  plans to do next.

## A sealed brief

A loop that rewrites its own instructions while reading untrusted pages
unattended is an unusually good target for prompt injection: one planted
sentence copied into the scratchpad would be obeyed by every later iteration.
The skill separates instructions from memory. `BRIEF.md` holds everything the
user decided, including the guardrails, and the loop never edits it. `seal`
records its hash, and `log` and `check` stop the loop if it changes. The
scratchpad can plan within the brief but has no authority to widen it.

Three further rules narrow what an injection can achieve. Sources are recorded
in the agent's own words, so imperative text has no route into memory. `check`
warns when the scratchpad or a finding contains phrases typical of injected
instructions. And the loop acts on the outside world read-only, so even a
successful injection cannot post, message, buy, sign in, or run downloaded
code.

## Structured records written by a script

Sources and findings go through `dataroom.py`, not hand-edited JSON. The script
assigns ids, rejects duplicate URLs after normalizing them, enforces the claim
labels, and refuses a `verified` finding that cites nothing the agent read.
This keeps the dataroom consistent across iterations, sessions, and agents, and
it means the final synthesis can trust the records it is built from.

## Claim discipline from deep research

The evidence rules come from the deep-research skill: the four claim labels, an
agent's summary treated as a lead until its source is opened, independence
checks between sources, a pass looking for disconfirming evidence, and no
fabricated citations. A loop running for hours accumulates errors faster than a
single session, so these rules matter more here, not less.

## Explicit stopping

Loops cost money for as long as they run, and a loop nobody remembers is the
worst kind. The skill stops on a budget of iterations, an end date, the
objective being met, or saturation: five iterations in a row without a source
rated 4 or higher. Closing the loop always cancels the schedule and writes a
synthesis, so a finished loop leaves a report instead of a directory of raw
material.

## What the loop is not for

It is not for answering a defined question in one sitting; the deep-research
skill does that better and faster. It is also not a monitor for one fixed source
that only needs a diff, which a plain scheduled check handles more cheaply.
