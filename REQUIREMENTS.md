# Wymagania Systemowe i Instrukcja Instalacji - Flutter Map App

## 1. Wymagania Systemowe


### 1.2 Flutter SDK
- **Wersja Minimalna**: Flutter SDK z Dart SDK ^3.7.2
- **Kanał**: Stable channel (zalecane)
- Pobieranie: https://flutter.dev/docs/get-started/install

### 1.3 Dart SDK
- **Wersja**: Dart ^3.7.2 (instalowane wraz z Flutter)
- Zarządzane automatycznie przez Flutter SDK

### 1.4 Android
- **Minimum SDK**: API 23 (Android 6.0)
- **Target SDK**: API 34+ (Android 14+)
- **Android Studio**: 4.1+ (opcjonalnie, można używać VS Code)
- **NDK**: Wersja 27.0.12077973
- **Java Development Kit (JDK)**: JDK 11 lub nowszy
- **Gradle**: Wersja 8.0+ (zarządzana przez projekt)

**Wymagane Komponenty Android SDK:**
- Android SDK Platform 34
- Android SDK Platform 23
- Android SDK Tools
- Android Emulator (opcjonalnie)

### 1.5 iOS (jeśli docelowa platforma to iOS)
- **Minimalna wersja iOS**: iOS 11.0+
- **Xcode**: 12.0 lub nowsze
- **CocoaPods**: Automatycznie instalowane przez Flutter
- **Mac z Apple Silicon lub Intel** do budowania
- **Developer Account Apple**: Do deploymentu na urządzenia fizyczne

### 1.6 Narzędzia Dodatkowe
- **Git**: Wersja 2.0+ (do klonowania repo i version control)
- **OpenSSL**: Dla bezpiecznych połączeń HTTPS
- **IDE/Edytor**: VS Code, Android Studio, lub IntelliJ IDEA

## 2. Wymagania Projektowe

### 2.1 Zależności Firebase
Aplikacja używa Firebase dla:
- **Firebase Auth** v5.7.0 - Autoryzacja użytkowników (Google Sign-In)
- **Cloud Firestore** v5.6.9 - Baza danych użytkowników i miejsc
- **Firebase Core** v3.15.2 - Inicjalizacja Firebase

**Wymagane Konfiguracje:**
- Plik `android/app/google-services.json` (Firebase Console)
- Plik `ios/Runner/GoogleService-Info.plist` (dla iOS)
- Firebase Project ID i API Keys

### 2.2 API Zewnętrzne
- **OpenRouteService API**: Do wyznaczania tras
  - Klucz API: Przechowywany w pliku `.env`
  - Wymaga: `OPENROUTE_API_KEY` environment variable
  - Strona: https://openrouteservice.org/

### 2.3 Uprawnienia i Konfiguracja
#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

#### iOS (Info.plist)
```
NSLocationWhenInUseUsageDescription - dostęp do lokalizacji
NSLocationAlwaysAndWhenInUseUsageDescription - śledzenie w tle
```

### 2.4 Główne Zależności Projektu

| Pakiet | Wersja | Przeznaczenie |
|--------|--------|---------------|
| firebase_core | ^3.15.2 | Inicjalizacja Firebase |
| firebase_auth | ^5.7.0 | Autoryzacja użytkowników |
| google_sign_in | ^7.1.1 | Google OAuth |
| cloud_firestore | ^5.6.9 | Baza danych |
| flutter_map | ^7.0.0 | Widget mapy |
| geolocator | ^14.0.1 | Dostęp do GPS |
| flutter_dotenv | ^5.2.1 | Zmienne środowiskowe |
| latlong2 | ^0.9.1 | Współrzędne geograficzne |
| flutter_tts | ^4.2.3 | Text-to-Speech |
| flutter_map_marker_cluster | ^1.4.0 | Klasterowanie markerów |
| flutter_map_animations | ^0.7.1 | Animacje mapy |
| cached_network_image | ^3.4.1 | Cache obrazów sieciowych |
| shared_preferences | ^2.5.3 | Lokalny storage |
| provider | ^6.0.5 | State management |
| confetti | ^0.8.0 | Efekty animacji |

