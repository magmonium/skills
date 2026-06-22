---
name: tdd-implement
description: Pick lowest-index ready task folder from tasks/, pick lowest-index draft issue inside it, implement it with strict TDD red-green-refactor (via the tdd skill), then mark issue done. Use when user says "tdd implement", "implement next task with TDD", or wants the next drafted task built test-first.
---

# TDD Implement

Pick lowest NNNN draft task folder → pick lowest NN draft issue → mark issue in-progress → implement TDD → mark issue done (or revert to draft) → mark folder done when all issues done.

Sibling: `/to-implement` — same lifecycle, straight build instead of TDD.

## 1. Pick task folder + issue

**If argument given** (NNNN number or folder path) → use that task folder.

**No argument:**
- Scan `tasks/` top-level for folders matching `NNNN_draft_*`. Pick LOWEST NNNN.
- No draft folders → tell user, stop.

**Folder stays `NNNN_draft_*` throughout implementation.** Never rename it to in-progress. Other agents must be able to find it by scanning for `NNNN_draft_*`.

**Inside chosen task folder:**
- Scan for files matching `NN_draft_*`. Pick LOWEST NN. Skip any `NN_inprogress_*` files (already claimed by another run).
- No `NN_draft_*` issues left:
  - `NN_inprogress_*` files exist → report those are in-flight, stop.
  - None in-flight either → all issues done; rename folder `NNNN_draft_<desc>` → `NNNN_done_<desc>` (`git mv`), report feature done, stop.
- Issue's **Blocked By** names another issue still `_draft_` or `_inprogress_` → report blocker, skip, pick next unblocked. None unblocked → list blockers, stop.

**Immediately after picking:** rename issue file `NN_draft_<desc>.md` → `NN_inprogress_<desc>.md` (`git mv`). This marks it claimed. Folder name unchanged.

## 2. Read context

- `prd.md` in the task folder — overall feature context.
- The chosen issue file fully — **What**, **One UI**, **Acceptance Criteria**, **Blocked By**.
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, test setup, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement — TDD

Invoke `tdd` skill (Skill tool). Follow it exactly: vertical slices, one test → minimal impl → repeat, refractor only on GREEN.

Adaptations for issue-driven run:

- Issue file = approved plan. **Acceptance Criteria** boxes = behavior list to test. Don't block waiting for user plan approval.
- Tests through public interface only — survive refractor. Run via project's test wrapper/commands from CLAUDE.md.
- Pure reference/contract issue (no executable behavior) → no TDD loop; produce reference artifact, done.

Code rules (apply during GREEN + refractor):

- **Magmonium Standard:** Use Signals (`signal`, `computed`, `effect`) for state. No `standalone: true`. Use `inject()` for DI. Use `ChangeDetectionStrategy.OnPush`.
- **Assets First:** Never hardcode UI config (buttons, forms, navs) in TS. Define in `mag_assets/*.yml`. Run `npm run assets:compile`.
- **UI Components:** No native `<h1>-<h6>`, `<button>`, `<input>`, or `<img>`. Use `m-header`, `m-button`, `m-input`, `m-img`.
- **Text:** All text via `| translate` pipe — no raw strings in templates.
- **Styling:** `.sass` only, BEM naming, max 3 nesting levels. Import `@use 'index' as m`.
- **FSD Layering:** `pages` → `widgets` → `features` → `entities` → `shared`.
- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies issue.
- If issue has **One UI** section: follow those constraints exactly.
- Respect ADRs. Issue conflicts ADR → stop, ask user.

## 4. Verify

- Every **Acceptance Criteria** box: check, tick in issue file. TDD loop already ran per-slice tests during red-green-refractor.
- Run full lint + test suite directly. Fix any failures before proceeding.
- **Translation lint errors:** Agent NEVER runs `translation:fix`. If lint fails only on translation errors → note it in report, tick gate anyway, proceed to close + commit (step 5). User can run `translation:fix` after.
- Asset compile: run `npm run assets:compile` if any `mag_assets/*.yml` changed.

## 5. Mark done (or revert)

**On success:**
- Rename issue file: `NN_inprogress_<desc>.md` → `NN_done_<desc>.md` (`git mv` inside task folder).
- Check task folder: any `NN_draft_*` or `NN_inprogress_*` files remaining?
  - Yes → note count remaining, stop. Folder stays `NNNN_draft_*`.
  - No → rename task folder: `NNNN_draft_<desc>` → `NNNN_done_<desc>` (`git mv`). Feature done → ready for `/to-review`.

**On failure / blocked / abandoned:**
- Rename issue file back: `NN_inprogress_<desc>.md` → `NN_draft_<desc>.md` (`git mv`). Folder unchanged.
- Report what failed. Stop.

## 6. Report — caveman, minimal

- Issue id (`NNNN/NN`) + one line what built. Files touched (paths only). Test count added/passing.
- Acceptance Criteria: each box pass/fail.
- Feature: N done / M total issues for this NNNN.
- **Commit:** Run `git add` on changed files, then `git commit` with message:
  ```
  <type>(NNNN/NN)- <what, terse, fragments>

  <one-line why, caveman>

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor/chore. `refractor` MUST be used instead of `refactor`.
