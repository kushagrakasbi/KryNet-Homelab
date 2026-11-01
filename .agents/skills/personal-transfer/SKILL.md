---
name: personal-transfer
description: >-
  WORK-LAPTOP ONLY — on the personal Mac, push to origin directly and skip this skill.
  Moves commits made on the work laptop over to the personal machine, which does the
  pushing to GitHub — by direct git push over SSH on the home LAN, or by git bundle
  when off-network. Use when the user says "send this to my personal mac", "transfer
  this work", "bundle these commits", "how do I push this", or asks whether a copied
  repo will push correctly. Also covers the rare push-from-here case with
  $PERSONAL_GITHUB_PAT.
---

# Transferring work to the personal machine

There are no GitHub credentials on this laptop by design. Work is committed here and
pushed from the personal machine.

> ⚠️ **If you are already ON the personal Mac** (`~/Projects/home-server`), none of this applies:
> `git push -u origin <branch>`, then open the PR with the GitHub API (`AGENTS.md` → *Working from
> the personal Mac*).

## Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `../../CLAUDE.md` | the push rule or PAT handling changes |

---

## 🔴 Never push from this laptop unless explicitly asked

Commit freely. Do not push. If a push *is* explicitly requested, see the last
section — and do not persist the token anywhere.

---

## Method 1 — direct push to the personal Mac (on the home LAN)

The least ceremony: no intermediate file at all. Git pushes over SSH to the clone
already on that machine.

Clone paths on that Mac, per `nucleus-app/docs/AGENT-HANDOFF.md`:

| Repo | Path there |
|---|---|
| `nucleus-app` | `~/Projects/Nucleus/nucleus-app` |
| `home-server` | `~/Projects/home-server` |

```bash
cd ~/Work/Repos/personal/home-server
BRANCH=$(git branch --show-current)
git push personal-mac:Projects/home-server "HEAD:refs/heads/$BRANCH"

# nucleus-app sits one level deeper
git push personal-mac:Projects/Nucleus/nucleus-app "HEAD:refs/heads/$BRANCH"
```

Then on the personal Mac: `git switch <branch>` and push to GitHub from there.

### ✅ UPDATE 2026-08-30: the GitHub push CAN now be done over SSH from here

The Mac's remote moved from HTTPS to **SSH** (`git@github.com:kushagrakasbi/...`), so the keychain is
no longer in the path and a non-interactive push works:

```bash
ssh personal-mac 'cd ~/Projects/Nucleus/nucleus-app && git push -u origin <branch>'
```

Verified pushing four branches this way. **So the two-step division of labour below is obsolete** —
push branches to the Mac, then push them on to GitHub from here in the same session.

Opening the PR still needs the API, since `gh` is not installed on the Mac:

```bash
curl -sS -X POST -H "Authorization: Bearer $PERSONAL_GITHUB_PAT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/kushagrakasbi/<repo>/pulls --data-binary @/tmp/pr.json
```

🔴 Build the JSON with `python3 -c "import json; json.dump(...)"` from a file — shell quoting mangles
a long markdown body. Never write the PAT to disk, a remote URL, or `.git/config`.

<details>
<summary>The old failure, kept for reference in case the remote reverts to HTTPS</summary>

Do not try to run `git push origin ...` inside `ssh personal-mac`. It fails:

```
failed to get: -25308
fatal: could not read Username for 'https://github.com'
```

`-25308` is `errSecInteractionNotAllowed` — the remote is HTTPS with the
`osxkeychain` credential helper, and the keychain will not release credentials to a
non-interactive session. `git@github.com` is not a fallback either; that key needs an
agent, which an SSH session does not have.

So the division of labour is fixed: **push branches to the Mac from here, then push
to GitHub interactively on the Mac.** Two commands in its Terminal:

```bash
cd ~/Projects/<repo> && git push -u origin <branch>
```

To remove this limitation permanently, install and authenticate `gh` on the Mac —
that also makes non-interactive pushes work.

</details>

### Pulling merged work BACK to this laptop

This laptop has no GitHub credentials, so it cannot fetch from `origin`. Fetch from
the Mac instead — it has the updated `main`:

```bash
cd ~/Work/Repos/personal/home-server
git fetch personal-mac:Projects/home-server main
git checkout main && git merge --ff-only FETCH_HEAD

# nucleus-app sits one level deeper
cd ~/Work/Repos/personal/nucleus-app
git fetch personal-mac:Projects/Nucleus/nucleus-app main
git checkout main && git merge --ff-only FETCH_HEAD
```

Then delete the merged branch locally: `git branch -D <branch>`.

Use `--ff-only`. If it refuses, this laptop has commits the Mac does not — stop and
work out which before merging anything.

### After a PR merges

GitHub squashes or merge-commits, so your local branch commit is **not** an ancestor
of the new `main`. `git branch -d` will warn about that; the content is still in.
Confirm equivalence before deleting rather than trusting the warning either way:

```bash
git diff --stat <branch>..origin/main -- $(git diff --name-only main..<branch>)
```

Empty output means everything landed.

### 🔴 Check the commit author before pushing anywhere

This laptop's global git identity is a work address. Personal repos carry a local
override, but verify rather than assume — a corp email in a public repo's history
cannot be recalled:

```bash
git log origin/main..HEAD --format='%an <%ae>'
```

**Prerequisites** — `personal-mac` is configured in `~/.ssh/config.d/`, pointing at
the LAN IP with the homelab key. It needs **Remote Login** enabled on that Mac
(*System Settings → General → Sharing → Remote Login*), and the `User` in that
config must match the account there.

Confirm the paths still match before relying on them — that doc is a snapshot:

