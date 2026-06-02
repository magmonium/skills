---
name: mm-app
description: Use when creating or configuring a new Magmonium WC app in the nx monorepo — bootstrapping, nav widgets, asset setup, module federation, providers pattern
---

# Magmonium App Creation & Configuration

## Overview

Every Magmonium app is an Angular Web Component (WC) that can run standalone OR embedded in m-ui host. Apps live in `apps/m-<name>/`, expose via Module Federation, and are configured through YAML assets — not TypeScript.

---

## Required File Structure

```
apps/m-<name>/
  src/
    main.ts                        # Dynamic import → bootstrap
    bootstrap.ts                   # bootstrapMagApp()
    environments/
      environment.ts               # local dev: localhost:8000
      environment.dev.ts           # remote dev: api-dev.magmonium.com
    app/
      wc.ts                        # Root WC component (BaseRootWebComponent)
      wc.config.ts                 # provideMagWcConfig (used by wc-element mode)
      wc.routes.ts                 # Route definitions
      providers.ts                 # Nav widgets, tokens
  module-federation.config.ts      # Exposes ./App
  webpack.config.ts                # withModuleFederation
  project.json                     # Nx targets with dependsOn
  mag_assets/
    remote/m-<name>.yml            # WC manifest (REQUIRED)
    navs/root.yml                  # App title (REQUIRED)
    navs/settings.yml              # If app has settings nav items
```

---

## 1. Entry Points

**`src/main.ts`** — always the same:
```ts
import('./bootstrap').catch((err) => console.error(err));
```

**`src/bootstrap.ts`:**
```ts
import '@angular/compiler';
import { bootstrapMagApp } from '@magmonium/one';
import { wcRoutes } from './app/wc.routes';
import { environment } from './environments/environment';
import { myProviders } from './app/providers';
import { MyWebComponent } from './app/wc';

bootstrapMagApp({
  backend: environment.url,
  socketUrl: environment.socketUrl,
  root: MyWebComponent,
  children: wcRoutes,
  providers: myProviders,
});
```

---

## 1b. Environment Files

Two env files, two purposes:

**`environment.ts`** — used by `serve` (default `development` config, no fileReplacements):
```ts
export const environment = {
  production: false,
  url: 'http://localhost:8000',          // local backend
  socketUrl: 'wss://pops-dev.magmonium.com/<name>',
};
```

**`environment.dev.ts`** — used by `build:dev` config (fileReplacements) for CI/remote dev builds:
```ts
export const environment = {
  production: false,
  url: 'https://api-dev.magmonium.com',  // remote dev API
  socketUrl: 'wss://pops-dev.magmonium.com/<name>',
};
```

**How it wires up in `project.json`:**
```json
"build": {
  "configurations": {
    "development": { /* no fileReplacements → uses environment.ts (localhost) */ },
    "dev": {
      "fileReplacements": [
        { "replace": "apps/m-<name>/src/environments/environment.ts",
          "with":    "apps/m-<name>/src/environments/environment.dev.ts" }
      ]
    }
  }
},
"serve": {
  "defaultConfiguration": "development"  // → build:development → localhost
}
```

**Common mistake:** putting LAN IP (`192.168.1.67:8000`) in `environment.ts` — breaks local dev for anyone not on that machine. Always use `localhost:8000`.

---

## 2. Root Web Component (`wc.ts`)

```ts
import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { BaseRootWebComponent, NavComponent } from '@magmonium/one';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'mx-<name>-wc',          // prefix convention: first letter(s) of name
  imports: [CommonModule, RouterOutlet, NavComponent],
  template: `
    <main class="<name>-main">
      <router-outlet></router-outlet>
    </main>
    <m-nav [showLogo]="false" />      // REQUIRED for standalone mode settings access
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyWebComponent extends BaseRootWebComponent implements OnInit {
  ngOnInit() {}
}
```

**`<m-nav [showLogo]="false" />`** — mandatory. Without it, standalone mode has no nav, so settings/equalizer/organize widgets are unreachable. Embedded mode ignores it (host renders its own nav).

---

## 3. App Config (`wc.config.ts`)

```ts
import { ApplicationConfig } from '@angular/core';
import { provideMagWcConfig, provideMagWcRoutes, RouteContainer } from '@magmonium/one';
import { wcRoutes } from './wc.routes';
import { environment } from '../environments/environment';
import { myProviders } from './providers';

