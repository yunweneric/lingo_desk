#!/bin/bash
#
# Run the CI jobs locally, using the same commands the workflows use.
#
#   ./scripts/ci_local.sh              verify + every job this machine can build
#   ./scripts/ci_local.sh verify       format, analyze, test  (the shared gate)
#   ./scripts/ci_local.sh android      verify + APK/AAB       (build_apk.yml)
#   ./scripts/ci_local.sh macos        verify + DMG           (release.yml)
#   ./scripts/ci_local.sh --skip-verify android
#
# The point is to fail here rather than on a runner, so the commands are
# copied from the workflows rather than improved on. Two deliberate
# differences:
#
#   * Plain `flutter`, not `fvm flutter`. CI installs FVM to pin the SDK;
#     locally your PATH Flutter is the one you develop with, and running
#     it through FVM here has hung on macOS. The SDK check below covers
#     what the pin was protecting against.
#   * Windows is not attempted. `build-windows` needs a Windows runner and
#     there is no way around that from a Mac.
#
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; DIM='\033[2m'; NC='\033[0m'

PASSED=0; FAILED=0; SKIPPED=0
FAILED_STEPS=()

step() {
  local name="$1"; shift
  echo -e "${YELLOW}▶ ${name}${NC}"
  echo -e "${DIM}  \$ $*${NC}"
  if "$@"; then
    echo -e "${GREEN}✓ ${name}${NC}\n"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}✗ ${name}${NC}\n"
    ((FAILED++))
    FAILED_STEPS+=("$name")
    return 1
  fi
}

# For steps CI marks `continue-on-error` — a failure is reported but does
# not sink the run, exactly as on the runner.
soft_step() {
  local name="$1"; shift
  echo -e "${YELLOW}▶ ${name}${DIM} (continue-on-error)${NC}"
  echo -e "${DIM}  \$ $*${NC}"
  if "$@"; then
    echo -e "${GREEN}✓ ${name}${NC}\n"
    ((PASSED++))
  else
    echo -e "${YELLOW}⚠ ${name} failed — CI tolerates this${NC}\n"
    ((SKIPPED++))
  fi
  return 0
}

# ---------------------------------------------------------------- SDK check

# The workflows resolve the SDK from .fvmrc and install exactly that.
# Locally we use whatever `flutter` is on PATH, so the one thing worth
# checking is that the two agree — a mismatch here is what broke the
# 2026-08-18 run, where CI resolved 3.29.3 against a pubspec needing
# Dart ^3.10.0 and died at `pub get` before any artifact was built.
check_sdk() {
  local pinned local_version
  pinned=$(grep -o '"flutter"[[:space:]]*:[[:space:]]*"[^"]*"' .fvmrc 2>/dev/null | cut -d'"' -f4)
  local_version=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')

  if [ -z "$pinned" ]; then
    echo -e "${YELLOW}⚠ No .fvmrc — CI will fall back to its hardcoded version${NC}\n"
    return
  fi

  if [ "$pinned" = "$local_version" ]; then
    echo -e "${GREEN}✓ Flutter ${local_version} matches .fvmrc${NC}\n"
  else
    echo -e "${RED}✗ SDK mismatch: .fvmrc pins ${pinned}, local flutter is ${local_version}${NC}"
    echo -e "${DIM}  CI builds with ${pinned}. A pass here does not predict a pass there.${NC}\n"
    ((FAILED++))
    FAILED_STEPS+=("SDK version matches .fvmrc")
  fi
}

# ------------------------------------------------------------------- jobs

# The `verify` job of release.yml, which is also the head of build_apk.yml.
# Every artifact job depends on this, so a failure here means no DMG, no
# APK, no release.
job_verify() {
  echo -e "\n${YELLOW}══ verify ══${NC}\n"
  step "Get dependencies" flutter pub get || return 1
  step "Verify formatting" dart format --set-exit-if-changed . || true
  step "Analyze code" flutter analyze || true
  step "Run tests" flutter test || true
}

