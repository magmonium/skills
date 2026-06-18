# Issue Format

File: `tasks/NNNN_draft_<task-desc>/NN_draft_<kebab-issue-desc>.md`

- `NNNN` — feature index, 4 digits (shared by all issues of this feature)
- `NN` — issue sequence, 2 digits, dependency order (01 first)
- Status encoded in filename: `_draft_` → `_done_` on completion
- Task folder status: `NNNN_draft_<desc>/` → `NNNN_done_<desc>/` when ALL issues done

All prose caveman. Keep file small — agent reads in seconds.

---

```markdown
# NN — <Issue Title>

## What

2–5 lines. Self-contained: what to build end-to-end for this slice. Name layers touched
(schema change, endpoint, UI screen, etc.). No file paths — describe behavior and contracts.

## One UI

> Include ONLY when this issue touches frontend/UI work. Omit section entirely otherwise.

- Screen built using One UI components — no native `<h1>`/`<button>`/`<input>`/`<img>`.
  Use `m-header`, `m-button`, `m-input`, `m-img` etc.
- Text via `| translate` pipe — no raw strings in templates.
- FSD layering: `pages` → `widgets` → `features` → `entities` → `shared`.

> Add the following line ONLY when a reusable One UI component is needed:
- Reusable component: `<ComponentName>` — build in `@magmonium/one` library.
  Inputs: [...]. Outputs: [...]. This issue depends on `NN_draft_one-ui-<component>`.

## Acceptance Criteria

- [ ] Observable outcome 1
- [ ] Observable outcome 2
- [ ] Build/lint/test pass (user confirms)

## Blocked By

None
```

Or for blocked issues:

```markdown
## Blocked By

`NN_draft_<issue-desc>` — must complete first
```

## Field rules

- **What**: end-to-end behavior, not layer-by-layer breakdown. What the user/system can observe when done.
- **One UI section**: present = frontend work involved. Omit = no frontend.
- **Acceptance Criteria**: external behavior only. 2–5 boxes. Last box = human build/lint/test gate. Agent never runs `translation:fix`, `assets:compile`, build, or full test suite — list commands, stop, wait for user.
- **Blocked By**: issue filename (without path). `None` if no blockers.
