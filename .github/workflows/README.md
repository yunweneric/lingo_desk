# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD.

## Workflows

### test.yml

Runs Flutter tests on pull requests to the main branch.

**Triggers:**
- Pull requests to `main` branch
- Manual workflow dispatch

**What it does:**
1. Checks out the code
2. Sets up Java (required for Android builds)
3. Installs FVM (Flutter Version Management)
4. Sets up Flutter via FVM
5. Gets dependencies
6. Verifies code formatting
7. Analyzes code
8. Runs unit tests
9. Runs widget tests
10. Runs all tests with coverage
11. Uploads coverage as artifact
12. Comments PR with coverage report (optional)

### build_apk.yml

Builds Android APK and App Bundle (AAB) files.

**Triggers:**
- Pushes to `main` branch (when PRs are merged)
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**What it does:**
1. Checks out the code
2. Sets up Java (required for Android builds)
3. Installs FVM (Flutter Version Management)
4. Sets up Flutter via FVM
5. Gets dependencies
6. Verifies code formatting
7. Analyzes code
8. Runs all tests
9. Builds Debug APK
10. Builds Release APK
11. Builds Release App Bundle (AAB)
12. Uploads all build artifacts

**Artifacts:**
- `app-debug-apk` - Debug APK (30 days retention)
- `app-release-apk` - Release APK (30 days retention)
- `app-release-bundle` - Release AAB (30 days retention)

**Note:** The AAB build may fail if signing keys are not configured. This is expected for unsigned builds and the workflow will continue.

### release.yml — Build Desktop Apps

Builds the macOS `.dmg` and the Windows `.exe` installer, and publishes a GitHub Release on tags.

**Triggers:**
- Pushes to `main` branch
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Jobs:**

| Job | Runner | What it does |
| --- | --- | --- |
| `prepare` | ubuntu | Resolves the Flutter SDK version from `.fvmrc` and the artifact version (tag name on tags, `pubspec` version + short SHA otherwise) |
| `verify` | ubuntu | `pub get`, format check, `flutter analyze`, `flutter test` — gates both builds |
| `build-macos` | macos | `flutter build macos --release`, packages the `.app` + `/Applications` symlink into a compressed DMG via `hdiutil` |
| `build-windows` | windows | `flutter build windows --release`, compiles `windows/installer/lingo_desk.iss` with Inno Setup into a setup `.exe`, plus a portable `.zip` |
| `release` | ubuntu | Tags only: downloads both artifacts and creates the GitHub Release |
| `summary` | ubuntu | Writes a build summary to the run page |

**Artifacts** (90 days retention):
- `lingodesk-macos-dmg` — `LingoDesk-<version>-macos.dmg`
- `lingodesk-windows` — `LingoDesk-<version>-windows-setup.exe` and `LingoDesk-<version>-windows-portable.zip`

**Cutting a release:**
```bash
git tag v1.0.0
git push origin v1.0.0
```
The tag name (minus the leading `v`) becomes the version, and the release is published with all three files attached.

**Notes:**
- Builds are **unsigned**. macOS users need right-click → Open on first launch; Windows users get a SmartScreen warning ("More info" → "Run anyway"). Add an Apple Developer ID / Windows code-signing certificate as secrets to remove these.
- The Windows installer definition lives in [`windows/installer/lingo_desk.iss`](../../windows/installer/lingo_desk.iss). Version, source dir and output name are passed in from the workflow via `/D` defines, so it can also be compiled locally with `ISCC`.
- This workflow uses `subosito/flutter-action` with the version pinned in `.fvmrc` instead of installing FVM on the runner.

### Android Signing (Optional)

To build signed APKs and AABs for production, you need to configure signing keys:

