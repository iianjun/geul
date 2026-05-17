---
name: pr
description: Use when creating or updating a GitHub PR from the current branch with this repo's PR template
---

# $pr -- PR Creation Guide

Use this command to create or update a pull request for `geul` from the current
branch. Base the PR body on `.github/pull_request_template.md`.

## Assumptions

- Default base ref is `main` unless the user provides another base.
- `$pr` creates a ready-for-review PR by default. Do not pass `--draft` unless
  the user explicitly asks for it.
- If a PR already exists for the current branch, update that PR body instead of
  creating a duplicate.
- If the branch has no upstream, push the current branch to `origin` before
  creating the PR.
- Treat untracked or unrelated working-tree changes as user-owned. Do not
  revert or include them silently.

## Workflow

1. Read project guidance:
   - `CLAUDE.md`
   - `.github/pull_request_template.md`
2. Inspect branch state:
   - `git status --short`
   - `git branch --show-current`
   - `git diff --stat <base-ref>...HEAD`
   - `git diff --name-only <base-ref>...HEAD`
   - `git log --oneline <base-ref>..HEAD`
3. If `HEAD` has no branch diff, inspect the working tree instead:
   - `git diff --stat`
   - `git diff --name-only`
4. Identify the PR scope:
   - What changed
   - Why it changed
   - Reviewer scan points
   - Verification actually run
   - UI impact, if any
   - Known risks or follow-ups
5. Ask one concise question only if scope, base ref, branch ownership, or PR
   title is ambiguous.
6. Write a PR body that preserves the template sections and checkbox semantics.
7. Create or update the PR:
   - Existing PR: `gh pr edit <number-or-url> --body-file <body-file>`
   - New PR: `gh pr create --base <base-ref> --head <branch> --title "<title>" --body-file <body-file>`

## PR Body Rules

- Keep the template sections and order exactly:
  - `Summary`
  - `Changes`
  - `Verification`
  - `UI Impact`
  - `Checklist`
  - `Notes for Reviewers`
- Replace template comments with concrete content.
- Use bullets for concrete code/doc/test changes.
- Mark a verification checkbox only if that command/check actually ran.
- Leave unchecked verification items unchecked when not run, and explain why in
  `Notes for Reviewers`.
- For UI changes, include a screenshot note or manual verification note.
- If there is no UI impact, check `No UI impact`.
- Do not claim tests were added unless files changed under `Tests/`.
- Keep risks and follow-ups specific, or write `None.` if there are none.

## Output

Return the PR URL, title, base branch, and a short note about whether the PR was
created or updated. Do not return only Markdown text unless the user explicitly
asks for a preview.
