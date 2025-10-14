# eventide_example

Demonstrates how to use the eventide plugin.

## Run example app

Example app is set to use Swift Package Manager by default. Therefore there is no Podfile.

```sh
flutter config --enable-swift-package-manager
flutter pub get
# Mandatory to get a FlutterGeneratedPluginSwiftPackage with a correct iOS minimum version
flutter build ios --config-only --no-codesign
```