# GanzJahr Rechnung

Android app (Flutter) for GanzJahr Garten & Objektpflege: customers, services, German invoices and quotes (DIN 5008 layout, PDF / print / share), payment reminders, §35a certificates, and monthly/yearly earnings reports.

- App languages: English, Deutsch, العربية (right-to-left). Invoices are always German.
- Data is stored on the phone (`ganzjahr_data.json`); Settings → Save backup exports everything.

## Build

Requirements: Flutter 3.47+ (Dart 3.13), Android SDK 36, Java 17.

```bash
flutter pub get
flutter test
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

## Structure

| Path | Content |
| --- | --- |
| `lib/models.dart` | Company, customer, service and document models |
| `lib/store.dart` | App state and local JSON storage |
| `lib/reports.dart` | Monthly / yearly earnings calculations |
| `lib/i18n.dart` | English / German / Arabic translations |
| `lib/pdf/invoice_pdf.dart` | German invoice, reminder, §35a and report PDFs |
| `lib/screens/` | UI screens |
