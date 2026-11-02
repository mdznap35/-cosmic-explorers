# Android build and delivery

## CI toolchain

- Godot 4.7.2 stable and matching export templates.
- OpenJDK 17.
- Android SDK Platform 35 and Build Tools 35.0.1.
- Android NDK r28b (28.1.13356709).
- CMake 3.10.2.4988404.
- ARM64-v8a debug APK export.

The toolchain versions match the Godot 4.7 Android export documentation. They are installed on GitHub-hosted runners, not on the user's phone.

## Artifact

The workflow emits `CosmicExplorers-Android-debug.apk` as a GitHub Actions artifact. The debug signing key is generated temporarily and is not suitable for future release updates.

Before a store or long-lived release, create a dedicated release keystore and store it only in GitHub Actions secrets. Never commit signing keys or passwords.

## Verification performed by CI

1. Confirm Godot version.
2. Import resources and parse scripts.
3. Run planet catalog and orbit-math checks.
4. Run mission-content validation.
5. Smoke-run the main scene headlessly.
6. Export an APK and verify ZIP integrity.
7. Inspect package identifier and permissions.
8. Fail if the APK requests Android internet permission.
9. Upload the APK artifact with a checksum printed in the build log.

A green build does not prove installation or frame performance on a physical phone. Those remain device acceptance checks.
