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
    remote/m-<name>.yml            # WC manifest + optional PWA config (REQUIRED)
    navs/root.yml                  # App title (REQUIRED)
    navs/settings.yml              # If app has settings nav items
    pwa/icon.svg                   # Source icon for PWA (if PWA enabled)
  workbox-config.cjs               # Workbox SW config (if PWA enabled)
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
import { BaseRootWebComponent } from '@magmonium/one';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'mx-<name>-wc',          // prefix convention: first letter(s) of name
  imports: [CommonModule, RouterOutlet],
  template: `
    <main class="<name>-main">
      <router-outlet></router-outlet>
    </main>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyWebComponent extends BaseRootWebComponent implements OnInit {
  ngOnInit() {}
}
```

**Never add `<m-nav />` here.** `FrameComponent` (used by `OneApp` in `bootstrapMagApp`) already renders `<m-nav />` in standalone mode. `m-ui` renders `<m-nav [isHost]="true" />` in embedded mode. Adding it to `wc.ts` duplicates the nav in **both** modes.

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

Nav widget registration + cross-bundle CE support:

```ts
import { ApplicationConfig } from '@angular/core';
import {
  provideNavWidgets, settingsWidgets,
  NAV_WC_COMPONENTS,
  provideUserTabs,
} from '@magmonium/one';
import { MySettingsComponent } from './widgets/my-settings/my-settings';
import { MyUserNavComponent } from './widgets/user/ui/user-nav/user-nav';

export const myProviders: ApplicationConfig['providers'] = [
  ...provideUserTabs({ mykey: MyUserNavComponent }),  // if app has user nav tab
  ...provideNavWidgets({
    ...settingsWidgets(),                  // includes user/theme/language
    root_myfeature: {
      content: MySettingsComponent,
      selector: 'mx-my-settings',         // REQUIRED: Angular selector = CE tag
      breadcramb: { header: { icon: 'play', label: 'myfeature_i18n_key', id: 'root_myfeature' } },
    },
    root_settings_myfeature: {
      content: MySettingsComponent,
      selector: 'mx-my-settings',         // REQUIRED: Angular selector = CE tag
      breadcramb: { header: { icon: 'settings', label: 'myfeature_i18n_key', id: 'root_settings_myfeature' } },
    },
  }),
  {
    provide: NAV_WC_COMPONENTS,
    useValue: [MySettingsComponent],       // REQUIRED: registers as CE for cross-bundle rendering
  },
];
```

**`ASSET_BASE_URL` / `ONE_ASSET_BASE_URL`** — do NOT add these to providers. The WC wrapper overrides `ASSET_BASE_URL` dynamically at runtime; `HttpService`/`ThemeStore` have `/assets` fallback. Adding them causes stale values in remote mode.

**`NAV_DEFAULT_MURL`** — optional. If omitted, menu opens to the nav root (user clicks a specific item). If provided, menu toggle jumps directly to that nav path.

**`selector` field in `NavWidgetConfig`** — must match the Angular `@Component` selector. `BaseRootWebComponent` registers these components as custom elements using `NAV_WC_COMPONENTS`; `resolvedWidget` uses `selector` as the CE tag. Without explicit `selector`, cross-bundle rendering fails.

**Widget ID convention:**
- `root_<feature>` → murl `/app/<appname>/<feature>` → embeddedId = `root_<feature>`
- `root_settings_<feature>` → nav path `settings/<feature>` → YAML `navs/settings.yml` must list `<feature>` in `navs`

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

> **m-ui is NOT a webpack app.** `apps/m-ui` uses `@nx/angular:application` (esbuild executor) — no `customWebpackConfig`, no `ModuleFederationPlugin`. WC apps (`m-comics`, `m-finance`, etc.) still use `@nx/angular:webpack-browser` + `withModuleFederation`. Do not copy m-ui's `project.json` build executor when scaffolding a new WC app.

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

**`mag_assets/remote/m-<name>.yml`** — WC manifest + optional PWA config:
```yaml
app: <slug>                               # short slug WITHOUT m- prefix (e.g. comics, finance, radio)
version: 0.0.1
company: Magmonium Media
componentPath: apps/m-<name>/src/app
componentName: wc
className: MyWebComponent
appConfigPath: apps/m-<name>/src/app/wc.config
selector: mx-<name>-wc
pwa:                                      # optional — enables PWA install button in m-ui footer
  desc: Magmonium <Name> — short tagline
  color: '#121212'                        # theme_color in manifest
  bgcolor: '#121212'                      # background_color in manifest
```

**`app:` slug rule:** Use the short name WITHOUT the `m-` prefix — `comics`, `finance`, `wallet`, `radio`. This value becomes the path segment in `/store/v1/wc/<slug>/pwa/` on both the backend and the `baseHref`. The `mag_assets_env/{env}/remote/` override files must use the same short slug.

