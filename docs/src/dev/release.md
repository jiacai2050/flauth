# Release

This document describes how to release Flauth to various platforms.

## Prerequisites

- The release commit is tagged (e.g., `v1.1.0`)
- `metadata/en-US/changelogs/<fdroid-versionCode>.txt` is up to date (e.g., `2002.txt` for pubspec `+2`)
- All tests pass: `flutter test`

## Android (F-Droid)

### 1. Tag and push the release

```bash
git tag v<version>
git push origin v<version>
```

### 2. Fork and clone fdroiddata

```bash
git clone git@gitlab.com:<your-username>/fdroiddata.git
cd fdroiddata
```

### 3. Update the app metadata

Edit `metadata/net.liujiacai.flauth.yml`:

- Bump `CurrentVersion` to the new version (e.g., `1.1.0`)
- Bump `CurrentVersionCode` — calculated as `pubspec versionCode + 2000`
  - e.g., `pubspec.yaml` has `version: 1.1.0+2`, so F-Droid versionCode = `2 + 2000 = 2002`
  - This offset is defined by `VercodeOperation: '%c + 2000'` in the F-Droid metadata
- Add a new build entry under `Builds:`:

```yaml
  - versionName: 1.1.0
    versionCode: 2002
    commit: v1.1.0
    output: build/app/outputs/flutter-apk/app-release.apk
    srclibs:
      - flutter@stable
    rm:
      - ios
      - macos
      - windows
      - linux
    build:
      - $$flutter$$/bin/flutter pub get
      - $$flutter$$/bin/flutter build apk --release
```

### 4. Test the build locally (optional)

```bash
fdroid build -v -l net.liujiacai.flauth
```

### 5. Submit a merge request

Push the branch and open an MR against [fdroid/fdroiddata](https://gitlab.com/fdroid/fdroiddata).

Reference MR: <https://gitlab.com/fdroid/fdroiddata/-/merge_requests/38396>

### 6. Wait for review

F-Droid maintainers will review and run the build pipeline. Once merged, the new version appears in the F-Droid repo within the next build cycle (typically 1-3 days).
