# PRD Format

File: `prd/draft/NNNN_<kebab-slug>.md` — NNNN zero-padded 4 digits, slug short kebab-case feature name.

All prose caveman style. Section order fixed — agents rely on it.

````md
# NNNN — <Title>

## Problem

What hurts, from user's perspective. 2–4 lines max.

## Solution

What fixes it, from user's perspective. 2–4 lines max.

## User Stories

Numbered list. Sentence structure kept exact (structure aids parsing, not caveman'd):

1. As <actor>, I want <feature>, so that <benefit>

Cover all aspects of the feature. Long list fine — each line short.

## Decisions

One bullet per decision resolved in the grill session:

- Modules built/modified + their interfaces
- Schema changes
- API contracts
- Architecture choices + one-line why

No file paths, no code — except snippet that encodes decision better than prose (schema, state machine, type shape).

## Testing

- Good test = external behavior only, no implementation details
- Which modules get tests
- Prior art in codebase, if any

## Out of Scope

Bullet list. Explicit beats implied — name the tempting adjacent work being skipped.

## Open Questions

Anything left unresolved after the grill. Delete section if none.
````

## Example (caveman prose)

```md
## Problem

Users own apps but no way to hand off ownership. Owner leaves → app orphaned.

## Solution

Transfer-ownership flow. Owner picks collaborator → collaborator accepts → roles swap.
```
