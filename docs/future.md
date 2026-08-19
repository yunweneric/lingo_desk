# Roadmap

Where LingoDesk is and where it's going.

This is a direction, not a delivery schedule. Nothing here carries a date, and
anything in [Exploring](#exploring) may never ship — it's listed so the
reasoning is public rather than sitting in someone's head.

- [x] **Shipped** — in `main` and usable today
- [ ] **Planned** — agreed on, not built
- [ ] **Exploring** — an idea we like, not a commitment

---

## Contents

- [Shipped](#shipped)
- [Planned](#planned)
  - [Project sync](#project-sync)
  - [Cloud workspaces](#cloud-workspaces)
  - [Sharing](#sharing)
  - [Packaging](#packaging)
- [Exploring](#exploring)
- [Deliberately not planned](#deliberately-not-planned)
- [Influencing this list](#influencing-this-list)

---

## Shipped

### Projects

- [x] Import a project folder — scan a directory and build the app from the
      locale files actually found in it
- [x] Upload individual JSON files into a new or existing app
- [x] Source and target locales per app, with workspace-wide defaults
- [x] App icons and per-app settings
- [x] Create, update and delete apps

### Editing

- [x] Flattened grid — nested JSON as one row per key, nesting preserved as
      collapsible groups
- [x] Live coverage per target locale, recalculated as you type
- [x] "Missing only" filter
- [x] Full-text search across keys *and* values
- [x] Add and delete keys across every locale at once, behind confirmation
      guards
- [x] Pagination for large key sets

### AI translation

- [x] Anthropic, OpenAI and Gemini providers
- [x] Configurable model per key
- [x] Fill one cell, one locale, or everything missing
- [x] Batch-at-a-time execution that writes each batch to storage as it lands,
      so a cancel or a crash keeps the work already done
- [x] Live per-cell progress and cancellation
- [x] API keys in the system keychain, with a plain warning when a build can't
      reach one

### Export

- [x] Zip bundle to Downloads
- [x] Write back to the imported project folder, following its original layout
- [x] Flat `<locale>.json` per locale into any chosen folder

### The app itself

- [x] Six theme variants, light and dark, following the system by default
- [x] Responsive shell — labelled sidebar, icon rail, or bottom bar by window
      size
- [x] Toast system with success / error / warning / info states
- [x] Local-first storage: no account, no backend, no telemetry
- [x] macOS, Windows, Linux, web and Android from one codebase
- [x] Landing page built from the app's own theme, published on every push to
      `main`
- [x] CI for format, analyze and tests, plus desktop and Android build jobs

---

## Planned

### Project sync

**Today the import is a snapshot.** Point LingoDesk at a folder and it reads
what's there; change `en.json` in your editor afterwards and the app has no
idea. The only way back into step is a re-import, which is a blunt instrument —
it can't tell an intentional edit on disk from a stale value in the app.

The plan is to make the link between an app and its source folder a live one:

- [ ] Detect that files in the linked project folder have changed since the
      last read
- [ ] Show what changed before anything is applied — keys added on disk, keys
      deleted, values edited on either side
- [ ] Pull those changes in, key by key or all at once
- [ ] Flag genuine conflicts — a key edited both in the app and on disk since
      the last sync — and make the user choose, rather than silently picking a
      winner
- [ ] Watch the folder while the app is open, so the prompt arrives on its own
      rather than waiting to be asked

The hard part is not detection, it's the conflict story. A tool that quietly
overwrites a translator's work on disk is worse than one that never syncs, so
the default has to be "show me, then ask."

### Cloud workspaces

Everything is on your machine today, which is the right default and stays the
default. But a locale file is rarely a one-person artifact, and passing zips
around is exactly the loop this app exists to remove.

The plan is an **opt-in** Firebase backend:

- [ ] Accounts, for people who want one
- [ ] Push a local app to a shared workspace, and pull it on another machine
- [ ] Team members with roles — who can edit translations, who can only read,
      who can change locales and settings
- [ ] Live presence and conflict handling for two people in the same grid
- [ ] Per-workspace AI credentials, so a team shares a budget instead of
      everyone pasting their own key

Two constraints on this one, stated up front:

1. **Local-first stays fully functional.** No account, no sign-in wall, no
   feature that only works once you're online. Cloud is a layer on top, never
   a floor underneath.
2. **Nothing leaves the machine unless you push it.** Opting into an account
   does not opt your local apps into sync.

### Sharing

- [ ] Share a read-only view of an app's coverage — the dashboard a PM or a
      client actually wants, without handing over the editor
- [ ] Invite a translator to one locale, scoped to that column and nothing else
- [ ] Share links with an expiry
- [ ] Export a review bundle for someone who won't install anything

### Packaging

- [ ] First tagged release, so the landing page's download button resolves real
      assets instead of falling back to build-from-source
- [ ] Signed macOS and Windows builds — the Gatekeeper and SmartScreen warnings
      in the README are a real install-time cost
- [ ] Homebrew cask, and a Windows package manager entry

---

## Exploring

Ideas with a case behind them, none of them committed.

**Formats beyond JSON**

- [ ] ARB (Flutter's own), `.strings`, `.xliff`, YAML, gettext `.po`
- [ ] CSV / XLSX round-trip, for translators who work in a spreadsheet and
      always will

**Correctness**

- [ ] Placeholder validation — `{count}` present in the source but missing from
      a translation is a crash waiting to happen, and the grid can see it
- [ ] ICU plural and select checking
- [ ] Length warnings where a translation will overflow the UI it's bound to
- [ ] A `lingodesk check` CLI for CI, failing a PR that adds a key to `en.json`
      and nowhere else

**Better AI output**

- [ ] A per-app glossary and tone brief, so "Sign in" doesn't come back three
      different ways across three runs
- [ ] Translation memory — reuse what was approved before instead of paying to
      translate the same string again
- [ ] Review queue for machine output, with an approved / needs-work state per
      cell

**Workflow**

- [ ] Bulk find and replace across locales
- [ ] Undo history for grid edits
- [ ] Command palette and keyboard-first navigation
- [ ] Git-aware view — what this branch changed in the locale files

---

## Deliberately not planned

Saying no in public is cheaper than saying it in twelve issues.

- **A hosted-only product.** The local, backend-free mode is the point of the
  tool, not a trial tier.
- **Telemetry.** Not anonymous, not opt-out, not "just crash reports."
- **A bundled translation API.** LingoDesk talks to the provider *you*
  configured with *your* key. Reselling inference makes us a middleman in your
  data path.
- **Locking files to a proprietary format.** What you import is JSON and what
  you get back is JSON — usable if this project disappears tomorrow.

---

## Influencing this list

It's MIT-licensed and the roadmap isn't sacred.

- **Want something on it?** Open an issue describing the workflow that's
  painful. A concrete "here's what I do today and here's where it breaks" moves
  things further up than a feature name.
- **Want to build something on it?** Say so on the issue first so two people
  don't write the same feature twice, then see
  [Contributing](../README.md#contributing) and the
  [Feature Implementation Guide](feature.md).
- **Planned items are the best place to start** — the shape is agreed, so the
  review is about the code rather than about whether it should exist.
