# LingoDesk — Implementation & UX Specification

LingoDesk is a **local-first localization manager**. It replaces the manual work of keeping `en.json`, `fr.json`, `es.json`, … in sync by giving developers one workspace where every translation key is a row, every language is a column, and progress is always visible. No backend: everything is stored on-device (SharedPreferences) and files move in and out as plain JSON.

**Core loop:** create an App → upload existing JSON files → fill the gaps in the editor → export production-ready nested JSON back into the codebase.

---

## Application Flow

```
Onboarding (first launch only)
        │
        ▼
┌─ 1. Dashboard ─────────────────────────────┐
│  overview + app list (CRUD entry point)    │
│    ├── "New app" ──► create modal ──►(optional) 3. File Upload ──► 4. Editor
│    ├── row tap ────► 4. Translation Editor │
│    └── row menu ───► Settings / Upload / Editor / Delete (confirm)
└────────────────────────────────────────────┘
```

Navigation uses **go_router** (`lib/core/router/app_router.dart`) — every transition is a **fade** (240ms, ease-out-cubic, the design system's motion tokens):

| Route | Screen |
|---|---|
| `/onboarding` | Onboarding (redirect-enforced until completed) |
| `/` | Dashboard |
| `/apps/:id/settings` | App Settings (edit — needs the `App` as `extra`; bare links fall back to `/`) |
| `/apps/:id/upload` | File Upload (`App` as `extra`; `?pop=1` pops back to the editor on import) |
| `/apps/:id/editor` | Translation Editor |

The dashboard subscribes to a `RouteObserver` and reloads its stats whenever a page above it pops, so numbers are never stale.

---

## Screens

### 0. Onboarding

- 3-step intro (workspace → project setup → export) with visual pane on wide layouts.
- Actions: **Next / Back**, **Skip**, last step shows **Start setup**.
- Shown **only on first launch** — completion is persisted; afterwards the app boots straight to the dashboard.

### 1. App Management Dashboard (entry point)

Purpose: bird's-eye view of every localization project + CRUD.

Layout (top → bottom):
- **Header**: breadcrumb (`Workspace / Dashboard`), live **search field** (filters the app table by name, with clear button), theme switcher (System/Light/Dark), UI-language switcher, **New app** button. Below it a hero card with totals: apps, keys, locales, and a "N missing strings" badge.
- **Metric cards** (responsive 1/2/4 columns): Apps, Total keys, Coverage %, Missing.
- **Coverage by app**: bar chart, one bar per app (app-name initials as labels), derived from real progress. Placeholder text when no apps.
- **Language health**: per-target-locale progress bars aggregated across apps, weakest locale first; "Next review: <app>" hint.
- **New app** opens a **modal dialog** (name, source language, target chips, inline validation); on success a follow-up prompt offers "Upload files" or "Later".
- **Sidebar actions**: Dashboard scrolls to top; Apps / Languages smooth-scroll to the apps table / language health card; Imports & Editor open the target for the single app directly, show an app chooser when several exist, or open the create modal when there are none; Tools → Settings opens the workspace Settings page.
- **Workspace Settings page** (`/settings`): tabbed — **Profile** (name/email, sidebar avatar), **Appearance** (System/Light/Dark), **Languages** (interface language + default target locales for new apps). Language options everywhere show the country's **flag emoji** next to the name (chips, dropdowns, upload pills, export rows, progress tiles, language health).
- **Apps table**: one row per app — name + `en.json - N keys`, target-language badges, progress bar + %, status badge (**New** = no keys yet / **Missing** = has gaps / **Complete**), relative "Updated" time, and a **⋯ menu** (Open editor / Settings / Upload files / Delete app).
- **Sidebar** (only ≥1024 px): brand, nav items, "Local workspace" footer.

UI states:
- **Loading**: centered spinner (list kept on screen during silent refreshes).
- **Empty**: "Create your first app" card with CTA.
- **Error**: message + Retry.
- **Search with no matches**: inline "No apps match your search."

Guards: **Delete app** always confirms via dialog ("permanently removes the app and all of its translations").

### 2. App Settings

Purpose: configure a project. **Create** happens in a modal dialog on the dashboard; **edit** (row menu → Settings) uses the full page at `/apps/:id/settings`. Both share the same form fields and BLoC.

- Form: **App name** text field, **Source language** dropdown, **Target languages** as toggleable filter chips (20 supported locales). The source language chip is disabled as a target; changing source removes it from targets automatically.
- Validation (inline error row): name required, ≥1 target language, source ∉ targets.
- Actions: Cancel / **Create app** (modal) or **Save changes** (page) with in-button progress spinner while saving.
- After **create**: prompt offers **"Upload files"** (→ File Upload) or **"Later"**. After **edit**: snackbar + pop.

### 3. File Upload (file initialization)

Purpose: import existing JSON files into an app's workspace. Context-aware for the selected app.

- **Required languages** card: one pill per language (source marked, e.g. `EN - source (English)`); pills flip to green check marks as valid files for them are staged.
- **Browse card**: icon + "Add your translation files" + **Browse files** button (native multi-select picker, `.json` only).
- **Staged files list**: each row shows file name (mono), key count, language badge, remove button. Validation per file:
  - language inferred from file name (`fr.json → fr`); rejected if not in the app's language set,
  - invalid JSON / non-object / empty files rejected with the reason inline,
  - re-picking a language replaces the previously staged file.
- Actions: **Skip to editor** and **Import & open editor** (enabled only with ≥1 valid file; spinner while importing).
- Import semantics: merge — union of keys, uploaded values overwrite existing ones.

### 4. Translation Editor (the workspace)

Purpose: the core grid where translation happens.

- **Header**: back, app name, `Translation editor - N keys - M missing`.
- **Progress tiles**: one per target language — code, %, progress bar, "N missing" / "Complete" (updates live as you type).
- **Toolbar**: search (matches keys *and* values), **Missing only** filter chip (shows match count when active), **Add key**, **Upload**, **Export JSON**.
- **Grid**: one row per key (sorted alphabetically), horizontal scroll when columns exceed the viewport.
  - Column 1: dot-notation key (mono) — column header marks the source column (`EN - source`).
  - One editable cell per language. **Empty target cells are highlighted** (warm "Missing" tint + hint text). Edits are debounced (~400 ms) then persisted; focus ring on the active cell.
  - Row delete (trash icon) behind a **confirmation dialog** — removes the key from *all* languages.
- **Add key dialog**: key field (validated: dot notation, letters/digits/`_`/`-`, must be unique) + optional source value.
- **Export dialog**: checkbox per language (`fr.json — French`), then one native save dialog per file. Output is **re-nested** JSON (dot keys expanded back to objects), pretty-printed, stable key order.
- Empty states: "No keys yet. Upload JSON files or add your first key." / "No keys match the current filters."
- Feedback: snackbars for add/delete/export results and errors (red for errors).

---

## Cross-cutting UX

- **Theming**: full light + dark themes (`LingoDeskTheme`), user-selectable System/Light/Dark from the dashboard header, persisted across launches. All screens resolve colors through shared tokens (`LingoDeskTokens`): background, card, border, foreground, muted, active.
- **Persistence**: apps *and* translation content are stored locally, so the dashboard's stats survive restarts. Theme, UI language, and onboarding completion are also persisted. Deleting an app deletes its translations.
- **Responsiveness**: laid out against Material 3 window size classes (`lib/core/responsive/breakpoints.dart`) — compact <600, medium 600, expanded 840, large 1200, extra-large 1600. Navigation is a bottom bar on compact, a 72px icon rail through expanded, and the full 284px sidebar from large up. Page headers stack below expanded. The metric grid runs 1/2/4 columns. Tables never scroll horizontally: on a wide pane they reflow and fold surplus columns into an expandable section per row, and on compact each row becomes a stacked card.
- **Confirmation guards**: destructive actions (delete app, delete key) always require dialog confirmation.
- **Relative timestamps**: "Just now", "2 min ago", "Yesterday", "3 days ago".

## Data Model (for reference)

| Entity | Fields | Notes |
|---|---|---|
| `App` | id, name, sourceLanguage, targetLanguages[], createdAt, updatedAt | one localization project |
| `AppOverview` | app + keyCount, missingCount, missingByLanguage, lastActivity | derived stats driving the dashboard |
| `TranslationEntry` | key, values{lang → string} | one grid row; empty value = missing |

Flattening: nested JSON ⇄ dot notation (`{"nav":{"home":"Home"}}` ⇄ `"nav.home": "Home"`); lists are indexed (`items.0`).

## State Management Map (which UI states exist)

| Screen | BLoC | Key states the UI renders |
|---|---|---|
| Dashboard | `AppManagementBloc` | Initial / Loading / **Loaded** (overviews + search query) / Error |
| App Settings | `AppSettingsBloc` | **Ready** (form fields, isSaving, inline error) / SaveSuccess (create vs edit) |
| File Upload | `FileUploadBloc` | **Ready** (staged files, per-file errors, isImporting) / ImportSuccess |
| Editor | `TranslationEditorBloc` | Loading / **Loaded** (entries, filters, per-language %, transient notice) / Error |

Every list/detail screen has an explicit **loading**, **empty**, and **error** treatment — design all three.

## Design System Snapshot (teal rebrand, Aug 2026)

Source of truth: the **LingoDesk Design System** project on claude.ai/design (`LingoDesk macOS.dc.html` + `_ds/lingodesk-design-system-*/tokens/`).

- **Brand**: one teal `#0F766E` for every primary action, progress fill, and active accent — never as a background wash. `#E7F3F0` (border `#CFE6E0`) is the only tinted surface. Status colors are literal: complete `#15803D`, warning `#B45309`, error `#DC2626`, missing cell tint `#FEF3C7`.
- **Surfaces**: warm stone — `#FAFAF9` page / white cards / `#E7E5E4` borders / ink `#1C1917` / slate `#78716C` muted / `#F0EFEC` active fill. The design is light-first; the app's dark mode maps to the system's deep teal-ink stage palette (`#0E1B18` bg, `#16241F` cards, `#0C1714` sidebar, white-12 borders, white-70 muted).
- **Type**: Space Grotesk (UI, 400/500/600/700) + Space Mono (machine strings, 700) — bundled in `assets/fonts/`. `letter-spacing: 0` on every style. Ramp: 40/30/28/22/17/16/14/12/11, mono 13.
- **Shape**: 12px radius for essentially everything (cards, buttons, inputs, chips, sidebar rows), 8px nested, 16px dialogs, 999 pills/progress. Cards are flat: white, 1px border, elevation 0 — no shadows, no gradients, no blur.
- **Brand mark**: teal rounded square with two overlapping locale tiles + two dots, drawn natively by `LingoDeskMark` (reference SVGs in `assets/brand/`); the wordmark is set live in Space Grotesk 700, never as an image.
- **Voice**: sentence case everywhere, verb-first 1–2 word buttons, numbers lead status copy ("12 missing"), no emoji/exclamation marks in product UI.

## Where Things Live

```
lib/core/            theme, tokens, shared widgets (WorkspaceScaffold), utils, DI, storage keys
lib/features/
  app_management/    dashboard (domain + data + bloc + UI)
  app_settings/      create/edit form (reuses app_management domain)
  file_upload/       picker, validation, staging, import
  translation_editor/ grid, key CRUD, progress, JSON export
```

Each feature follows Clean Architecture (domain / data / presentation) with BLoC state management and `export.dart` barrels — see [feature.md](feature.md) for the pattern.
