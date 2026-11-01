---
name: session-handoff
description: >-
  Keeps the agent handoff in docs/handoff/ (HANDOFF.md, PROGRESS.md, PLAN.md,
  RESUME-PROMPT.md, TRAPS.md) current so any agent on any machine can take over at any
  point. Use at the START of every session on this repo (read it), after every milestone
  (a PR merged, a deploy, a fix verified, an incident found), before context is compacted,
  before stopping, and whenever the user says "handoff", "update progress", "resume prompt",
  "write it up", "I'm switching machines" or "another agent will take over".
---

# 🔁 Session handoff — keep docs/handoff/ true

**The rule:** the state of the work lives in `docs/handoff/`, and it must be true *whenever* someone
reads it — not just at the end. The owner works from two machines and hands work between agents; a
session that ends without updating these files forces the next one to re-derive, and re-derive wrongly.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `docs/handoff/*` | the file set or its sections change |
| `AGENTS.md` → *Agent handoff* | the upkeep rule changes |

---

## When to update — and what

| Moment | Update |
|---|---|
| **Session start** | Read `HANDOFF.md` + `TRAPS.md`, run `scripts/fleet-validate.sh`. If reality differs from `HANDOFF.md` §2–3, **fix the doc first** — then work |
| **Milestone** (PR merged, deploy done, incident found, decision taken) | `PROGRESS.md` entry · `HANDOFF.md` §2–5 · `PLAN.md` row status |
| **New false reading** | a row in `TRAPS.md` |
| **"Do next" changes** | `HANDOFF.md` §5 **and** step 4 of `RESUME-PROMPT.md` |
| **Before compaction / stopping / switching machine** | all of the above, then commit + PR |

## Checklist — capture the state honestly

```bash
scripts/fleet-validate.sh                 # health: containers, GPU, mounts, ZFS, Gatus, backups, HA
scripts/drift-check.sh --quiet            # repo vs live (needs Portainer tokens — personal Mac, or Mac awake)
git fetch origin && git log --oneline -5 origin/main
```

Open PRs (no `gh` on either machine):

```bash
curl -s -H "Authorization: Bearer $PERSONAL_GITHUB_PAT" \
  "https://api.github.com/repos/kushagrakasbi/home-server/pulls?state=open" \
  | python3 -c 'import json,sys;[print(p["number"],p["title"]) for p in json.load(sys.stdin)]'
```

Then write:

1. **`HANDOFF.md`** — bump *Last verified* (absolute date + time + machine). §2 state table from the
   commands above. §3 open incidents (cause, fix, who). §4 owner decisions with your recommendation.
   §5 the next agent work, in order. §6 if you took a backup, add it with its path.
2. **`PROGRESS.md`** — a new entry at the TOP: what changed, **how it was verified**, what must not be
   re-derived.
3. **`PLAN.md`** — move finished items to §2 *Done* (with the PR); re-order the backlog if priorities
   moved; add decisions to §5 with the reason.
4. **`RESUME-PROMPT.md`** — step 4 must match `HANDOFF.md` §5.
5. **`TRAPS.md`** — any reading that lied to you.

## Writing rules

- 🔴 **Only write what you measured.** Mark anything carried forward or assumed as *unverified*. A
  handoff that is confidently wrong is worse than none — it is trusted.
- **Absolute dates and times**, never "yesterday". Say which machine you verified from.
- **Correct, don't silently rewrite.** If an earlier entry was wrong, say so in the new entry —
  the correction is the valuable part.
- 🔴 **No credentials, tokens, ping UUIDs or camera passwords** — paths and variable names only.
- Keep `HANDOFF.md` a *current-state* document: move finished history into `PROGRESS.md` so it does
  not grow without bound.
- Long reasoning belongs in `PLAN.md`; `HANDOFF.md` says what and where.

## Committing it

Same flow as any change: branch off fresh `main` (`docs/handoff-<yyyy-mm-dd>`), commit, PR.

- **Personal Mac:** push to `origin` directly; open the PR with the GitHub API.
- **Work laptop:** commit locally, then the `personal-transfer` skill (push to the Mac, the Mac pushes).

A handoff-only PR is fine to raise on its own. Do not hold it back to bundle with code.

## Done means

`fleet-validate.sh` output and `HANDOFF.md` §2 agree · every §3/§4 item names who acts next · the PR
is open (or merged) · `RESUME-PROMPT.md` step 4 matches §5.
