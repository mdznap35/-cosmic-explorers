# Prototype showcase APK build

The standalone showcase APK starts from `scenes/prototypes/showcase_app.tscn` on the `prototype-showcase-app-buildfix-v1` review branch. The Sana-only preview export temporarily switches the main scene by replacing the existing `run/main_scene` setting, so it works regardless of which scene the showcase branch uses as its default entry point. The workflow restores the original project and export preset files before uploading the APK artifacts.