export const appConfig: ApplicationConfig = provideMagWcConfig({
  backend: environment.url,
  routes: provideMagWcRoutes({ component: RouteContainer, children: wcRoutes }),
  providers: myProviders,
});
```

---

## 4. Providers (`providers.ts`)

Minimum required tokens + nav widget registration:

```ts
import { ApplicationConfig } from '@angular/core';
import {
  ASSET_BASE_URL, ONE_ASSET_BASE_URL,
  NAV_DEFAULT_MURL,
  provideNavWidgets, settingsWidgets,
  NAV_WC_COMPONENTS,
} from '@magmonium/one';
import { MySettingsComponent } from './widgets/my-settings/my-settings';

export const myProviders: ApplicationConfig['providers'] = [
  { provide: ASSET_BASE_URL, useValue: '/assets' },
  { provide: ONE_ASSET_BASE_URL, useValue: '/assets' },
  { provide: NAV_DEFAULT_MURL, useValue: 'my-default-route' },  // route opened on nav toggle
  ...provideNavWidgets({
    ...settingsWidgets(),                  // includes user/theme/language
    root_settings_myfeature: {
      content: MySettingsComponent,
      breadcramb: { header: { icon: 'settings', label: 'myfeature_i18n_key', id: 'root_settings_myfeature' } },
    },
  }),
  {
    provide: NAV_WC_COMPONENTS,
    useValue: [MySettingsComponent],       // REQUIRED for cross-bundle rendering
  },
];
```

**Widget ID convention:** `root_settings_<feature>` → nav path `settings/<feature>` → YAML `navs/settings.yml` must list `<feature>` in `navs`.

---

## 5. Routes (`wc.routes.ts`)

```ts
import { Route } from '@angular/router';

export const wcRoutes: Route[] = [
  {
    path: '',
    pathMatch: 'full',
    loadChildren: () => import('./pages/home/routes').then(m => m.routes),
  },
  { path: '**', redirectTo: '' },
];
```

---

## 6. Module Federation

**`module-federation.config.ts`:**
```ts
import { ModuleFederationConfig } from '@nx/module-federation';

const config: ModuleFederationConfig = {
  name: 'm-<name>',
  remotes: [],
  exposes: { './App': 'apps/m-<name>/src/bootstrap.ts' },
  shared: () => false,
};
export default config;
```

**`webpack.config.ts`:**
```ts
import { withModuleFederation } from '@nx/module-federation/angular';
import config from './module-federation.config';

export default withModuleFederation(config, { dts: false });
```

---

## 7. YAML Assets (Required)

**`mag_assets/remote/m-<name>.yml`** — WC manifest:
```yaml
app: m-<name>
version: 0.0.1
company: Magmonium Media
componentPath: apps/m-<name>/src/app
componentName: wc
className: MyWebComponent
appConfigPath: apps/m-<name>/src/app/wc.config
selector: mx-<name>-wc
```

**`mag_assets/navs/root.yml`** — minimum:
```yaml
title: <name>
```

**`mag_assets/navs/settings.yml`** — if app has custom settings widgets:
```yaml
title: settings
icon: settings
navs:
  - myfeature        # must match last segment of root_settings_myfeature
```

**`mag_assets/navs/myfeature.yml`** — child nav entries:
```yaml
title: myfeature_i18n_key
icon: settings
```

After any YAML change: `npm run assets:compile`

---

## 8. project.json (Key Parts)

```json
{
  "targets": {
    "serve": {
      "options": { "port": 42XX },
      "dependsOn": ["cli:build", "sass:build", "one:build"]
    },
    "build": {
      "options": {
        "stylePreprocessorOptions": {
          "includePaths": ["libs/sass/src/lib", "libs/sass/src", "."]
        },
        "assets": [
          { "glob": "**/*", "input": "apps/m-<name>/public" },
          { "glob": "**/*", "input": "libs/one/assets", "output": "assets/one" }
        ]
      }
    }
  }
}
```

`dependsOn` is mandatory — without it, sass/one may not be built before the app.

---

## Nav Widget System — Key Rules

| Widget ID | Nav path | Fetches YAML |
|-----------|----------|-------------|
| `root_stations` | `stations` | `navs/stations.yml` (if exists) |
| `root_settings` | `settings` | `navs/settings.yml` |
| `root_settings_eq` | `settings/eq` | resolved from widget breadcramb |

- Widget IDs that exist in the widgetMap are **not** fetched from assets
- Parent IDs (e.g. `root_settings`) ARE fetched — add `settings.yml` with `navs` children
- Labels in nav menu use `| translate` — `title` in YAML must be an i18n key

---

## 9. User Nav Widget (`widgets/user/ui/user-nav/`)

Apps can inject content into the nav's user panel via `provideUserTabs`. Pattern from m-wallet (`WalletCollectComponent`) and m-radio (`RadioUserNavComponent`).

**`providers.ts`:**
```ts
import { provideUserTabs } from '@magmonium/one';
import { MyUserNavComponent } from './widgets/user/ui/user-nav/user-nav';

