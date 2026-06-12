---
name: one-ui
description: Build Angular UI components using @magmonium/one library components and TranslatePipe. Use when creating or modifying Angular templates in this monorepo that need m-button, m-header, m-card, m-icon, m-input, m-tabs, or any other m-* component, or when adding translated text via the translate pipe. Enforces asset-first configs, BEM SASS, and no native HTML element violations.
---

# one-ui: Build UI with @magmonium/one

## Theme System (single source of truth)

**ThemeStore is the only authority for all colors.** When theme changes, ThemeStore writes CSS custom properties directly to `document.documentElement.style`. SASS vars are pure aliases — no hardcoded values anywhere.

### CSS custom property naming

All theme color keys from `mag_assets/theme/*.ts` are written as `--m-{kebab-case}`:

| Theme key | CSS var | SASS alias |
|---|---|---|
| `mm` | `--m-mm` | `m.$mm` |
| `background` | `--m-background` | `m.$background` |
| `textSecondary` | `--m-text-secondary` | `m.$text-secondary` |
| `backdropStandard` | `--m-backdrop-standard` | `m.$backdrop-standard` |
| `toolTipBg` | `--m-tool-tip-bg` | `m.$tooltip-bg` |
| `errorLight` | `--m-error-light` | `m.$error-light` |

### Two-tier color priority (component > global)

Components expose their own CSS vars that consumers can override. Global theme vars are the fallback:

```sass
// Component SASS sets local var, falls back to global theme var
--m-btn-color: var(--m-button-color, #{m.$mm})
//              ↑ consumer override    ↑ ThemeStore-managed global
```

To color a component instance, set the component var on the host:
```html
<!-- Host CSS: m-button { --m-button-color: var(--m-error); } -->
<m-button name="delete_btn" />
```

### SASS rules for colors

- **Always use `m.$var`** — never hardcode hex values or `var(--old-name, #fallback)`.
- **No `@media (prefers-color-scheme: dark)` blocks** — ThemeStore controls dark/light. OS media queries fight ThemeStore and break user-selected themes.
- **No `-dark` SASS variants** (`m.$background-dark` is gone). When dark theme is selected, ThemeStore sets `--m-background` to the dark value. `m.$background` reacts automatically.

```sass
// ✅ Correct
.my-block
  background: m.$background
  color: m.$text
  border-color: m.$border

// ❌ Wrong — hardcoded, won't react to theme changes
.my-block
  background: #ffffff
  color: #334955

// ❌ Wrong — OS media query fights ThemeStore
.my-block
  background: m.$background
  @media (prefers-color-scheme: dark)
    background: m.$background-dark  // m.$background-dark no longer exists
```

### Adding a new theme color

1. Add the key to all theme files in `mag_assets/theme/*.ts`
2. Run `npm run assets:compile` — generates updated JSON only (no CSS files)
3. ThemeStore reads JSON, writes `--m-{key}` to `:root` at runtime
4. Add SASS alias to `libs/sass/src/lib/variables/_colors.sass`: `$my-color: var(--m-my-color)`
5. Use in SASS: `m.$my-color`

---

## Rules (non-negotiable)

1. **Never use native HTML** where a `@magmonium/one` component exists:
   - `<h1>`–`<h6>` → `<m-header [level]="n">`
   - `<button>` → `<m-button>`
   - `<input>` → `<m-input>` or form field component
   - `<img>` → `<m-img>`
2. **Never hardcode labels/text** — always route through `| translate` with a key
3. **Never inline button/form/field/tab configs** in TypeScript — use YAML assets in `mag_assets/`
4. **Asset-first**: create the YAML, then reference by `name=` in template
5. SASS: `.sass` only, `@use 'index' as m`, BEM naming, max 3 nesting levels
6. **Asset location → `one` prop rule** (critical):
   - Asset lives in `libs/one/mag_assets/` → add `one` prop: `<m-button name="btn" one />`
   - Asset lives in app's own `mag_assets/` (e.g. `apps/m-radio/mag_assets/`) → no `one` prop: `<m-button name="btn" />`
   - Wrong location = asset not found at runtime. Always decide location before creating the YAML.
