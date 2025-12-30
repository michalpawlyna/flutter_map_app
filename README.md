# flutter_map_app

Aplikacja mobilna Flutter do przeglądania i zarządzania miejscami na mapie z funkcjami społecznościowymi i integracją Firebase.

## Opis

Ten projekt to aplikacja mapowa z następującymi funkcjonalnościami:
- wyświetlanie mapy i znaczników miejsc,
- wybór miasta i miejsc do odwiedzenia,
- trasy i polilinie (routing),
- lokalizacja użytkownika i przycisk centrowania,
- zapis ulubionych miejsc,
- system osiągnięć i powiadomień (dialogi odblokowań),
- integracja z Firebase (autoryzacja, Firestore),
- TTS (tekst na mowę) oraz analiza bliskości (proximity).

Projekt używa standardowej struktury Flutter i jest przygotowany pod Android/iOS.

## Funkcje (krótko)
- Logowanie (Firebase Auth)
- Przechowywanie danych użytkownika i miejsc w Firestore
- Widok mapy z markerami i szczegółami miejsca
- Trasowanie pomiędzy punktami oraz informacja o trasie
- Powiadomienia głosowe (TTS) i interakcje użytkownika

## Wymagania
- Flutter SDK (zalecane ostatnie stabilne wydanie)
- Dart
- Firebase CLI (do konfiguracji, opcjonalnie)

## Konfiguracja

1. Skopiuj repozytorium i otwórz w VS Code / Android Studio.
2. Zainstaluj zależności:

```bash
flutter pub get
```

3. Android: plik `google-services.json` jest już umieszczony w `android/app/`.
	iOS: dodaj `GoogleService-Info.plist` do projektu iOS jeśli chcesz uruchomić na iOS.
4. Plik `lib/firebase_options.dart` jest wygenerowany przez `flutterfire` i zawiera konfigurację Firebase.

## Uruchamianie

Uruchom aplikację na emulatorze lub urządzeniu:

```bash
flutter run
```

Do budowy release APK:

```bash
flutter build apk --release
```

## Struktura projektu (ważniejsze pliki)
- Główny punkt wejścia: [lib/main.dart](lib/main.dart)
- Konfiguracja Firebase: [lib/firebase_options.dart](lib/firebase_options.dart)
- Ekrany: [lib/screens/](lib/screens) (np. [lib/screens/map_screen.dart](lib/screens/map_screen.dart))
- Serwisy: [lib/services/](lib/services) (np. [lib/services/auth_service.dart](lib/services/auth_service.dart), [lib/services/firestore_service.dart](lib/services/firestore_service.dart))
- Widżety UI: [lib/widgets/](lib/widgets)

## Plik .env i klucz API

Projekt korzysta z klucza API do routingu (OpenRouteService). W repo musi znajdować się plik .env z następującą zmienną:

- OPENROUTE_API_KEY — klucz API OpenRouteService używany przez `lib/services/route_service.dart`.

Przykład zawartości pliku .env:

```
OPENROUTE_API_KEY=twój_openroute_api_key_tutaj
```