Presence of `pwa:` object = PWA enabled. `name` and `short_name` are auto-derived from the `app` field (`radio` → `Radio` / `Radio`). Omit `pwa:` entirely to disable.

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

After any YAML change — choose the targeted script (faster):

| Changed assets in… | Run |
|---|---|
| `libs/one/mag_assets` or `apps/m-ui/mag_assets` | `npm run assets:ui` |
| `apps/m-comics/mag_assets` | `npm run assets:comics` |
| `apps/m-finance/mag_assets` | `npm run assets:finance` |
| `apps/m-radio/mag_assets` | `npm run assets:radio` |
| `apps/m-wallet/mag_assets` | `npm run assets:wallet` |
| Everything (all apps) | `npm run assets:compile` |

`assets:<appname>` compiles only `libs/one` + target app assets (WC apps also run WC bundle + PWA). `assets:ui` compiles one + m-ui only, skips WC/PWA. `assets:compile` compiles all paths.

---

## 7b. PWA Configuration

When `pwa:` is present in `mag_assets/remote/m-<name>.yml`, the full PWA pipeline activates during `npm run assets:wc`.

### Required additions

**`mag_assets/pwa/icon.svg`** — source icon, scaled to 192×512px by PwaCompiler:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="96" fill="#121212"/>
  <text x="256" y="320" font-family="system-ui,sans-serif" font-size="260" font-weight="700"
        text-anchor="middle" fill="#ffffff">N</text>
</svg>
```
Replace letter and colors to match the app. This is a placeholder — swap for real icon later.

**`src/index.html`** — add manifest link + SW registration before `</head>`:
```html
<link rel="manifest" href="manifest.json" />
<meta name="theme-color" content="#121212" />   <!-- match pwa.color -->
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js'));
  }
</script>
```

**`public/sw.js`** — service worker source. The `self.__WB_MANIFEST` placeholder is replaced by `scripts/generate-sw.js` at build time with the precache manifest. In dev builds it is undefined and precaching is a no-op. Add any custom fetch logic (e.g. CORS proxy) here — it survives the workbox injection:
```js
// Replaced by workbox-build injectManifest with [{url, revision}, ...] entries.
// undefined in dev builds — precaching is a no-op.
const PRECACHE = self.__WB_MANIFEST;
const CACHE_NAME = 'm-<name>-precache-v1';

self.addEventListener('install', (event) => {
  if (PRECACHE?.length) {
    event.waitUntil(
      caches.open(CACHE_NAME).then((cache) =>
        Promise.allSettled(PRECACHE.map((entry) =>
          cache.add(new Request(entry.url, { cache: 'reload' }))
        ))
      )
    );
  }
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  const cleanup = PRECACHE?.length
    ? caches.keys()
        .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
        .then(() => self.clients.claim())
    : self.clients.claim();
  event.waitUntil(cleanup);
});

self.addEventListener('fetch', (event) => {
  // Serve from precache for same-origin requests
  if (PRECACHE?.length && event.request.url.startsWith(self.location.origin)) {
    event.respondWith(
      caches.match(event.request).then((cached) => cached || fetch(event.request))
    );
  }
});
```

**`workbox-config.cjs`** — uses `injectManifest` mode so custom SW logic in `public/sw.js` is preserved. `generateSW` would overwrite the file entirely:
```js
module.exports = {
  swSrc: 'apps/m-<name>/public/sw.js',
  swDest: 'dist/apps/m-<name>-wc/pwa/sw.js',
  globDirectory: 'dist/apps/m-<name>-wc/pwa/',
  globPatterns: ['**/*.{js,css,html,svg,ico,woff,woff2,png,jpg,webp}'],
  globIgnores: ['sw.js', 'sw.js.map'],
};
```

**`project.json`** — add `pwa` build configuration under `build.configurations`:
```json
"pwa": {
  "outputPath": "dist/apps/m-<name>-wc/pwa",
  "baseHref": "/store/v1/wc/<slug>/pwa/",
  "outputHashing": "all",
  "fileReplacements": [
    {
      "replace": "apps/m-<name>/src/environments/environment.ts",
      "with": "apps/m-<name>/src/environments/environment.dev.ts"
    }
  ],
  "assets": [
    { "glob": "**/*", "input": "apps/m-<name>/public" },
    { "glob": "**/*", "input": "apps/m-<name>/public/assets", "output": "assets" },
    { "glob": "**/*", "input": "libs/one/assets", "output": "assets/one" },
    { "glob": "manifest.json", "input": "apps/m-<name>/public/assets", "output": "." },
    { "glob": "icons/**/*", "input": "apps/m-<name>/public/assets", "output": "." }
  ]
}
```

`<slug>` = the `app:` field value from the remote YAML — short name WITHOUT `m-` prefix (e.g. `radio`, `comics`, `finance`, `wallet`).

### How it builds

The CLI's `assets-wc` command only copies YAML assets — it does NOT run the Angular build or Workbox. The full PWA pipeline runs via the per-app npm script in `package.json`:

```json
"assets:<name>": "nx run-many -t build -p cli,sass,one && node dist/libs/cli/bin/cli.js assets-wc --config ./mag-cli.config.js --app m-<name> && nx build m-<name> --configuration=pwa && node scripts/generate-sw.js && node scripts/patch-wc-env.js --app m-<name>"
```

Steps in order:
1. `nx run-many -t build -p cli,sass,one` — builds libs (sass + one needed for Angular build)
2. `assets-wc --app m-<name>` — generates `manifest.json`, icons → `public/assets/`; copies all YAML assets → `dist/apps/m-<name>-wc/`
3. `nx build m-<name> --configuration=pwa` → Angular app → `dist/apps/m-<name>-wc/pwa/`
4. `node scripts/generate-sw.js` — runs `workbox-build injectManifest` using `workbox-config.cjs` → writes `dist/apps/m-<name>-wc/pwa/sw.js` with precache manifest injected
5. `node scripts/patch-wc-env.js --app m-<name>` — patches env-specific fields in `app-wc.json`

**`scripts/generate-sw.js`** — shared script (already exists in repo root):
```js
#!/usr/bin/env node
'use strict';
const { injectManifest } = require('workbox-build');
const config = require('../workbox-config.cjs');
injectManifest(config)
  .then(({ count, size }) => console.log(`SW generated: ${count} precache entries (${size} bytes)`))
  .catch((err) => { console.error('SW generation failed:', err.message); process.exit(1); });