## 3. Instrukcja Instalacji

### 3.1 Konfiguracja Środowiska

#### Windows
1. Pobierz Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. Rozpakuj do folderu bez spacji, np. `C:\flutter`
3. Dodaj do zmiennych środowiskowych PATH:
   ```
   C:\flutter\bin
   C:\flutter\bin\cache\dart-sdk\bin
   ```
4. Zweryfikuj instalację:
   ```bash
   flutter --version
   dart --version
   ```

#### macOS
```bash
# Zainstaluj Homebrew (jeśli nie zainstalowany)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Zainstaluj Flutter
brew install flutter

# Zweryfikuj
flutter --version
```

#### Linux
```bash
# Zainstaluj wymagane pakiety
sudo apt-get install git curl

# Pobierz Flutter
git clone https://github.com/flutter/flutter.git ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Dodaj do ~/.bashrc lub ~/.zshrc
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# Zweryfikuj
flutter --version
```

### 3.2 Konfiguracja Android

#### Windows
1. Zainstaluj Android Studio: https://developer.android.com/studio
2. Uruchom Android Studio i zainstaluj wymagane SDK:
   - Android SDK Platform 34
   - Android SDK Platform 23
   - Android Emulator
3. Akceptuj licencje:
   ```bash
   flutter doctor --android-licenses
   ```
4. Utwórz emulator Android:
   ```bash
   flutter emulators --create
   ```

#### macOS/Linux
```bash
# Zainstaluj Java 11
# macOS: brew install openjdk@11
# Linux: sudo apt-get install openjdk-11-jdk

# Zainstaluj Android SDK Command-line Tools
# Pobierz z: https://developer.android.com/studio

# Akceptuj licencje
flutter doctor --android-licenses
```

### 3.3 Konfiguracja iOS (macOS only)

```bash
# Zainstaluj Xcode (ze App Store) lub:
xcode-select --install

# Zainstaluj CocoaPods
sudo gem install cocoapods

# Zweryfikuj
flutter doctor
```

### 3.4 Klonowanie i Konfiguracja Projektu

1. **Klonuj repozytorium:**
   ```bash
   git clone <repo_url>
   cd flutter_map_app
   ```

2. **Zainstaluj zależności Flutter:**
   ```bash
   flutter pub get
   ```