```bash
ssh personal-mac 'ls -d ~/Projects/*/ ~/Projects/Nucleus/*/ 2>/dev/null'
```

### 🔴 Two things that will bite

**You cannot push to the branch that is checked out there.** Git refuses, because it
would desync that working tree from HEAD (`receive.denyCurrentBranch`). Push a
*different* branch name, or check out something else on the Mac first. The error is
explicit, so you will know.

**Same-LAN only.** `personal-mac` is a private IP with no Tailscale on this laptop.
Off-network this fails exactly like the fleet does — that is when you use a bundle.

### Verify

```bash
ssh personal-mac "cd ~/Projects/home-server && git log --oneline -3 <branch>"
```

Confirm your commits are there *before* deleting anything locally.

---

## Method 2 — `git bundle`, not a zip

For when you are **off the home LAN**, or moving work to a machine you cannot reach.
Transfer the resulting file however you like — AirDrop is fine.

**Will a copied repo push correctly from the personal machine?** Yes — a git repo is
fully self-contained, so a faithful copy of the directory (including `.git/`) pushes
exactly as it would from here. Neither of these repos has worktrees or absolute-path
hooks, so nothing breaks on the move.

But copying the whole repo is the wrong tool, for three reasons:

| Zip / copy | `git bundle` |
|---|---|
| Carries untracked junk — build output, `.env`, `data/`, personal `.xlsx` files | Carries **only commits** |
| **Overwrites** the clone already on that machine, losing anything committed there | Merges cleanly via `git fetch` |
| Finder zips add `._` AppleDouble files and can mangle modes | Single verifiable file |
| No integrity check | `git bundle verify` before you trust it |

A bundle is git's own sneakernet format. It is exactly this use case.

---

## Sending work out

### 1. Commit everything you want to send

```bash
cd ~/Work/Repos/personal/<repo>
git status --short          # anything untracked you actually want? add it now
git log --oneline origin/main..HEAD    # what will travel
```

### 2. Bundle just your new commits

```bash
BRANCH=$(git branch --show-current)
git bundle create ~/Desktop/<repo>-$BRANCH-$(date +%Y%m%d).bundle origin/main..$BRANCH
```

`origin/main..HEAD` bundles **only what is new**, so the file is small. If the branch
is entirely new and unrelated to `origin/main`, bundle the whole branch instead:

```bash
git bundle create ~/Desktop/<repo>-$BRANCH.bundle $BRANCH
```

### 3. Verify before sending

```bash
git bundle verify ~/Desktop/<repo>-<branch>-<date>.bundle
git bundle list-heads ~/Desktop/<repo>-<branch>-<date>.bundle
```

`verify` confirms the bundle is complete and that its prerequisites exist. A bundle
that fails verify on the *receiving* machine means that machine is missing the base
commits — bundle the full branch instead.

### 4. On the personal machine

```bash
cd ~/Projects/<repo>            # the existing clone — NOT overwritten
git fetch ~/Downloads/<repo>-<branch>-<date>.bundle '*:refs/remotes/worklaptop/*'
git log --oneline worklaptop/<branch>
git switch -c <branch> worklaptop/<branch>     # or: git merge worklaptop/<branch>
git push -u origin <branch>
```

Then open the PR from there, with the title in the repo's Conventional Commits
format.

---

## When you also need untracked files

Bundles carry commits only. For gitignored-but-wanted files (a spreadsheet, a `.env`,
a database snapshot), send them **separately and deliberately** — that way you never
sweep something up by accident:

```bash
tar --disable-copyfile -czf ~/Desktop/<repo>-extras.tgz \
    "2025-2026 NetWorth-FY2025-2026.xlsx"
```

`--disable-copyfile` stops macOS adding `._` resource-fork entries.

🔴 **Never bundle or tar a `.env`, a token file, or a production database into
something you then leave on Desktop or send over a chat app.** Financial data and
credentials get their own transfer, or none.

---

## If a copy really is simpler

For a repo the personal machine does **not** already have, a full copy is fine and
simplest. Use `tar`, not Finder's zip:

```bash
tar --disable-copyfile -czf ~/Desktop/<repo>.tgz -C ~/Work/Repos/personal <repo>
```

This preserves `.git/`, file modes and symlinks. On arrival:

```bash
tar -xzf ~/Downloads/<repo>.tgz -C ~/Projects
cd ~/Projects/<repo> && git fsck && git status
```

Check `.git/config` afterwards — the remote should be the normal HTTPS/SSH GitHub
URL, with no credential helper or `insteadOf` rewrite carried over from this machine.
Both of these repos are clean in that respect today.

---

## The rare push-from-here case

Only when explicitly asked. `$PERSONAL_GITHUB_PAT` is exported in the environment.

```bash
# inline, single use — nothing written to disk
git -c credential.helper= \
    push "https://$PERSONAL_GITHUB_PAT@github.com/kushagrakasbi/<repo>.git" HEAD:<branch>
```

Rules:

- **Never** write the token into `.git/config`, a remote URL, a script, or a doc.
- **Never** echo it. Reference it by name only.
- `credential.helper=` (empty) stops it being cached into the login keychain.
- Prefer the bundle route. This exists for when waiting is not an option.

⚠️ The token will appear in that shell's history. `HISTORY_IGNORE`/a leading space
helps, but the durable answer is: use the bundle.

---

## Verify

```bash
git bundle verify <file>                          # here, before sending
git log --oneline worklaptop/<branch> | head      # there, after fetching
git status                                        # there: clean, nothing clobbered
```

The point of the bundle is that the receiving clone is never overwritten — confirm
that by checking its own local commits are still present after the fetch.