```

`workbox-build` is already a devDependency — no extra install needed.

### Deployed path

`dist/apps/m-<name>-wc/pwa/` uploads alongside `remote/` to:
```
api-dev.magmonium.com/store/v1/wc/<appId>/pwa/
```

### m-ui footer install button

When active WC app's `app-wc.json` has a `pwa` field, the footer in m-ui shows an install icon. Clicking opens the PWA URL in a new tab where the browser shows the install prompt.

### Local testing

1. Run `npm run assets:<name>` to build everything into `dist/apps/m-<name>-wc/pwa/`
2. Start m-ui dev server (`npm start`)
3. Navigate to the app section in m-ui
4. Install button appears — clicking opens:
   - `http://localhost:4200/local-dist/m-<name>-wc/pwa/` (served by proxy → `dist/apps/m-<name>-wc/pwa/index.html`)
   - JS/CSS assets load via `/store/v1/wc/<appId>/pwa/` (proxy maps `appId` → `dist/apps/m-<appId>-wc/pwa/`)

The `apps/m-ui/proxy.conf.js` handles both paths. No extra config needed.

> **`<appId>` proxy mapping:** The proxy strips `m-` prefix from `/store/v1/wc/<appId>/pwa/` and appends `-wc` to get the dist dir. So `baseHref: "/store/v1/wc/m-comics/pwa/"` maps to `dist/apps/m-comics-wc/pwa/` — correct. If `baseHref` used `comics` (no `m-` prefix), it would map to `dist/apps/comics-wc/` — wrong. Always match `baseHref` `appId` segment to the full app name including `m-`.

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
| Nav | `FrameComponent` renders `<m-nav />` | Host `App` renders `<m-nav [isHost]="true">` |
| Settings path | Fetches from app's `/assets/navs/` | Fetches from host's `/assets/navs/` |
| `APP_BASE_HREF` | `/` | `/app/m-<name>` |
| `assetStore.appId` | `undefined` | `m-<name>` |