1. **Create a keystore file** (locally, never commit it):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Add signing configuration to `android/app/build.gradle.kts`**:
   ```kotlin
   android {
       signingConfigs {
           create("release") {
               storeFile = file(System.getenv("KEYSTORE_FILE") ?: "upload-keystore.jks")
               storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
               keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
               keyPassword = System.getenv("KEY_PASSWORD") ?: ""
           }
       }
       buildTypes {
           getByName("release") {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

3. **Add GitHub Secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `KEYSTORE_FILE` - Base64 encoded keystore file
     - `KEYSTORE_PASSWORD` - Keystore password
     - `KEY_ALIAS` - Key alias
     - `KEY_PASSWORD` - Key password

4. **Update the workflow** to use the secrets:
   ```yaml
   - name: Setup signing keys
     run: |
       echo "${{ secrets.KEYSTORE_FILE }}" | base64 -d > android/app/upload-keystore.jks
   ```

## Configuration

### Flutter Version

The workflow tries to read the Flutter version from `.fvm/fvm_config.json`. If this file is not committed to the repository (it's in `.gitignore` by default), you have two options:

1. **Commit the FVM config file** (recommended):
   ```bash
   # Add fvm_config.json to version control
   git add .fvm/fvm_config.json
   git commit -m "Add FVM config for CI"
   ```

2. **Update the workflow directly**:
   Edit the workflow files (`.github/workflows/*.yml`) and update the `FLUTTER_VERSION` variable in the "Setup Flutter via FVM" step.

### Coverage Reports

Coverage reports are:
- Uploaded as artifacts (available for 7 days)
- Posted as PR comments (if the lcov-reporter-action is working)

## Manual Trigger

You can manually trigger any workflow from the GitHub Actions tab:
1. Go to the "Actions" tab in your repository
2. Select the workflow you want to run (e.g., "Flutter Tests" or "Build Android APK")
3. Click "Run workflow"

## Testing Workflows Locally

### Option 1: `scripts/ci_local.sh` (Recommended)

One script mirrors the workflows, job by job:

```bash
./scripts/ci_local.sh            # verify + every job this machine can build
./scripts/ci_local.sh verify     # format, analyze, test  (release.yml verify)
./scripts/ci_local.sh android    # APK debug/release + AAB (build_apk.yml)
./scripts/ci_local.sh macos      # .dmg                    (release.yml build-macos)

./scripts/ci_local.sh --skip-verify android   # straight to the artifact
```

It runs the same commands the workflows run, produces the real artifacts,
and first checks that your local Flutter matches the version pinned in
`.fvmrc` — a mismatch there is what broke the release run of 2026-08-18,
where CI resolved 3.29.3 against a pubspec needing Dart ^3.10.0 and died at
`pub get` before building anything.

It deliberately uses plain `flutter`, not `fvm flutter`: CI installs FVM to
pin the SDK, while locally your PATH Flutter is the one you develop with,
and the version check covers what the pin was protecting against.

**`build-windows` is not covered** — it needs a Windows runner, and there is
no way around that from macOS or Linux.

### Option 2: Using `act` (GitHub Actions Local Runner)

You can use [`act`](https://github.com/nektos/act) to run GitHub Actions workflows locally:

1. **Install act:**
   ```bash
   # macOS
   brew install act
   
   # Or using the install script
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   ```

2. **Run a workflow:**
   ```bash
   # List available workflows
   act -l
   
   # Run a specific workflow (e.g., test workflow)
   act pull_request
   
   # Run a specific job
   act -j test
   
   # Run with a specific event
   act push -e .github/workflows/test-event.json
   ```

3. **Limitations:**
   - `act` runs workflows in Docker containers, so only the ubuntu `verify` job is reachable; `build-macos` and `build-windows` cannot run under it, as there are no macOS or Windows container images
   - For macOS workflows, use the test scripts instead
   - Some actions may not work perfectly in local Docker environment

### Option 3: Manual Step-by-Step

You can also manually run each step from the workflow:

1. Setup FVM and Flutter (see workflow steps)
2. Run `fvm flutter pub get`
3. Run `fvm dart format --set-exit-if-changed .`
4. Run `fvm flutter analyze`
5. Run `fvm flutter test`
6. Run `flutter build macos --release` (for DMG), `flutter build windows --release` (for EXE) or `flutter build apk --release` (for APK)
7. Create the DMG with `hdiutil create`, or the installer with `ISCC windows\installer\lingo_desk.iss`

## Extending Workflows

To add more workflows (e.g., for building, deploying), create new `.yml` files in this directory following the same pattern.