7. **Never add external classes to `m-` components** — ESLint rule `local/no-external-classes-on-m-components` blocks this at commit time.
   - Wrong: `<m-img class="my-class" ... />`
   - Fix: wrap in a `<div class="my-class">` and style the wrapper instead.

---

## Component Reference

### `m-button` / `ButtonComponent`
```html
<!-- App-specific asset (apps/<app>/mag_assets/buttons/submit_btn.yml) -->
<m-button name="submit_btn" (clicked)="onSubmit()" />

<!-- Shared asset in libs/one/mag_assets/buttons/submit_btn.yml → add `one` -->
<m-button name="submit_btn" one (clicked)="onSubmit()" />

<!-- Dynamic config (computed signal) -->
<m-button [config]="btnConfig()" (clicked)="onAction()" />

<!-- Remote app assets (fallback: one → remote → normal) -->
<m-button name="collect_btn" remote="m-wallet" (clicked)="onCollect()" />
```
- `name` → resolves YAML; location depends on `one` prop (see Asset YAML Conventions)
- `one` → look in `libs/one/mag_assets/` instead of app's `mag_assets/`
- `[config]` → `Partial<Button>` object (label, icon, primary, disabled, badge)
- `(clicked)` → emits `Button | undefined`
- `remote` → app ID (e.g. `'m-wallet'`); resolves assets from remote WC bundle; `one` + `remote` = one first, remote fallback; cascades to child icons automatically

