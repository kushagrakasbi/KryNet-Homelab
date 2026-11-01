# ▶️ Resume prompt

Paste the block into a fresh agent session, on either machine. Keep it current: when the
"do next" list in `HANDOFF.md` §5 changes, change step 4 here.

```
You are taking over operations of the KryNet home server fleet (3 nodes: Agni 192.168.0.200,
Prime 192.168.0.100, Legion 192.168.0.150). The repo is `home-server` —
~/Projects/home-server on the personal Mac, ~/Work/Repos/personal/home-server on the work laptop.

1. WORK OUT WHERE YOU ARE. Read AGENTS.md "Where you are working from". On the personal Mac
   you hold the Portainer tokens (~/.portainer/) and push to GitHub directly. On the work
   laptop you cannot push, cannot reach *.krynet.cc, and read tokens from the Mac over SSH.
   Then run `git fetch origin && git status` and fast-forward main if behind.

2. READ, in order: docs/handoff/HANDOFF.md (state + queue), docs/handoff/TRAPS.md (readings
   that lied), AGENTS.md. Read docs/handoff/PLAN.md before choosing work.

3. VERIFY before trusting the docs: run `scripts/fleet-validate.sh` and compare with HANDOFF.md
   §2–3. Anything different is either your first task or a correction to HANDOFF.md.

4. DO NEXT (unless the owner says otherwise):
   a. Open incidents in HANDOFF.md §3 — the pCloud re-auth and Legion sudo are owner steps;
      prepare them, ask for them, then verify them.
   b. Agent work in HANDOFF.md §5, in order.
   c. Anything in HANDOFF.md §4 needs the owner's explicit "yes" first.

5. KEEP THE HANDOFF CURRENT. At every milestone and before you stop, follow the
   `session-handoff` skill: update HANDOFF.md, PROGRESS.md, PLAN.md and this prompt, and
   commit them — on a branch, via a PR, like any other change.

Rules that do not bend: production-warning block + explicit "yes" before destructive or bulk
changes; no credentials in any file, commit or message; never `docker system prune -a`;
validate the Caddyfile before reloading; one branch per task, never stacked PRs; commit as
Kushagra Kasbi and NEVER with a work email address (check `git config --local user.email`).
```
