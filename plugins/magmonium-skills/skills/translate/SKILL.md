---
name: translate
description: Use when asked to /translate — scans Angular templates for raw (untranslated) text and | translate pipe usages with missing i18n keys, wraps raw text with the translate pipe, creates en-only YAML files in the correct mag_assets/i18n/ folder, runs the fix-i18n CLI to machine-translate remaining languages, then verifies nothing breaks and lint passes.
---

# translate

## Overview

Full i18n pipeline for the nx repo:

1. **Discover** — find (a) `| translate` keys missing from `mag_assets/i18n/`, and (b) raw hardcoded text in templates that has no `| translate` pipe at all.
2. **Fix templates** — wrap raw text with `| translate` + new dash-case key derived from the English text.
3. **Create YAML** — for each missing key, write file named after the English text with **only the `en:` translation. Nothing else.**
4. **Run CLI** — `npm run translate:fix` machine-translates all remaining languages.
5. **Rectify** — review CLI output, fix bad/missed translations.
6. **Verify** — `npm run assets:compile` + lint for touched scope. All green → complete.

## Scope Rules

| Component lives in | Create YAML in | Check compiled JSON at |
|---|---|---|
| `libs/one/**` | `libs/one/mag_assets/i18n/` | `libs/one/assets/i18n/en.json` |
| `apps/m-finance/**` | `apps/m-finance/mag_assets/i18n/` | `apps/m-finance/public/assets/i18n/en.json` |
| `apps/m-comics/**` | `apps/m-comics/mag_assets/i18n/` | `apps/m-comics/public/assets/i18n/en.json` |
| `apps/m-ui/**` | `apps/m-ui/mag_assets/i18n/` | `apps/m-ui/public/assets/i18n/en.json` |

YAML path: `<scope_root>/mag_assets/i18n/<first_char_of_filename>/<filename>.yml`

**Filename derivation algorithm** (applies to all new files):
1. Take the English text value.
2. Lowercase it.
3. Replace every run of non-alphanumeric characters with a single `-`.
4. Strip leading and trailing `-`.
5. Result is both the filename (without `.yml`) and the translation key used in templates.

If the derived name starts with a digit → place in `mag_assets/i18n/0-9/` subdir.

## Process

### Step 1 — Resolve scope

If a file path argument is given, scope = the app/lib that file belongs to.
If no argument, scan all component templates across the entire repo.

### Step 2 — Discover raw (untranslated) text

Scan templates (inline + `.html`) for user-visible static text NOT passing through `| translate`:

- Element text nodes: `<span>Net Margin</span>`
- User-facing attributes: `placeholder`, `title`, `label`, `aria-label`, `alt`, `tooltip`

Skip: `.spec.ts` files, interpolated variables, numbers/punctuation-only, single chars, icon names, `class`/`id`/routerLink/technical attrs.

For each finding, derive the key using the filename derivation algorithm (see Scope Rules), then wrap with translate pipe:

```html
<!-- before -->
<span>Net Margin</span>
<input placeholder="Search stocks" />

<!-- after -->
<span>{{ 'net-margin' | translate }}</span>
<input [placeholder]="'search-stocks' | translate" />
```

The original text becomes the `en:` value verbatim (exact text preserved, not re-humanized). Key = dash-case filename. Add these keys to the missing-key list.

### Step 3 — Extract existing translate keys

Grep for `| translate` in templates. Handle three patterns:

**Static string:**
```
'net-margin' | translate   →  key = net-margin
"search-stocks" | translate →  key = search-stocks
```

**Conditional:**
```
(x > 0 ? 'upside' : 'downside') | translate  →  keys = [upside, downside]
```

**Dynamic expression** (must trace):
```
technicalSentiment().label | translate
```
Find the `computed()`/method in the TS and extract all returned string literals:
```ts
return { label: 'strongly-bullish' }  →  key = strongly-bullish
return { label: 'bullish-support' }   →  key = bullish-support
```

**Existing snake_case / camelCase keys with no YAML file** — do NOT create a file using the old key name. Instead:
1. Humanise the key (replace `_` with space, split camelCase on capital letters, title-case).
2. Run the filename derivation algorithm on the humanised text.
3. Create the file under the new dash-case name.
4. Update the `| translate` reference in the template to the new key.

**Untraceable** (data from API, e.g. `item.label | translate`):
→ Report as `DYNAMIC/UNTRACEABLE`, skip YAML creation.

### Step 4 — Check existing keys

For each key (from Steps 2 + 3), derive the dash-case filename first, then:
1. **Check `libs/one` first** (always): `libs/one/mag_assets/i18n/<char>/<dash-name>.yml` — if found, skip creation regardless of scope. The shared lib serves all apps.
2. Look in compiled JSON: `<scope>/public/assets/i18n/en.json` (or `assets/i18n/en.json` for libs/one)
3. Also check if YAML source already exists: `<scope>/mag_assets/i18n/<char>/<dash-name>.yml`

**Extra check for label / placeholder / title / aria-label text** — before creating a new YAML, grep all `mag_assets/i18n/` directories (recursively) for a yml file whose `en:` value matches the English text (case-insensitive). If a match is found under a different dash-case key, reuse that key in the template instead of creating a duplicate.

