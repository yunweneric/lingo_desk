# LingoDesk: Localization Management Tool

LingoDesk is a lightweight, project-based translation manager designed to eliminate the manual overhead of syncing multiple JSON localization files. It provides a centralized UI to manage keys and translations across various languages with real-time progress tracking.

## 🚀 The Problem

Developers often spend excessive time manually opening, editing, and syncing key-value pairs across `en.json`, `es.json`, `uk.json`, etc. This process is:

- **Error-prone**: Easy to miss keys or make typos
- **Time-consuming**: Requires opening multiple files and manually syncing
- **Inefficient**: Breaks the development flow and reduces productivity

## ✨ The Solution

LingoDesk offers a browser-based workflow to:

- **Organize translations by "App" (Project)**: Group related translations together
- **Flatten complex nested JSON**: Convert nested structures into a manageable table format
- **Track translation completion**: Real-time progress percentages for each language
- **Export clean, nested JSON**: Generate production-ready files with proper structure

## 🛠 Project Architecture

LingoDesk follows a 4-screen flow designed for an intuitive translation management experience.

### 1. App Management Dashboard

The entry point of the application.

- **CRUD for Apps**: Create, view, update, or delete localization projects
- **Persistence**: Project metadata is saved to `localStorage` so your project list persists across sessions
- **Overview**: See high-level completion status for each app

### 2. App Settings

Configure the specific requirements for an App.

- **Source Language**: Set the base language (e.g., `en`)
- **Target Languages**: Define languages to translate into (e.g., `uk`, `es`, `ru`)
- **Project Configuration**: Update project naming and language scope

### 3. File Initialization (Upload)

A dedicated stage to sync your local code with the editor.

- **Context-Aware**: Displays the specific languages required for the selected App
- **Validation**: Ensures files match the expected language codes before proceeding
- **File Upload**: Import existing JSON files to populate the editor

### 4. Translation Editor (The Workspace)

The core engine of LingoDesk.

- **Flattened Grid**: A unified table where each row is a translation key
- **Progress Widget**: Real-time completion bars for every target language
- **"Show Missing Only"**: A filter to instantly isolate untranslated strings
- **CRUD on Keys**: Add new keys or delete obsolete ones across all languages simultaneously
- **JSON Export**: Re-constructs the nested JSON structure and triggers browser downloads

## ⚙️ Technical Specifications

### Data Transformation

**Flattening**: Converts nested JSON into dot-notation format
```json
// Input
{
  "nav": {
    "home": "Home"
  }
}

// Output
{
  "nav.home": "Home"
}
```

**Un-flattening**: Reverses dot-notation back into deep objects upon export

**In-Memory State**: Translation content is handled in-session for maximum speed and privacy

### Core Features

- **Missing Indicator**: Automatic UI highlighting for empty fields
- **Confirmation Guards**: Destructive actions (deleting keys or apps) are protected by warning modals
- **Frontend-Only**: No backend required. Your data stays in your browser

## 🚦 Getting Started

1. **Define an App**: Create your first project and set your target languages
2. **Upload Files**: Drop your existing `.json` files into the uploader
3. **Translate**: Use the "Show Missing" filter to fill in the gaps
4. **Export**: Download the updated files and drop them back into your codebase

---

*LingoDesk was prototyped and specified using an iterative blueprinting process to ensure a rock-solid development path.*
