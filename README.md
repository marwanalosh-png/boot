# My Android App (Flutter)

Build locally (requires Flutter):
- cd my_android_app
- flutter create .   # generates android/ if missing
- flutter pub get
- flutter gen-l10n
- flutter run -t lib/main.dart
- flutter build apk -t lib/main.dart

Via GitHub Actions (APK artifact):
- Push repo and use .github/workflows/my-android-app.yml
