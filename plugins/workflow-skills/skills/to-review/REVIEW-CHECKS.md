# Review Checks

Audit scope: ONLY code this PRD's tasks introduced or changed. Pre-existing flaws outside that diff → mention once, don't task them.

Finding format — one line each: `[file/module] [problem] [fix]`. Severity tag: `SEC` | `ARCH` | `DRY`.

## SEC — Security

- Input from request hits DB/shell/path/template without validation or escaping (injection, traversal).
- Endpoint missing authn/authz the sibling endpoints have (compare same module's views).
- Object access without ownership check — user A reads/writes user B's record (IDOR).
- Secrets/keys/tokens hardcoded or logged.
- Sensitive fields leak in responses (check model `restricted` lists honored).
- Mass assignment — request body written to model without field whitelist.
- Errors leak internals (stack traces, query text) to client.

SEC findings: report in plain clear prose, not caveman. User must understand risk before agreeing.

## ARCH — Architecture

- Violates ADR in `docs/adr/` (or project ADR folder) — cite the ADR.
- Violates project CLAUDE.md conventions (response helpers, auth classes, base models, error handling decorators — whatever project names).
- Wrong layer: business logic in view/controller/template, DB calls outside model/service layer.
- God blob: one function/component doing many jobs that project splits elsewhere.
- New pattern invented where existing project pattern already covers the case.
- Missing index/constraint the access pattern obviously needs.

## DRY — Duplication / Reuse

- Copy-paste block ≥5 lines appearing 2+ times in PRD's code → extract helper.
- Logic re-implementing existing shared util/component — point at the existing one.
- New UI markup duplicating existing reusable component.
- Same validation/transform inline in multiple endpoints → shared function.
- Reusability: new code other modules will want soon → suggest extracting now, name where it should live.

DRY suggestions are cheapest to reject — propose only when reuse is concrete, not speculative.