### `m-button-group` / `ButtonGroupComponent`
```html
<m-button-group name="filter_tabs" [buttons]="overrides()" (clicked)="onTab($event)" />
```
- **No content projection** — template has no `ng-content`. Never nest `<m-button>` children inside; group is fully asset-driven via `name` (loads `mag_assets/button_groups/<name>.yml`'s `buttons: [<button-asset-names>]`) and emits ONE `(clicked)` for whichever button fired.
- `name` → `mag_assets/button_groups/<name>.yml`
- `[buttons]` → `Record<string, Partial<Button>>` for runtime overrides (e.g. per-row `disabled`, badge counts, primary state) — keyed by button asset name
- `(clicked)` → emits `Button | undefined`; branch on `button?.name` to dispatch the right handler
- `remote` → app ID; propagates to all child `m-button` and `m-context-menu`

```html
<!-- Per-row dynamic state (e.g. list of items each with own processing flag) -->
<m-button-group
  name="notification_actions"
  [buttons]="actionOverrides(item.id)"
  (clicked)="onAction($event, item.id)"
/>
```
```ts
actionOverrides = (id: string): Record<string, Partial<Button>> => ({
  approve_notification: { disabled: this.isProcessing(id) },
  reject_notification: { disabled: this.isProcessing(id) },
});
onAction = (button: Button | undefined, id: string): void => {
  if (button?.name === 'approve_notification') this.approve(id);
  else if (button?.name === 'reject_notification') this.reject(id);
};
```

### `m-header` / `HeaderComponent`
```html
<m-header [level]="2">{{ 'section_title' | translate }}</m-header>
```
- `[level]` → 1–6 (required)
- Content projected via `ng-content`

### `m-icon` / `IconComponent`
```html
<m-icon name="plus" size="sm" color="mm" />
<m-icon [name]="iconSignal()" size="lg" />
<m-icon name="custom_icon" remote="m-wallet" />
```
- `name` → SVG icon key from `mag_assets/icons/`
- `size` → `xs | sm | md | lg | xl`
- `color` → theme color token
- `remote` → app ID (e.g. `'m-wallet'`); loads SVG from remote WC bundle with `one → remote` fallback

### `m-img` / `ImgComponent`
```html
<!-- From URL -->
<m-img [src]="imageUrl()" alt="description" />

<!-- From raw base64 string (component builds the data URI) -->
<m-img [data]="base64String()" alt="UPI QR code" />

<!-- From raw base64 with custom MIME type -->
<m-img [data]="pngData()" dataType="image/png" alt="receipt" />

<!-- Non-fill with explicit dimensions -->
<m-img [src]="thumb()" alt="thumbnail" [fill]="false" [width]="200" [height]="200" />
```
- `[src]` → full URL or data URI (`data:image/...;base64,...`); optional when `[data]` is provided
- `[data]` → raw base64 string (no `data:` prefix); component constructs the data URI automatically
- `dataType` → MIME type used with `[data]` (default `'image/jpeg'`)
- `alt` → required; accessible label
- `[fill]` → `boolean`, default `true`; stretches to container
- `[priority]` → `boolean`, default `false`; skips skeleton, sets LCP hint
- `[width]` / `[height]` → used when `fill` is `false` (defaults `1200` / `1800`)
- Shows skeleton while loading, inline broken-image SVG on error
- **Never add a class to `<m-img>` directly** — wrap in a `<div class="...">` instead

### `m-card` / `CardComponent`
```html
<m-card variant="dashboard" [fullHeight]="true">
  <!-- content -->
</m-card>
```
- `variant` → `default | dashboard | flat`
- `spacing`, `fullHeight` inputs available

### `m-card-wrapper` / `CardWrapperComponent`
```html
<m-card-wrapper variant="dashboard">
  <m-header [level]="3">{{ 'title' | translate }}</m-header>
</m-card-wrapper>
```

### `m-nothing` / `NothingComponent`
```html
<m-nothing
  [icon]="emptyIcon()"
  [title]="'no_items'"
  [description]="'no_items_desc'"
  [button]="ctaButton()"
  (actionClick)="onCreate()"
/>
```
- `[icon]` → required string, icon name (e.g. `'file'`, `'pencil'`)
- `[title]` → required string, i18n key for heading
- `[description]` → optional string, i18n key for subtitle paragraph
- `buttonName` → optional string, YAML button name (preferred, resolves from `mag_assets/buttons/<name>.yml`)
- `[button]` → optional `Button` config for dynamic/computed buttons (use when name alone can't express it)
- `(actionClick)` → emits `void` when button clicked
- Renders the full empty-state block (border, padding, icon box, header, desc, CTA)
- Use instead of hand-rolling `.something__empty` + `.something__empty-icon` divs

### `m-accordion` / `AccordionComponent`
```html
<!-- Named (config from mag_assets/accordions/<name>.yml) -->
<m-accordion name="faq_item">
  <div accordion-body>Content here</div>
</m-accordion>

<!-- With inputs -->
<m-accordion label="section_title" subtitle="section_label" icon="info" variant="outlined" [open]="isOpen()" (toggled)="onToggle($event)">
  <div accordion-body>Content here</div>
</m-accordion>

<!-- Lazy body (renders only on first open) -->
<m-accordion name="heavy_section">
  <ng-template mAccordionBody>
    <my-heavy-component />
  </ng-template>
</m-accordion>

<!-- Group: only one accordion open at a time -->
<m-accordion-group name="faq_group">
  <m-accordion name="faq_1" />
  <m-accordion name="faq_2" />
</m-accordion-group>
```
- `name` → resolves YAML from `mag_assets/accordions/<name>.yml`
- `variant` → `'flat' | 'outlined' | 'glass'` (default: `'glass'`)
- `label` → i18n key for title text
- `subtitle` → i18n key for small uppercase label above title
- `icon` → icon name for left icon; `null` suppresses config icon
- `open` → controlled mode: `boolean` binding; parent must update via `(toggled)` to change state
- `(toggled)` → emits `boolean` on toggle; in controlled mode parent must react to update `open`
- `[accordion-header]` slot → replaces generated title/subtitle with custom content
- `[accordion-body]` slot → standard body content (always in DOM)
- `ng-template[mAccordionBody]` → lazy body via `AccordionBodyDirective` (instantiated only on first open)
- `isOpen` → public computed signal; read current open state from component ref
- Group: `m-accordion-group name="..."` → `mag_assets/accordion_groups/<name>.yml`; enforces single-open

### `m-one-form` / `FormGroupComponent`
```html
<m-one-form
  name="my_form"
  [(data)]="formData"
  [(state)]="formState"
  [validation]="validationSchema"
  [options]="{ field_name: dropdownOptions() }"
  [fieldConfigs]="{ field_name: { readonly: true } }"
  [elements]="{ field_name: MyContentComponent }"
  [datas]="{ field_name: cardItems() }"
  (act)="onAct($event)"
  (dataChange)="onDataChange($event)"
/>
```
- `name` → resolves YAML from `mag_assets/forms/<name>.yml`; form lists field names in `inputs`
- `remote` → app ID; propagates to all child `m-input-wrapper` instances
- `[(data)]` → two-way bound `Record<string, unknown>` form values
- `[(state)]` → two-way bound `FormState` (invalid, dirty, touched, etc.)
- `[validation]` → `SchemaOrSchemaFn` for `@angular/forms/signals` validation
- `[options]` → `Record<string, DropdownOption[] | Signal<DropdownOption[]>>` per-field dropdown options
- `[fieldConfigs]` → `Record<string, Partial<Input>>` per-field config overrides
- `[elements]` → `Record<string, Type<unknown>>` per-field component class for `selectable_card` fields
- `[datas]` → `Record<string, SelectableCardItem[]>` per-field item list for `selectable_card` fields
- `(act)` → emits `Record<string, unknown>` on form submit
- `(dataChange)` → emits `Record<string, unknown>` on any field value change

### Translation Pipe / `TranslatePipe`
```html
{{ 'my_key' | translate }}
{{ 'greeting' | translate: { name: user() } }}
```
- Keys map to YAML files: `mag_assets/i18n/<first-letter>/<key>.yml`
- Each key YAML contains `en:`, `es:`, `fr:`, etc.
- **Never put raw strings in templates** — always use a translation key

---

## Asset YAML Conventions

### Where to put the YAML — decides whether to use `one` prop

| Scenario | YAML goes in | Template usage |
|---|---|---|
| Shared across all apps, belongs to design system | `libs/one/mag_assets/<type>/<name>.yml` | `<m-button name="btn" one />` |
| App-specific, only used in this app | `apps/<app>/mag_assets/<type>/<name>.yml` | `<m-button name="btn" />` |

**Decide location first. Creating the YAML in the wrong place = silent 404 at runtime.**

### YAML structure by type

| UI element | Subfolder | Key fields |
|---|---|---|
| Button | `buttons/<name>.yml` | `label`, `icon`, `primary`, `disabled` |
| Button group | `button_groups/<name>.yml` | `color`, `buttons: []` |
| Form | `forms/<name>.yml` | `inputs: [[field1], [field2]]` |
| Field | `fields/<name>.yml` | `type`, `label`, `placeholder` |
| Header | `headers/<name>.yml` | `level`, `label` |
| Tab set | `tabs/<name>.yml` | `variant`, `tabs: []` |
| Nav | `navs/<name>.yml` | `items: []` |

Button YAML example (app-specific → `apps/m-radio/mag_assets/buttons/create_app_btn.yml`):
```yaml
label: create_app
icon: plus
primary: true
```

Same button if shared (`libs/one/mag_assets/buttons/create_app_btn.yml`) → template uses `one`:
```html
<m-button name="create_app_btn" one (clicked)="onCreate()" />
```

After creating/editing YAML: run `npm run assets:compile`.

---

## Component Template

```typescript
@Component({
  selector: 'feature-my-component',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ButtonComponent, HeaderComponent, IconComponent, TranslatePipe],
  template: `
    <section class="my-component">
      <m-header [level]="2">{{ 'section_title' | translate }}</m-header>

      @if (items().length > 0) {
        <!-- content -->
      } @else {
        <div class="my-component__empty">
          <m-icon name="inbox" size="lg" />
          <m-header [level]="4">{{ 'no_items' | translate }}</m-header>
          <m-button name="create_item_btn" (clicked)="onCreate()" />
        </div>
      }
    </section>
  `,
  styleUrl: './my-component.sass',
})
export class MyComponent {
  protected readonly items = signal<Item[]>([]);
  protected onCreate = (): void => { /* ... */ };
}
```

SASS template:
```sass
@use 'index' as m

.my-component
  // block styles

  &__empty
    display: flex
    flex-direction: column
    align-items: center
    gap: 1rem
```

### `m-stepper` / `StepperComponent`
```html
<m-stepper name="create_app" />
<m-stepper [config]="stepperCfg()" />
```
- `name` → `mag_assets/stepper/<name>.yml`
- `[config]` → `Partial<Stepper>`: `{ steps, progress, selected, orientation, responsive, readonly, disabled }`
- `orientation` → `'vertical' | 'header' | 'compact'`
  - `vertical` — list of steps with inline prev/next nav in active step
  - `header` — shows current step only: icon circle + "STEP N/total" + title + underline
  - `compact` — mobile-optimised: SVG circular progress ring ("X/Y") + step title + "Next: …" hint + Back/Next nav row. Default on mobile.
- `responsive` → `{ mobile?: 'vertical' | 'header' | 'compact', desktop?: 'vertical' | 'header' | 'compact' }`. Mobile defaults to `compact`, desktop to `vertical` when not set.
- `steps` → `StepperStep[]`: `{ label, icon?, description?, disabled? }`
  - `icon` used for active/pending circles; falls back to step number if absent
- `progress` → index of last completed step (0-based)
- `selected` → index of currently viewed step
- `[initialSelected]` / `[initialProgress]` → one-time init inputs
- `[disabled]` → disables forward navigation

---

### `m-user-nav` / `UserNavComponent`
```html
<m-user-nav />
```
- Registered via `provideUserTabs(tabs: Record<string, Type<unknown>>)` as the `root_user` nav widget
- Renders profile banner + `m-profile-card` + dynamic tab bar + tab content
- Tabs sourced from `LoginStore.resolvedUserTabs()` — remote tabs first, then host tabs
- Tab buttons loaded from `buttons/{tabId}.yml` per tab via `AssetStore.resolve()`
- `m-tabs` only shown when `resolvedTabs().length > 1` (single tab → content shown directly)
- Tab content: CE via `m-ce-outlet [tag]` (remote), or `ngComponentOutlet` (local)
- Remote asset resolution now uses `config.remote` (app ID) — `REMOTE_ASSET_BASE_URL` token removed

### `m-profile-card` / `ProfileCardComponent`
```html
<m-profile-card [user]="user()" (menuAction)="handleMenuAction($event)">
  <!-- projected: tabs + content -->
</m-profile-card>
```
- `[user]` → `User | null | undefined` — displays avatar, full name, username, bio, join date, followers
- `(menuAction)` → `EventEmitter<MenuItem>` — action from `m-context-menu[name="user_header"]`
- `<ng-content />` — projects tabs nav card + content below identity section

### `provideUserTabs(tabs)` — DI function
```ts
import { provideUserTabs } from '@magmonium/one';

provideUserTabs({
  posts: CreatePostComponent,
  apps: CreateAppComponent,
})
```
- Returns `Provider[]`: sets `USER_TAB_MAP` token + registers `root_user → UserNavComponent` nav widget
- Call in `ApplicationConfig.providers` — replaces manual `provideNavWidgets({ root_user: ... })`
- Remote apps register tabs via `window.__mag_register_user_tabs__(remoteId, { tabId: ceSelector })`

---

## Checklist

- [ ] All headings use `m-header [level]`
- [ ] All buttons use `m-button` with `name` or `[config]` — no `<button>`
- [ ] All text uses `| translate` with a key
- [ ] Button/form configs defined in YAML, not inline TS
- [ ] Asset in `libs/one/mag_assets/` → `one` prop on component; asset in app's `mag_assets/` → no `one` prop
- [ ] New i18n key has a YAML file in `mag_assets/i18n/<letter>/`
- [ ] New icon is in `mag_assets/icons/` (not directly in `assets/`)
- [ ] SASS uses `@use 'index' as m`, BEM, max 3 nesting levels
- [ ] `imports[]` includes all used components/pipes
- [ ] `ChangeDetectionStrategy.OnPush` set
- [ ] Signals for state, arrow functions for methods
- [ ] `npm run assets:compile` run after YAML changes