Skip if found in any of the above.

**Deduplication rule**: if same dash-named file already exists in ≥2 apps and not in `libs/one`, do NOT create another copy. Instead flag it:
```
⚠ DUPLICATE: <dash-name>.yml found in [app-a, app-b] — move the copy with most translations to libs/one/mag_assets/i18n/<char>/<dash-name>.yml and delete app copies.
```

### Step 5 — Create missing YAML files (en only)

For each missing key, derive the dash-case filename (see Scope Rules algorithm), then write `<scope>/mag_assets/i18n/<first_char_of_filename>/<dash-name>.yml` with **ONLY the `en:` line. Do NOT add any other language** — the CLI fills them in Step 6.

**English value**:
- Key came from raw text (Step 2) → use the original template text verbatim.
- Key came from existing `| translate` usage → humanize the key: replace `_` with space, split camelCase on capitals, title-case each word. Preserve known abbreviations: `PE`, `PB`, `EPS`, `SMA`, `PNL`, `CAGR`, `ETF`. `strongly_bullish` → `Strongly Bullish`, `pe_ratio` → `PE Ratio`, `high_52w` → `52W High`, `sma_50` → `SMA 50`. Then run the filename derivation algorithm on the humanised text.

Example — raw text `"Net Margin"` in `apps/m-finance/`:
- Dash name: `net-margin`
- File: `apps/m-finance/mag_assets/i18n/n/net-margin.yml`
- Template: `{{ 'net-margin' | translate }}`

```yaml
en: Net Margin
```

That is the entire file.

### Step 6 — Run fix-i18n CLI

From the nx repo root:

```bash
npm run translate:fix:dry   # preview: which keys/langs will be filled
npm run translate:fix       # machine-translates all missing languages
```

The CLI (`fix-i18n`) finds incomplete YAMLs, gets the full language set from `libs/cli/mag_assets/i18n/lang.yml`, and fills missing langs via translation providers.

### Step 7 — Rectify

After CLI run, re-read each created/modified YAML:

- Every file has the full language set (compare against an established file, e.g. `libs/one/mag_assets/i18n/h/high_52w.yml`).
- Spot-check translations — fix any that are empty, garbled, left identical to English where a real translation exists, or wildly long. Financial/UI labels must stay short — match character density of nearby labels.
- CLI failed for some langs → fill those manually with proper concise translations.

### Step 8 — Verify nothing breaks + lint

```bash
npm run i18n:compile             # validate + auto-fix + compile i18n yml → json, fast signal
npm run lint:finance              # or lint / lint:comics / lint:wallet / lint:radio / lint:libs per touched scope
```

- `i18n:compile` runs validator (`compile-i18n` CLI): parses every i18n yml, auto-fixes common syntax issues (unquoted trailing colon, tabs, dup lang keys) writing fixes back to source, compiles good files to json, and logs unresolved failures to `i18n-compile-errors.log` at repo root. Non-zero exit = unresolved failures — open the log, fix flagged files by hand, rerun.
- Scope to touched app only: `npm run i18n:compile -- --app <app-name>` (e.g. `m-finance`). Use `i18n:compile:dry` first if you want a preview without writing fixes/json.
- Templates were edited (Step 2) → confirm compiled JSON contains the new keys, and lint passes for every app/lib whose templates changed.
- Anything red → fix, rerun, only then complete.

### Step 9 — Report

```
Scanned: <N> files
Raw text wrapped with translate pipe: <R>
  ✓ apps/m-finance/.../widget.html — "Net Margin" → 'net-margin' | translate
Found: <M> translate keys
Already present: <X>
Created (en-only): <Y> YAML files
  ✓ apps/m-finance/mag_assets/i18n/s/strongly-bullish.yml
CLI translate:fix: <Z> langs filled across <Y> files
Rectified manually: <K> entries
assets:compile: ✓   lint: ✓
Dynamic/untraceable (manual action needed):
  - item.label | translate  (instrument-rankings.ts:42)
```

## Important Notes

- YAML filename = dash-case of the English text (see Scope Rules algorithm) — **only `-` separators, never `_` or camelCase**. The `i18n:compile` CLI rejects any file that does not follow dash-case; snake_case files (e.g. `one_ui_nav_dropdown_input.yml`) will fail at compile time.
- **Keys come ONLY from visible English text** — never from component names, file paths, Angular selectors, CSS class names, element IDs, or UI hierarchy paths. A name like `one-ui-nav-dropdown-input` encodes structure, not meaning. If you cannot identify the actual displayed text, skip the node and report it as untraceable.
- The filename IS the translation key used in `| translate` pipes in templates
- Never overwrite existing YAML files — check before writing
- Create the `mag_assets/i18n/<char>/` directory if it doesn't exist; use `0-9/` for digit-starting names
- New YAMLs contain ONLY `en:` — never hand-write other languages before the CLI runs; only fill gaps in Step 7
- Do not stop after creating YAMLs — Steps 6–8 (CLI, rectify, verify, lint) are mandatory before declaring done