# build_apk.yml. The AAB is continue-on-error upstream because it needs
# signing config; without android/key.properties it falls back to debug
# signing, which is fine for a local check but not for Play.
job_android() {
  echo -e "\n${YELLOW}══ android (build_apk.yml) ══${NC}\n"
  step "Build APK (debug)" flutter build apk --debug || true
  step "Build APK (release)" flutter build apk --release || true
  soft_step "Build App Bundle (release)" flutter build appbundle --release

  if [ ! -f android/key.properties ]; then
    echo -e "${DIM}  Note: no android/key.properties — release artifacts are debug-signed.${NC}\n"
  fi

  echo -e "${DIM}Artifacts:${NC}"
  ls -lh build/app/outputs/flutter-apk/app-debug.apk \
        build/app/outputs/flutter-apk/app-release.apk \
        build/app/outputs/bundle/release/app-release.aab 2>/dev/null \
    | awk '{print "  " $5 "\t" $9}'
  echo ""
}

# The build-macos job of release.yml, through to the .dmg.
job_macos() {
  echo -e "\n${YELLOW}══ macos (release.yml) ══${NC}\n"

  if [ "$(uname)" != "Darwin" ]; then
    echo -e "${YELLOW}⚠ Not macOS — skipping${NC}\n"
    ((SKIPPED++)); return 0
  fi

  # release.yml builds with the numeric part of the version: the tag for a
  # release, else the pubspec version plus a short sha.
  local pubspec_version version numeric
  pubspec_version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
  version="${pubspec_version}-$(git rev-parse --short HEAD 2>/dev/null || echo local)"
  numeric="${version%%-*}"

  step "Build macOS app (release)" \
    flutter build macos --release --build-name="${numeric}" || return 1

  local app_name app_path dmg_path stage
  app_name=$(grep "PRODUCT_NAME" macos/Runner/Configs/AppInfo.xcconfig | cut -d'=' -f2 | xargs)
  app_path="build/macos/Build/Products/Release/${app_name}.app"
  dmg_path="build/dist/${app_name}-${version}-macos.dmg"

  echo -e "${YELLOW}▶ Create DMG${NC}"
  mkdir -p build/dist
  stage=$(mktemp -d)
  if cp -R "${app_path}" "${stage}/" \
     && ln -s /Applications "${stage}/Applications" \
     && hdiutil create -volname "${app_name}" -srcfolder "${stage}" \
          -ov -format UDZO "${dmg_path}" >/dev/null; then
    rm -rf "${stage}"
    echo -e "${GREEN}✓ Create DMG${NC}"
    ls -lh "${dmg_path}" | awk '{print "  " $5 "\t" $9}'
    echo -e "${DIM}  Unsigned: Gatekeeper will need System Settings → Privacy & Security → Open Anyway.${NC}\n"
    ((PASSED++))
  else
    rm -rf "${stage}"
    echo -e "${RED}✗ Create DMG${NC}\n"
    ((FAILED++)); FAILED_STEPS+=("Create DMG")
  fi
}

# ------------------------------------------------------------------- main

RUN_VERIFY=true
TARGET="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-verify) RUN_VERIFY=false ;;
    verify|android|macos|all) TARGET="$1" ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

cd "$(dirname "$0")/.." || exit 1

echo "🔁 Local CI — mirroring .github/workflows/"
echo "=========================================="
echo ""
check_sdk

if [ "$RUN_VERIFY" = true ]; then
  if ! job_verify; then
    echo -e "${RED}Dependencies failed to resolve; every artifact job depends on this.${NC}"
    exit 1
  fi
fi

case "$TARGET" in
  android) job_android ;;
  macos)   job_macos ;;
  all)     job_android; job_macos ;;
esac

echo "=========================================="
echo -e "${GREEN}Passed: ${PASSED}${NC}"
[ "$SKIPPED" -gt 0 ] && echo -e "${YELLOW}Tolerated: ${SKIPPED}${NC}"
if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}Failed: ${FAILED}${NC}"
  for s in "${FAILED_STEPS[@]}"; do echo -e "${RED}  · ${s}${NC}"; done
  echo ""
  echo -e "${DIM}Windows (build-windows) cannot run here; it needs a Windows runner.${NC}"
  exit 1
fi
echo ""
echo -e "${DIM}Not covered: build-windows — needs a Windows runner.${NC}"
exit 0
