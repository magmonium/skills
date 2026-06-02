---
name: translate
description: Use when asked to /translate — scans Angular templates for | translate pipe usages, finds missing i18n keys, and creates the appropriate YAML asset files in the correct mag_assets/i18n/ folder based on where the component lives.
---

# translate

## Overview

Scans Angular component templates for `| translate` pipe usages, identifies keys missing from compiled i18n JSON, and creates missing YAML files in the correct scope's `mag_assets/i18n/` folder with **proper translations** for all required languages.

## Scope Rules

| Component lives in | Create YAML in | Check compiled JSON at |
|---|---|---|
| `libs/one/**` | `libs/one/mag_assets/i18n/` | `libs/one/assets/i18n/en.json` |
| `apps/m-finance/**` | `apps/m-finance/mag_assets/i18n/` | `apps/m-finance/public/assets/i18n/en.json` |
| `apps/m-comics/**` | `apps/m-comics/mag_assets/i18n/` | `apps/m-comics/public/assets/i18n/en.json` |
| `apps/m-ui/**` | `apps/m-ui/mag_assets/i18n/` | `apps/m-ui/public/assets/i18n/en.json` |

YAML path: `<scope_root>/mag_assets/i18n/<first_char_of_key>/<key>.yml`

## Process

### Step 1 — Resolve scope

If a file path argument is given, scope = the app/lib that file belongs to.
If no argument, scan all `.ts` files across the entire repo.

### Step 2 — Extract translate keys

Grep for `| translate` in templates. Handle three patterns:

**Static string:**
```
'key_name' | translate   →  key = key_name
"key_name" | translate   →  key = key_name
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
return { label: 'strongly_bullish' }  →  key = strongly_bullish
return { label: 'bullish_support' }   →  key = bullish_support
```

**Untraceable** (data from API, e.g. `item.label | translate`):
→ Report as `DYNAMIC/UNTRACEABLE`, skip YAML creation.

### Step 3 — Check existing keys

For each key:
1. **Check `libs/one` first** (always): `libs/one/mag_assets/i18n/<char>/<key>.yml` — if found, skip creation regardless of scope. The shared lib serves all apps.
2. Look in compiled JSON: `<scope>/public/assets/i18n/en.json` (or `assets/i18n/en.json` for libs/one)
3. Also check if YAML source already exists: `<scope>/mag_assets/i18n/<char>/<key>.yml`

Skip if found in any of the above.

**Deduplication rule**: if same filename already exists in ≥2 apps and not in `libs/one`, do NOT create another copy. Instead flag it:
```
⚠ DUPLICATE: <key>.yml found in [app-a, app-b] — move the copy with most translations to libs/one/mag_assets/i18n/<char>/<key>.yml and delete app copies.
```

### Step 4 — Get language list for scope

Sample an existing YAML in the same scope to get the authoritative language codes:

```bash
cat libs/one/mag_assets/i18n/h/high_52w.yml        # for libs/one scope
cat apps/m-finance/mag_assets/i18n/p/profit.yml    # for apps/m-finance scope
```

Use the exact same language codes and order from that file for all new YAMLs.

### Step 5 — Create missing YAML files with proper translations

For each missing key, write `<scope>/mag_assets/i18n/<first_char>/<key>.yml`.

**English value**: Humanize the key:
- Replace `_` with space, title-case each word
- Preserve known abbreviations: `PE`, `PB`, `EPS`, `SMA`, `PNL`, `CAGR`, `ETF`
- `strongly_bullish` → `Strongly Bullish`, `pe_ratio` → `PE Ratio`, `high_52w` → `52W High`, `sma_50` → `SMA 50`

**All other languages**: Provide **proper translations** using multilingual knowledge. Do NOT copy the English value — translate the concept accurately for each language.

Example for `strongly_bullish` in `apps/m-finance/`:
```yaml
en: Strongly Bullish
bn: দৃঢ়ভাবে ঊর্ধ্বমুখী
hi: मजबूत तेजी
fr: Fortement Haussier
es: Fuertemente Alcista
it: Fortemente Rialzista
ja: 強い強気
ko: 강한 강세
pt: Fortemente Altista
ru: Сильный бычий тренд
zh: 强烈看涨
```

Example for `net_margin` in `apps/m-finance/`:
```yaml
en: Net Margin
bn: নিট মার্জিন
hi: शुद्ध मार्जिन
fr: Marge Nette
es: Margen Neto
it: Margine Netto
ja: 純利益率
ko: 순이익률
pt: Margem Líquida
ru: Чистая маржа
zh: 净利润率
```

Example for `financial_history` in `apps/m-finance/`:
```yaml
en: Financial History
bn: আর্থিক ইতিহাস
hi: वित्तीय इतिहास
fr: Historique Financier
es: Historial Financiero
it: Storia Finanziaria
ja: 財務履歴
ko: 재무 이력
pt: Histórico Financeiro
ru: Финансовая История
zh: 财务历史
```

**Conciseness principle**: Financial/UI labels should be short. Keep translations concise — match the character density of nearby labels.

### Step 6 — Report

```
Scanned: <N> files
Found: <M> translate keys
Already present: <X>
Created: <Y> YAML files
  ✓ apps/m-finance/mag_assets/i18n/s/strongly_bullish.yml
  ✓ apps/m-finance/mag_assets/i18n/n/neutral.yml
  ...
Dynamic/untraceable (manual action needed):
  - item.label | translate  (instrument-rankings.ts:42)

Run `npm run assets:compile` to rebuild i18n JSON.
```

## Important Notes

- YAML filename = the exact translation key (snake_case)
- Never overwrite existing YAML files — check before writing
- Create the `mag_assets/i18n/<char>/` directory if it doesn't exist
- Do NOT run `npm run assets:compile` automatically — remind the user at the end