Nav is always provided by the frame/host — never by `wc.ts`.

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
          registry-url: https://npm.pkg.github.com/
          scope: '@magmonium'
        env:
          NODE_AUTH_TOKEN: ${{secrets.MAGMONIUM_SEC}}

      - name: Cache node_modules
        uses: actions/cache@v4
        id: node-modules-cache
        with:
          path: '**/node_modules'
          key: ${{ runner.os }}-modules-${{ hashFiles('**/yarn.lock') }}
          restore-keys: |
            ${{ runner.os }}-modules-

      - name: Cache Nx
        uses: actions/cache@v4
        with:
          path: |
            .nx/cache
            .nx/workspace-data
          key: ${{ runner.os }}-nx-wc-${{ hashFiles('**/yarn.lock') }}-${{ hashFiles('libs/cli/**', 'nx.json') }}
          restore-keys: |
            ${{ runner.os }}-nx-wc-${{ hashFiles('**/yarn.lock') }}-
            ${{ runner.os }}-nx-wc-

      - name: Install dependencies
        if: steps.node-modules-cache.outputs.cache-hit != 'true'
        run: yarn install --frozen-lockfile --network-timeout 300000
        env:
          NODE_OPTIONS: --dns-result-order=ipv4first

      # Without PWA (no pwa: in remote YAML):
      - name: Build assets and web component
        run: |
          npx nx build cli
          node dist/libs/cli/bin/cli.js assets-wc --config ./mag-cli.config.js --app m-<name>
          node scripts/patch-wc-env.js --app m-<name>
        env:
          BUILD_CONFIG: dev

      # With PWA (pwa: present in remote YAML) — replace the step above:
      # - name: Build libs, assets, PWA and web component
      #   run: |
      #     npx nx run-many -t build -p cli,sass,one
      #     node dist/libs/cli/bin/cli.js assets-wc --config ./mag-cli.config.js --app m-<name>
      #     npx nx build m-<name> --configuration=pwa
      #     node scripts/generate-sw.js
      #     node scripts/patch-wc-env.js --app m-<name>
      #   env:
      #     BUILD_CONFIG: dev
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
| `<m-nav />` in `wc.ts` | Duplicates nav in both standalone AND embedded — `FrameComponent`/host already renders it |
| Missing `settings.yml` with `navs` | Settings sub-items don't appear in nav panel |
| Widget child segment ≠ YAML nav child name | Nav shows wrong items or empty |
| `title` in nav YAML is raw text, not i18n key | Untranslated label shown |
| Editing compiled JSON directly | Overwritten by `assets:compile` — edit YAML only |
| Running `assets:wc` without `--app` for a single app | Compiles ALL 6 app asset paths — use `assets:<appname>` scripts instead; `assets-wc --app <name>` filters to libs/one + target only |
| Copying m-ui `project.json` executor for new WC app | m-ui uses esbuild (`@nx/angular:application`); WC apps need `@nx/angular:webpack-browser` + `customWebpackConfig` |
| Adding `.gitignore` to `public/assets/` | Root `.gitignore` already ignores `apps/m-<name>/public/assets/` — no per-app gitignore needed |
| Missing `NAV_WC_COMPONENTS` provider | Widget fails to render cross-bundle — CE never registered |
| Missing `selector` in `NavWidgetConfig` | Falls back to `reflectComponentType` which may not match registered CE tag — widget renders blank |
| `ASSET_BASE_URL` / `ONE_ASSET_BASE_URL` in providers | WC wrapper overrides at runtime anyway; static value causes wrong asset URLs in remote mode — remove from providers |
| No `dependsOn` in project.json serve | Build fails — sass/one not ready |
| Wrong selector in remote yml | WC doesn't mount in m-ui |
| LAN IP in `environment.ts` | Local serve hits `192.168.x.x:8000` not `localhost` — use `http://localhost:8000` |
| `environment.dev.ts` pointing to LAN IP | CI/remote dev build hits wrong backend — should be `https://api-dev.magmonium.com` |
| Missing `workbox-config.cjs` with `pwa:` set | SW never generated — app installs but loads uncached on every visit |
| Using `generateSW` mode in `workbox-config.cjs` | Overwrites `public/sw.js` entirely — any custom fetch logic (CORS proxy etc.) is lost. Use `injectManifest` with `swSrc` |
| `self.__WB_MANIFEST` appears more than once in `public/sw.js` | `workbox-build injectManifest` requires exactly one occurrence — check comments too |
| Wrong `baseHref` in pwa build config | JS/CSS 404 after install — proxy maps `appId` segment directly to `dist/apps/<appId>-wc/`; use full name e.g. `/store/v1/wc/m-comics/pwa/` |
| Missing `fileReplacements` in `pwa` build config | PWA bundles with `environment.ts` (localhost) → API calls hit `192.168.x.x:8000` in production — always add `fileReplacements` pointing to `environment.dev.ts` |
| CI build step missing lib builds for PWA | Angular build needs `sass` + `one` compiled first — add `npx nx run-many -t build -p cli,sass,one` before `nx build m-<name> --configuration=pwa` |
| Missing `node scripts/generate-sw.js` in CI | Angular pwa build produces no `sw.js` precache — workbox step must run after `nx build` |
| Missing manifest link in `index.html` | Browser never sees manifest — install prompt never fires |
| Missing `mag_assets/pwa/icon.svg` | `assets-wc` skips icon generation — PWA installs without icon |
| `pwa:` as boolean (`pwa: true`) | Must be an object with `desc`/`color`/`bgcolor` — boolean breaks manifest generation |
| Editing `public/assets/manifest.json` directly | Overwritten by `assets:<name>` on every build — set colors in remote YAML `pwa:` block |
| Testing PWA without running `assets:<name>` first | `/local-dist/m-<name>-wc/pwa/` doesn't exist — proxy returns 404 |