3. **Skonfiguruj Firebase:**
   - Przejdź do Firebase Console (https://console.firebase.google.com)
   - Utwórz projekt Flutter
   - Zaregisteruj aplikację Android i iOS
   - Pobierz `google-services.json` do `android/app/`
   - Pobierz `GoogleService-Info.plist` do `ios/Runner/`

4. **Utwórz plik `.env`:**
   ```
   OPENROUTE_API_KEY=twój_openroute_api_key_tutaj
   ```
   - Plik umieść w głównym katalogu projektu
   - Uzyskaj klucz z: https://openrouteservice.org/

5. **Zweryfikuj Setup:**
   ```bash
   flutter doctor
   ```
   Powinno być bez błędów (✓).

### 3.5 Uruchamianie Aplikacji

#### Na Emulatorze Android
```bash
# Lista dostępnych emulatorów
flutter emulators

# Uruchom emulator
flutter emulators --launch <emulator_id>

# Uruchom aplikację
flutter run
```

#### Na Urządzeniu Fizycznym (Android)
```bash
# Podłącz urządzenie USB i włącz Developer Mode
# Zweryfikuj połączenie
flutter devices

# Uruchom aplikację
flutter run
```

#### Na iOS (macOS)
```bash
# Lista dostępnych symulatorów
xcrun simctl list devices

# Otwórz iOS Simulator (jeśli nie otwarty)
open -a Simulator

# Uruchom aplikację
flutter run -d ios
```

### 3.6 Budowanie Release APK (Android)

```bash
# Opuszczaj debugger
flutter build apk --release

# Plik wyjściowy: build/app/outputs/apk/release/app-release.apk
```

### 3.7 Budowanie iOS App Bundle

```bash
flutter build ios --release
# Następnie użyj Xcode do submisji na App Store
```

## 4. Rozwiązywanie Problemów

### Problem: `Flutter SDK nie znaleziony`
```bash
# Zweryfikuj PATH
flutter doctor

# Jeśli nie działa, ustaw ścieżkę ręcznie
export FLUTTER_ROOT=/ścieżka/do/flutter
export PATH=$FLUTTER_ROOT/bin:$PATH
```

### Problem: `Gradle build nie powiedzie się`
```bash
# Wyczyść cache
flutter clean
rm -rf build/
flutter pub get

# Przebuduj
flutter build apk
```

### Problem: `Błędy Firebase`
- Zweryfikuj, że `google-services.json` jest w `android/app/`
- Zweryfikuj Firebase Project ID w `lib/firebase_options.dart`
- Sprawdź uprawnienia w Firebase Console

### Problem: `Brak uprawnień do lokalizacji`
- Android: Uprawnienia są deklarowane w `AndroidManifest.xml`
- iOS: Wiadomości o dostępie są skonfigurowane w `Info.plist`
- Runtime permissions: Aplikacja powinna prosić podczas działania

### Problem: `Błędy OpenRouteService API`
- Zweryfikuj, że `.env` zawiera poprawny klucz API
- Sprawdzaj limit zapytań API
- Zweryfikuj bezpośrednie połączenie do API

## 5. Specyfikacja Sprzętu Zalecanego

### Development Machine
| Komponent | Minimum | Zalecane |
|-----------|---------|----------|
| CPU | Intel i5 / Ryzen 5 | Intel i7+ / Ryzen 7+ |
| RAM | 8 GB | 16 GB+ |
| Dysk SSD | 256 GB | 512 GB+ |
| GPU | Zintegrowana | Dedykowana (dla emulatora) |

### Target Device (Android)
- RAM: 2 GB+ (ideal 4 GB+)
- Storage: 150 MB+
- Screen: 4.5" - 6.5"

### Target Device (iOS)
- iPhone XS, 11, 12, 13, 14, 15+
- iOS 11.0+
- RAM: 2 GB+

## 6. Struktura Projektu

```
flutter_map_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── firebase_options.dart     # Firebase config
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── route_service.dart
│   └── widgets/                  # Reusable UI components
├── android/                      # Android-specific config
├── ios/                         # iOS-specific config
├── pubspec.yaml                 # Dependencies
├── .env                         # API keys (nie pushować!)
└── google-services.json         # Firebase (Android)
```

## 7. Polecane Narzędzia Dodatkowe

- **VS Code Extensions**: Dart, Flutter, Firebase
- **Android Studio**: Dla zaawansowanego debugowania
- **Postman**: Do testowania REST API (OpenRouteService)
- **Firebase CLI**: Do deploymentu funkcji Cloud Functions
- **DevTools**: Zainteresowany w Flutter `flutter pub global activate devtools`

## 8. Dokumentacja i Zasoby

- Flutter: https://flutter.dev/docs
- Firebase: https://firebase.google.com/docs
- OpenRouteService: https://openrouteservice.org/docs
- Flutter Map: https://github.com/fleaflet/flutter_map
- Dart Language: https://dart.dev/guides

## 9. Wersje Komponentów - Podsumowanie

```yaml
# pubspec.yaml
environment:
  sdk: ^3.7.2

# Android Configuration
minSdk: 23
targetSdk: 34 (Android 14)
compileSdk: 34

# Java
JVM Target: 11

# iOS (if applicable)
Minimum iOS: 11.0+
Xcode: 12.0+
```

---

**Ostatnia Aktualizacja**: Styczeń 2026  
**Autor**: Flutter Map App Development Team  
**Status**: Aktualny
