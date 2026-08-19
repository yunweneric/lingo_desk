# LingoDesk

**A desktop workspace for JSON localization files.**

### 🌍 [**See LingoDesk &rarr;**](https://yunweneric.github.io/lingo_desk/)

LingoDesk replaces the loop of opening `en.json`, `fr.json`, `es.json` side by
side and hand-syncing keys between them. Point it at a project folder, edit
every locale in one grid, let an AI fill the gaps, and write the files back
where they came from.

Built with **Flutter** — macOS, Windows, Linux, web and mobile from one
codebase. Everything is stored on your machine; there is no backend and no
account.

---

## Contents

- [Why](#why)
- [Features](#features)
- [Getting started](#getting-started)
- [How it works](#how-it-works)
- [Architecture](#architecture)
- [Design system](#design-system)
- [Landing page](#landing-page)
- [Roadmap](#roadmap)
- [Testing](#testing)
- [Building & releases](#building--releases)
- [Contributing](#contributing)
- [License](#license)

---

## Why

Keeping a set of locale files in step is mechanical work that tooling should
have absorbed years ago:

- **Drift is invisible.** A key added to `en.json` is missing from six other
  files and nothing tells you until a user sees a blank string.
- **Nesting hides the gaps.** Deeply nested objects make it hard to see which
  keys exist where, so "is this translated?" means diffing files by eye.
- **Translation is a context switch.** Copying strings into a translator and
  pasting them back breaks flow and loses the surrounding structure.

LingoDesk turns the whole set into one table, shows you exactly what's missing,
and writes valid nested JSON back out.

---

## Features

### Projects

- **Import a project folder** — scan a directory, detect its locale files and
  create the app from what's actually there.
- **Upload files** — or hand it individual JSON files for an existing app.
- **Source and target locales** per app, with workspace-wide defaults applied to
  every new one.
- **App icons** and per-app settings.

### Editing

- **Flattened grid** — nested JSON becomes one row per key, with the original
  nesting preserved as collapsible groups.
- **Live coverage** — completion per target locale, updated as you type.
- **Missing only** filter and full-text search across keys *and* values.
- **Add and delete keys** across every locale at once, behind confirmation
  guards.
- **Pagination** for large key sets.

### AI translation

- **Anthropic, OpenAI and Gemini**, with a configurable model per key.
- **Fill one cell, one locale, or everything missing** — runs a batch at a
  time, writing each batch to storage as it lands, so a cancel or a crash
  keeps the work already done.
- **Live progress** over the grid, with per-cell spinners and a cancel.

### Export

Three destinations, because "export" means different things mid-task:

| Destination | What it does |
| --- | --- |
| **Downloads** | Bundles the selected locales into a zip |
| **Back to project** | Overwrites the files in the folder the app was imported from, following its original layout |
| **Choose a folder** | Writes one flat `<locale>.json` per locale wherever you point it |

### The app itself

- **Six theme variants**, light and dark, following the system by default.
- **Responsive** — the full labelled sidebar on a desktop window, an icon rail
  on a tablet, a bottom bar on a phone.
- **Toasts** for every outcome, with success / error / warning / info states.
- **Local-first**: apps, translations and preferences live in local storage;
  API keys go to the system keychain where one is available.

---

## Getting started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) — the version in
  [`.fvmrc`](.fvmrc) (currently **3.38.10**)
- Platform toolchain for your target (Xcode for macOS/iOS, Visual Studio for
  Windows, Android Studio for Android)

The project pins its Flutter version in `.fvmrc`. [FVM](https://fvm.app/) will
honour it if you use it, but plain `flutter` on a matching version works fine —
every command below is written that way.

### Run it

```bash
git clone https://github.com/your-username/lingo_desk.git
cd lingo_desk
flutter pub get

flutter run -d macos     # or: windows, linux, chrome, <device-id>
```

### First run

1. **Import project** in the sidebar, and pick a folder containing your locale
   files — or **New app** and upload JSON files by hand.
2. Confirm the source locale and pick your targets.
3. Open the app in the editor.
4. Optionally add an API key under **Settings → AI providers** to translate
   missing strings.

---

## How it works

### Flattening

Nested JSON is flattened to dot notation for editing, and un-flattened on the
way out, so the files you commit keep their original shape:

```jsonc
// en.json on disk
{ "nav": { "home": "Home", "about": "About" } }

// in the editor
"nav.home"  → "Home"
"nav.about" → "About"
```

The grid keeps the dots visible and groups rows by prefix, so structure is still
legible when a project has a few thousand keys.

### Storage

| What | Where |
| --- | --- |
| Apps, translations, preferences | Local storage on the device |
| AI API keys | System keychain via `flutter_secure_storage`; the app tells you plainly if a build can't reach one and falls back |
| Your locale files | Only ever read and written where you point the app |

Nothing is uploaded anywhere. The only network calls LingoDesk makes are to the
AI provider you configured, when you ask it to translate.

---

## Architecture

**Clean Architecture** with **BLoC** state management, organised by feature.

```
lib/
├── core/
│   ├── constants/        # Supported languages, storage keys
│   ├── di/               # get_it registrations
│   ├── errors/           # Failures and exceptions
│   ├── preferences/      # Settings + AI credential controllers
│   ├── responsive/       # Window size classes, touch targets
│   ├── router/           # go_router configuration
│   ├── theme/            # Palettes, tokens, motion
│   ├── usecases/
│   ├── utils/
│   └── widgets/          # App shell, design-system widgets, toasts
├── features/
│   ├── ai_translation/   # Providers, keys, batch translation
│   ├── app_management/   # Apps list, dashboard, overviews
│   ├── app_settings/     # Per-app configuration
│   ├── file_upload/      # Project scan + file import
│   ├── onboarding/
│   ├── settings/         # Profile, appearance, languages
│   └── translation_editor/
└── main.dart
```

Each feature follows the same three layers:

```
feature/
├── data/          # Data sources, models, repository implementations
├── domain/        # Entities, repository interfaces, use cases
└── presentation/  # BLoC, pages, widgets
```

- **Domain** knows nothing about Flutter or storage.
- **Data** implements the domain's repository interfaces.
- **Presentation** talks to domain use cases through a BLoC and never touches
  data sources directly.

Failures travel as `Either<Failure, T>` (dartz) rather than exceptions, so every
call site has to decide what a failure looks like on screen.

Each folder carries an `export.dart` barrel — see
[Feature Implementation Guide](docs/feature.md#feature-structure).

---

## Design system

The visual language lives in [`lib/core/theme/`](lib/core/theme/) and is worth
reading before adding UI:

- **`lingo_desk_palette.dart`** — the six theme variants. A variant is a whole
  look, not an accent swap: each carries its own neutrals.
- **`lingo_desk_tokens.dart`** — semantic tokens (`background`, `card`, `border`,
  `foreground`, `muted`, `active`) resolved from the active variant and
  brightness, plus `LingoDeskStatus` for success / error / warning / info.
- **`lingo_desk_motion.dart`** — three durations and one curve family do almost
  all the work. Everything decelerates; nothing accelerates away from the user.
  Reduced-motion is respected throughout.

Reusable widgets are in [`lib/core/widgets/`](lib/core/widgets/) — the app
shell, workspace cards and headers, fields, menus, dropdowns and the toast
system. Prefer extending one of those over styling a Material widget inline.

Further reading: [docs/ui.md](docs/ui.md),
[docs/nomenclature.md](docs/nomenclature.md).

---

## Landing page

The marketing site at **<https://yunweneric.github.io/lingo_desk/>** is a second
Flutter entry point in this repository, not a separate project:

```bash
flutter run -d chrome -t lib/main_landing.dart          # develop
flutter build web --release -t lib/main_landing.dart \
  --base-href /lingo_desk/ --pwa-strategy none          # what CI publishes
```

| Path | What it is |
| --- | --- |
| [`lib/main_landing.dart`](lib/main_landing.dart) | Web entry point — no DI, no router, no storage |
| [`lib/landing/sections/`](lib/landing/sections/) | One file per band of the page |
| [`lib/landing/data/`](lib/landing/data/) | GitHub Releases lookup behind the download button |
| [`web/`](web/) | Shell, social cards, and the HTML curtain shown before Flutter boots |
| [`pages.yml`](.github/workflows/pages.yml) | Builds and publishes to GitHub Pages on push to `main` |

It imports the app's own [`LingoDeskTheme`](lib/core/theme/lingo_desk_theme.dart),
palettes, motion tokens and [`LingoDeskMark`](lib/core/widgets/lingo_desk_mark.dart)
rather than restating them, so the site and the product cannot drift apart — and
the "built with Flutter" section lets a visitor repaint the whole page through
all six palettes to prove it.

The download button resolves the newest **GitHub Release** at runtime and offers
the asset matching the visitor's OS. It has to be a release rather than an
Actions artifact: artifact downloads require an authenticated token, so a public
page cannot fetch them. Until a `v*` tag is pushed, the section falls back to the
build-from-source instructions.

Any section can be linked directly: `#why`, `#features`, `#screens`,
`#how-it-works`, `#flutter`, `#download`.

---

## Testing

```bash
flutter test                          # everything
flutter test test/unit                # unit tests
flutter test test/widget              # widget tests
flutter test integration_test         # integration tests

./scripts/test.sh all                 # or: unit | widget | integration | coverage
./scripts/ci_local.sh verify         # run what CI runs, locally
```

Coverage:

```bash
flutter test --coverage
./scripts/test_coverage.sh            # generates and opens an HTML report
```

See [test/README.md](test/README.md) for the full layout.

---

## Building & releases

### Local

```bash
flutter build macos      # .app
flutter build windows    # .exe + DLLs
flutter build linux
flutter build web
flutter build apk        # or: appbundle
```

### CI

| Workflow | Trigger | Produces |
| --- | --- | --- |
| [`test.yml`](.github/workflows/test.yml) | push / PR | format check, analyze, tests |
| [`release.yml`](.github/workflows/release.yml) | push to `main`, `v*` tags | macOS `.dmg`, Windows installer `.exe` and portable `.zip` |
| [`build_apk.yml`](.github/workflows/build_apk.yml) | push to `main`, `v*` tags | Android APK / AAB |

Desktop artifacts land on every push to `main` (Actions → the run → **Artifacts**,
kept 90 days). Tagging cuts a GitHub Release with everything attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

> Desktop builds are **unsigned**. On macOS the first launch is blocked — open
> **System Settings → Privacy & Security** and choose **Open Anyway**;
> right-click → Open stopped bypassing Gatekeeper in macOS 15. On Windows,
> choose **More info → Run anyway** past SmartScreen. Add signing certificates
> as repository secrets to remove both.

Before pushing, you can run the CI jobs on your own machine:

```bash
./scripts/ci_local.sh            # verify + every job this Mac can build
./scripts/ci_local.sh verify     # format, analyze, test
./scripts/ci_local.sh android    # APK + AAB
./scripts/ci_local.sh macos      # .dmg
```

It uses the same commands as the workflows and checks your local Flutter
against `.fvmrc`, which is the mismatch that has broken CI before. `build-windows`
is the one job it can't cover — that needs a Windows runner.

See [.github/workflows/README.md](.github/workflows/README.md) for details.

---

## Roadmap

Everything in [Features](#features) is shipped and in `main`. The full list —
what's done, what's next, and what has been ruled out — lives in
[docs/future.md](docs/future.md).

The three things being worked towards:

- **Project sync** — the import is a snapshot today. Make the link to the
  source folder live: detect changes on disk, show them before applying, and
  make a conflict a decision rather than a silent overwrite.
- **Cloud workspaces** — an *opt-in* Firebase layer for teams: shared apps,
  roles, live editing. Local-first stays the default and stays fully functional
  offline, and nothing leaves your machine unless you push it.
- **Sharing** — read-only coverage views for a PM or a client, and
  single-locale invites for a translator, without handing over the whole
  editor.

Beyond those: more file formats, placeholder and ICU validation, a CLI check
for CI, glossaries and translation memory for better AI output. See
[Exploring](docs/future.md#exploring).

If something you need isn't there, open an issue describing the workflow that's
painful — that lands better than a feature name.

---

## Contributing

1. Fork and clone, then `flutter pub get`.
2. Branch: `git checkout -b feature/your-feature-name`.
3. Build it, then run the pre-commit checks below.
4. Open a PR with a clear description, and screenshots for any UI change.

### Guidelines

- **Keep the layers separate.** Domain code must not import Flutter or a data
  source.
- **State goes through BLoC** for anything with more than local widget state.
- **Organise by feature, not by file type.**
- **Reach for the design system first** — a new colour or duration should be a
  token, not a literal.
- **Document the why.** Comments should explain decisions, not restate the code.

### Pre-commit

CI fails on unformatted code, so run this before pushing:

```bash
dart format .
dart format --set-exit-if-changed .   # what CI runs
flutter analyze
flutter test
```

### Commits

[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`,
`docs:`, `style:`, `refactor:`, `test:`, `chore:`.

### Reporting issues

Include your platform and OS version, `flutter --version` output, steps to
reproduce, what you expected, what happened, and a screenshot if it's visual.

---

## License

MIT — see [LICENSE](LICENSE).

---

**Made with ❤️ using Flutter**