export const myProviders = [
  ...provideUserTabs({
    mykey: MyUserNavComponent,   // key is the tab identifier
  }),
  ...provideNavWidgets({ ... }),
];
```

**`widgets/user/ui/user-nav/user-nav.ts`:**
```ts
@Component({
  selector: 'mx-user-nav',
  imports: [ButtonComponent, TranslatePipe],
  template: `
    <div class="user-nav">
      <!-- content area -->
      <div class="user-nav__cta">
        <m-button name="my_cta_btn" (clicked)="onCta()" />
      </div>
    </div>
  `,
  styleUrl: './user-nav.sass',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyUserNavComponent {
  readonly #router = inject(Router);
  protected readonly onCta = (): void => { void this.#router.navigate(['target']); };
}
```

**`widgets/user/ui/user-nav/user-nav.sass`:**
```sass
@use 'index' as m

.user-nav
  display: flex
  flex-direction: column
  gap: 2rem
  padding: 1.5rem
  height: 100%
  overflow-y: auto
  scrollbar-width: none
  &::-webkit-scrollbar
    display: none
```

**Key rules:**
- `provideUserTabs` must come BEFORE `provideNavWidgets` in the providers array
- It auto-registers `root_user` nav widget — no manual nav widget entry needed
- Button assets go in `mag_assets/buttons/`, i18n in `mag_assets/i18n/<letter>/`
- Run `npm run assets:compile` after adding any new YAML asset

---

## Standalone vs Embedded Mode

| | Standalone (direct URL) | Embedded (m-ui host) |
|---|---|---|
| Nav | `<m-nav>` in `wc.ts` | Host renders `<m-nav [isHost]="true">` |
| Settings path | Fetches from app's `/assets/navs/` | Fetches from host's `/assets/navs/` |
| `APP_BASE_HREF` | `/` | `/app/m-<name>` |
| `assetStore.appId` | `undefined` | `m-<name>` |

In standalone, omitting `<m-nav>` = no settings access. Always include it.

---

## 10. CI/CD Pipeline

Every WC app needs a GitHub Actions workflow at `.github/workflows/m-<name>-wc.yml`. Pattern is identical across all apps — only the app name and secrets change.

**Trigger:** push/PR to `dev`, path-filtered to `apps/m-<name>/**` + the workflow file itself.

**Jobs:** `version-check` → `build` → `deploy` (deploy only on push to `dev`, not PRs).

**Gate:** deploy only fires when `mag_assets/remote/m-<name>.yml` version field actually changed. No version bump = no deploy.

**Template** (copy, replace `<name>` and `<NAME>`):

```yaml
name: m-<name> Web Component CI/CD

on:
  push:
    branches:
      - dev
    paths:
      - 'apps/m-<name>/**'
      - '.github/workflows/m-<name>-wc.yml'
  pull_request:
    branches:
      - dev
    paths:
      - 'apps/m-<name>/**'
      - '.github/workflows/m-<name>-wc.yml'

jobs:
  version-check:
    name: Check Version Change
    runs-on: ubuntu-latest
    outputs:
      changed: ${{ steps.check.outputs.changed }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check if version changed
        id: check
        run: |
          FILE="apps/m-<name>/mag_assets/remote/m-<name>.yml"
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            BASE_SHA="${{ github.event.pull_request.base.sha }}"
          else
            BASE_SHA="$(git rev-parse HEAD~1)"
          fi
          CHANGED=$(git diff ${BASE_SHA} HEAD --name-only | grep -c "^${FILE}$" || true)
          if [ "$CHANGED" -gt "0" ]; then
            PREV=$(git show ${BASE_SHA}:${FILE} 2>/dev/null | grep '^version:' | awk '{print $2}' || echo "")
            CURR=$(grep '^version:' ${FILE} | awk '{print $2}')
            if [ "$PREV" != "$CURR" ]; then
              echo "changed=true" >> $GITHUB_OUTPUT
              echo "Version changed: $PREV → $CURR"
            else
              echo "changed=false" >> $GITHUB_OUTPUT
              echo "Version unchanged: $CURR (skipping)"
            fi
          else
            echo "changed=false" >> $GITHUB_OUTPUT
            echo "File not modified (skipping)"
          fi

  build:
    name: Build & Package Assets
    needs: version-check
    if: needs.version-check.outputs.changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'yarn'
      - name: Install dependencies
        run: yarn install --frozen-lockfile --network-timeout 300000
        env:
          NODE_OPTIONS: --dns-result-order=ipv4first
      - name: Build assets and web component
        run: |
          npx nx build cli
          node dist/libs/cli/bin/cli.js assets-wc --config ./mag-cli.config.js --app m-<name>
          node scripts/patch-wc-env.js --app m-<name>
        env:
          BUILD_CONFIG: dev
      - name: Package as bundle.zip
        if: github.ref == 'refs/heads/dev' && github.event_name == 'push'
        run: cd dist/apps/m-<name>-wc && zip -r ../../../bundle.zip .
      - name: Upload WC artifact
        if: github.ref == 'refs/heads/dev' && github.event_name == 'push'
        uses: actions/upload-artifact@v4
        with:
          name: m-<name>-wc
          path: bundle.zip
          retention-days: 1

  deploy:
    name: Deploy to Magmonium
    needs: build
    if: github.ref == 'refs/heads/dev' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Download WC artifact
        uses: actions/download-artifact@v4
        with:
          name: m-<name>-wc
      - name: Upload bundle to backend
        run: |
          ENDPOINT="${{ secrets.MAG_ENDPOINT }}"
          ENDPOINT="${ENDPOINT%/}"
          APP_ID="${{ secrets.MAG_APP_ID_M_<NAME> }}"
          APP_ID="${APP_ID//[$'\t\r\n ']/}"
          curl -f -X POST \
            -H "Authorization: Bearer ${{ secrets.MAG_DEPLOY_TOKEN_M_<NAME> }}" \
            -F "bundle=@bundle.zip" \
            "${ENDPOINT}/store/v1/bundle/${APP_ID}"
      - name: Trigger deployment
        run: |
          ENDPOINT="${{ secrets.MAG_ENDPOINT }}"
          ENDPOINT="${ENDPOINT%/}"
          APP_ID="${{ secrets.MAG_APP_ID_M_<NAME> }}"
          APP_ID="${APP_ID//[$'\t\r\n ']/}"
          curl -f -X POST \
            -H "Authorization: Bearer ${{ secrets.MAG_DEPLOY_TOKEN_M_<NAME> }}" \
            "${ENDPOINT}/store/v1/deploy/${APP_ID}"
```

**GitHub Secrets required** (GitHub → Settings → Secrets → Actions):

| Secret | Shared? |
|--------|---------|
| `MAG_ENDPOINT` | Yes — already exists |
| `MAG_DEPLOY_TOKEN_M_<NAME>` | Per-app — get from Magmonium backend |
| `MAG_APP_ID_M_<NAME>` | Per-app — get from Magmonium backend |

**Checklist:**
- [ ] Register app in Magmonium backend → get token + app ID
- [ ] Add `MAG_DEPLOY_TOKEN_M_<NAME>` and `MAG_APP_ID_M_<NAME>` to GitHub secrets
- [ ] Create `.github/workflows/m-<name>-wc.yml` from template above
- [ ] Bump version in `mag_assets/remote/m-<name>.yml` to trigger first deploy

**Build output path:** `dist/apps/m-<name>-wc` (set by the cli `assets-wc` command, not `project.json`).

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No `<m-nav>` in `wc.ts` | Settings/widgets unreachable standalone — always add `<m-nav [showLogo]="false" />` |
| Missing `settings.yml` with `navs` | Settings sub-items don't appear in nav panel |
| Widget child segment ≠ YAML nav child name | Nav shows wrong items or empty |
| `title` in nav YAML is raw text, not i18n key | Untranslated label shown |
| Editing compiled JSON directly | Overwritten by `assets:compile` — edit YAML only |
| Adding `.gitignore` to `public/assets/` | Root `.gitignore` already ignores `apps/m-<name>/public/assets/` — no per-app gitignore needed |
| Missing `NAV_WC_COMPONENTS` provider | Widget fails to render cross-bundle |
| No `dependsOn` in project.json serve | Build fails — sass/one not ready |
| Wrong selector in remote yml | WC doesn't mount in m-ui |
| LAN IP in `environment.ts` | Local serve hits `192.168.x.x:8000` not `localhost` — use `http://localhost:8000` |
| `environment.dev.ts` pointing to LAN IP | CI/remote dev build hits wrong backend — should be `https://api-dev.magmonium.com` |
