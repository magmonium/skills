---
name: grill-to-prd
description: Interview the user relentlessly about a plan or feature until shared understanding, then write a caveman-style PRD draft file to prd/draft/NNNN_<slug>.md. Use when user wants to grill an idea into a PRD file, turn a grilling session into a local PRD draft, or mentions "grill to prd".
---

# Grill to PRD

Two phases: grill, then write PRD file. No issue tracker — output is a local draft file in the repo.

## Phase 1 — Grill

Interview the user relentlessly about every aspect of the plan until shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask questions one at a time, waiting for an answer before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

Track resolved decisions as you go — they feed the PRD.

## Phase 2 — Write PRD

When all branches are resolved (or user says "write the prd" / "enough"):

1. Determine the number: scan `prd/draft/` (relative to repo root) for the highest `NNNN_` prefix; next = highest + 1, zero-padded to 4 digits. Folder missing → create it, start at `0001`.
2. Write `prd/draft/NNNN_<kebab-slug>.md` using the template in [PRD-FORMAT.md](./PRD-FORMAT.md).
3. Reply with the file path and one line per section so the user can confirm or correct.

## PRD Style — Caveman

PRD prose is caveman: drop articles, filler, pleasantries, hedging. Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for"). Pattern: `[thing] [action] [reason].`

Keep exact: technical terms, code blocks, schemas, API contracts, error strings, the user-story sentence structure.

Goal: a human skims it in one minute; an agent parses it without ambiguity. Small file beats exhaustive file — cut anything that doesn't change what gets built.

No specific file paths or code snippets in decisions — they rot. Exception: a snippet that encodes a decision more precisely than prose can (schema, state machine, type shape). Trim to the decision-rich parts.
