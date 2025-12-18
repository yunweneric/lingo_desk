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
- Pushes to `main` branch
- Version tags (e.g., `v1.0.0`)
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

## Extending Workflows

To add more workflows (e.g., for building, deploying), create new `.yml` files in this directory following the same pattern.

