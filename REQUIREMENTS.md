# Specyfikacja Wymagań Funkcjonalnych i Niefunkcjonalnych
## Aplikacja Flutter Map App

---

## WYMAGANIA FUNKCJONALNE

### 1. AUTENTYFIKACJA I AUTORYZACJA

#### 1.1 Logowanie i Rejestracja
- **F1.1.1** Użytkownik może zalogować się za pomocą adresu e-mail i hasła
- **F1.1.2** Użytkownik może się zaarejestrować z nowym e-mailem i hasłem
- **F1.1.3** Użytkownik może zalogować się za pomocą konta Google (OAuth 2.0)
- **F1.1.4** Przy pierwszym logowaniu użytkownik konto jest tworzone w Firestore z domyślnymi wartościami:
  - `uid`, `email`, `username` (puste), `displayName`, `photoURL`
  - `totalPlacesVisited: 0`, `totalPlacesLiked: 0`, `totalRoutesCreated: 0`
  - `achievementsSummary`, `achievementsUnlockedAt`, `visitedPlaces`, `favouritePlaces`, `equippedAchievements` (puste kolekcje)
  - `createdAt` (timestamp serwera)

#### 1.2 Zarządzanie Sesją
- **F1.2.1** Aplikacja przechowuje informacje o aktualnie zalogowanym użytkowniku
- **F1.2.2** Użytkownik może się wylogować (wyczyści sesję lokalną i Google Sign-In)
- **F1.2.3** Stan zalogowania jest słuchany w real-time (`authStateChanges` stream)
- **F1.2.4** Po wylogowaniu użytkownik jest kierowany na ekran logowania

#### 1.3 Profil Użytkownika
- **F1.3.1** Użytkownik może edytować swoją nazwę wyświetlaną (`displayName`)
- **F1.3.2** Użytkownik może ustawić i zmienić nazwę użytkownika (`username`)
  - Walidacja: regex `^[a-z0-9._-]{3,30}$` (3-30 znaków, małe litery, cyfry, znaki: . _ -)
  - Unikalna w ramach aplikacji (walidacja na Firestore)
- **F1.3.3** Zmiany profilu są zapisywane w Firestore
- **F1.3.4** Zmiany są natychmiast aktualizowane w UI

---

### 2. MAPY I WYŚWIETLANIE LOKALIZACJI

#### 2.1 Mapa Interaktywna
- **F2.1.1** Aplikacja wyświetla interaktywną mapę (flutter_map, Carto basemap)
- **F2.1.2** Mapę można przesuwać i powiększać/zmniejszać (zoom: 4-18)
- **F2.1.3** Mapy nie można obracać (disabled InteractiveFlag.rotate)
- **F2.1.4** Mapa wyświetla kafelki w wysokiej rozdzielczości (retinaMode)
- **F2.1.5** Pierwsze otwarcie mapy centruje widok na ostatniej znanej pozycji użytkownika lub domyślnie na Polsce (52°N, 19°E)

#### 2.2 Lokalizacja Użytkownika
- **F2.2.1** Aplikacja żąda uprawnienia dostępu do lokalizacji (przy pierwszym uruchomieniu)
- **F2.2.2** Jeśli lokalizacja jest wyłączona, wyświetlana jest informacja o konieczności jej włączenia
- **F2.2.3** Jeśli uprawnienia są odmówione, wyświetlany jest błąd
- **F2.2.4** Bieżąca pozycja użytkownika jest wyświetlana na mapie (niebieski marker)
- **F2.2.5** Stream pozycji użytkownika jest aktualizowany w zależności od trybu:
  - **Idle**: aktualizacja co ~30s, dokładność niska, filtr 100m
  - **Normal** (domyślnie): aktualizacja co ~10s, dokładność wysoka, filtr 25m
  - **Tracking**: aktualizacja co ~5s, dokładność najwyższa, filtr 5m
- **F2.2.6** Emitowana pozycja musi mieć dokładność ≤ 2000m
- **F2.2.7** Pozycje z czasem < minEmitInterval i dystansem < 1m są filtrowane

#### 2.3 Przycisk Centrowania na Użytkowniku
- **F2.3.1** Istnieje przycisk "Centered on User" (CenterOnUserButtonWidget)
- **F2.3.2** Kliknięcie przycisku animuje mapę tak, aby użytkownik znalazł się w centrum
- **F2.3.3** Przycisk jest dostępny w rogu ekranu mapy

---

### 3. PUNKTY ZAINTERESOWANIA (PLACES) I MARKERY

#### 3.1 Ładowanie i Wyświetlanie Miejsc
- **F3.1.1** Aplikacja pobiera listę miejsc z Firestore (`places` kolekcja)
- **F3.1.2** Miejsca mogą być filtrowane po mieście (`getPlacesForCity(cityId)`)
- **F3.1.3** Każde miejsce ma:
  - `id`, `name`, `lat`, `lng`, `cityRef` (referencja do miasta)
  - `description`, `photoUrl` (opcjonalnie)
  - `likedCount` (liczba polubień)
- **F3.1.4** Miejsca są wyświetlane na mapie jako markery (ikony pin)
- **F3.1.5** Markery używają ikon: `assets/marker.png` (zwyczajny), `assets/marker_active.png` (aktywny)

#### 3.2 Klastrowanie Markerów
- **F3.2.1** Jeśli włączone klastrowanie, blisko leżące markery są grupowane w klastry
- **F3.2.2** Każdy klaster wyświetla liczbę markerów w czarnym kole
- **F3.2.3** Kliknięcie na klaster powoduje powiększenie mapy i wycentrowanie na klastrze
- **F3.2.4** Maksymalny promień klastra: 45px; rozmiar ikony: 40×40px

#### 3.3 Interakcja z Markerami
- **F3.3.1** Kliknięcie na marker:
  - Animuje marker (skaluje się na 1.2x)
  - Otwiera bottom sheet ze szczegółami miejsca
  - Wyświetla opis, zdjęcie, liczba polubień
- **F3.3.2** Bottom sheet zawiera przycisk "Nawiguj" do tego miejsca (generuje trasę)
- **F3.3.3** Markery odwiedzonych miejsc mają małą ikonę checkmark (niebieski, w lewym dolnym rogu)
- **F3.3.4** Jeśli miejsce jest częścią trasy wielopunktowej, marker wyświetla numer porządkowy (0-99)

#### 3.4 Polubienia (Favourite Places)
- **F3.4.1** Użytkownik może polubić/polubić miejsce (serce ikona w bottom sheet)
- **F3.4.2** Polubienia są przechowywane w Firestore:
  - Lista `favouritePlaces` w dokumencie użytkownika
  - `likedCount` na dokumencie miejsca (inkrementalne)
  - `totalPlacesLiked` w profilu użytkownika (licznik)
- **F3.4.3** Polubienie powoduje sprawdzenie i możliwe odblokowaniu osiągnięcia typu `likePlace`
- **F3.4.4** Użytkownik może usunąć polubienie (dekrementacja liczników)

---

### 4. TRASY (ROUTES)

#### 4.1 Generowanie Tras
- **F4.1.1** Aplikacja używa OpenRouteService API do generowania tras pieszych
- **F4.1.2** Użytkownik może wygenerować trasę od swojej pozycji do wybranego miejsca
- **F4.1.3** Alternatywnie użytkownik może wygenerować trasę dla wielu punktów (waypoints)
- **F4.1.4** Obsługiwane tryby transportu (setawalne w preferencjach):
  - `foot-walking` (domyślnie)
  - `cycling-regular`
  - `driving-car`
- **F4.1.5** Odpowiedź zawiera:
  - Listę współrzędnych trasy (GeoJSON LineString)
  - Dystans w metrach
  - Czas w sekundach

#### 4.2 Obsługa Błędów i Retry'e
- **F4.2.1** Jeśli API key ORS nie jest ustawiony, wyświetlany jest błąd
- **F4.2.2** Timeout żądania: 30 sekund
- **F4.2.3** Implementacja retry (max 3 próby) dla błędów 502, 503, 504
- **F4.2.4** Obsługa błędów:
  - 401/403: API key nieważny/wygasł
  - 429: Rate limit przekroczony
  - 400: Złe parametry trasy
- **F4.2.5** Błędy komunikowane użytkownikowi jako Toastification notifications

#### 4.3 Wyświetlanie Trasy
- **F4.3.1** Wygenerowana trasa wyświetla się na mapie jako linia (polyline) w kolorze (np. niebieski)
- **F4.3.2** Widget RoutePolylineWidget rysuje linię trasy
- **F4.3.3** Po wygenerowaniu trasy mapa automatycznie zmienia zoom/pozycję, by pokazać całą trasę (fit)
- **F4.3.4** Padding przy fit: top=60, left=60, right=60, bottom=(wysokość info widgetu + 20)
- **F4.3.5** Użytkownik może wyczyścić trasę (przycisk w RouteInfoWidget)

#### 4.4 Informacje o Trasie
- **F4.4.1** Widget RouteInfoWidget wyświetla w bottom sheet:
  - Całkowity dystans w km (z 1-2 miejscami po przecinku)
  - Całkowity czas w minutach/godzinach (sformatowany)
  - Przycisk "Wyczyść trasę"
  - Przycisk TTS (tekst-na-mowę) z informacjami o trasie
- **F4.4.2** TTS oznajmia dystans i czas w języku polskim

#### 4.5 Optymalizacja Wielopunktowych Tras
- **F4.5.1** Aplikacja może optymalizować kolejność odwiedzin dla wielu punktów
- **F4.5.2** Algorytm: Nearest Neighbor (greedy) + 2-opt local search
- **F4.5.3** Początkowe rozwiązanie: nearest neighbor od pozycji startu
- **F4.5.4** 2-opt iteruje do max 1000 iteracji lub brak poprawy
- **F4.5.5** Funkcja `optimizeWaypointsOrderWith2Opt(start, pointsToVisit)` zwraca indeksy optymalnej kolejności
- **F4.5.6** Liczba markerów wyświetla numer porządkowy odwiedzin (1, 2, 3, ...)
- **F4.5.7** Po każdej optymalizacji loguje się: dystans początkowy, liczba iteracji, dystans końcowy

---

### 5. PROXIMITY DETECTION (WYKRYWANIE BLISKOŚCI)

#### 5.1 Automatyczne Wykrywanie Wizyt
- **F5.1.1** ProximityService słucha stream pozycji użytkownika
- **F5.1.2** Jeśli użytkownik wejdzie w promień ~50m od miejsca i zostanie tam przez min. 15 sekund:
  - Wizyta jest raportowana do Firestore
  - Miejsce jest dodawane do `visitedPlaces` użytkownika
  - `totalPlacesVisited` jest inkrementowana
- **F5.1.3** Po raportowaniu wizyty wyświetla się dialog z informacją o zdobyciu osiągnięcia (jeśli dotyczy)

#### 5.2 Cooldown i Debouncing
- **F5.2.1** Po zdetekcji wizyty, to samo miejsce nie może być ponownie zdetekcji przez 30 minut (cooldown)
- **F5.2.2** Gdy użytkownik opuszcza promień, licznik czasu wejścia jest resetowany
- **F5.2.3** Jeśli alert jest wyświetlany, nowe zdetekcje są ignorowane do zamknięcia alertu

#### 5.3 Filtrowanie Pozycji
- **F5.3.1** Pozycje o dokładności > 2000m są pomijane
- **F5.3.2** Pozycje, które są bliżej niż 1m od ostatniej i mają mały odstęp czasowy, są filtrowane

---

### 6. OSIĄGNIĘCIA (ACHIEVEMENTS)

#### 6.1 Model Osiągnięć
- **F6.1.1** Każde osiągnięcie ma:
  - `id`, `title`, `desc` (opis), `key` (unikalny klucz)
  - `type` (enum: `visit`, `likePlace`, `createRoute`, `unknown`)
  - `criteria` (mapa z parametrami, np. `target`: liczba wizyt do odblokowani)
  - `photoUrl` (opcjonalnie)
  - `createdAt` (timestamp)
- **F6.1.2** Osiągnięcia są przechowywane w Firestore (`achievements` kolekcja)

#### 6.2 Automatyczne Odblokowywanie Osiągnięć
- **F6.2.1** Przy raportowaniu wizyty sprawdzane są osiągnięcia typu `visit`
- **F6.2.2** Przy polubienia miejsca sprawdzane są osiągnięcia typu `likePlace`
- **F6.2.3** Przy tworzeniu trasy sprawdzane są osiągnięcia typu `createRoute`
- **F6.2.4** Osiągnięcie jest odblokowywane jeśli spełnione są kryteria (np. `totalPlacesVisited >= target`)
- **F6.2.5** Każde osiągnięcie może być odblokowywane tylko raz na użytkownika
- **F6.2.6** Gdy osiągnięcie jest odblokowywane:
  - `achievementsSummary[id] = true` (flaga)
  - `achievementsUnlockedAt[id] = serverTimestamp` (czas)

#### 6.3 Wyświetlanie Osiągnięć
- **F6.3.1** Na ekranie profilu wyświetla się lista wszystkich osiągnięć
- **F6.3.2** Zblokowywane osiągnięcia wyświetlają się jako szare/przygaszone
- **F6.3.3** Odblokowywane osiągnięcia wyświetlają się w pełnych barwach
- **F6.3.4** Przy odblokowywaniu wyświetla się dialog z informacją o zdobytym osiągnięciu
  - Ikona, tytuł, opis
  - Animacja (confetti, Lottie)

#### 6.4 Wyposażenie Osiągnięć
- **F6.4.1** Użytkownik może wybrać kilka osiągnięć do "wyposażenia" (`equippedAchievements`)
- **F6.4.2** Wyposażone osiągnięcia mogą być wyświetlane w profilu lub widgecie użytkownika
- **F6.4.3** Lista wyposażonych osiągnięć jest zapisywana w Firestore

---

### 7. WYBÓR MIAST I MIEJSC

#### 7.1 Ekran Wyboru Miast
- **F7.1.1** Istnieje ekran `SelectCityScreen` z listą dostępnych miast
- **F7.1.2** Użytkownik może wybrać miasto
- **F7.1.3** Po wyborze miasta:
  - Mapa wyświetla tylko miejsca z tego miasta
  - Mapa wycentrowuje się na mieście (jeśli dostępna pozycja)

#### 7.2 Ekran Wyboru Miejsc
- **F7.2.1** Istnieje ekran `SelectPlacesScreen` do filtrowania/wyszukiwania miejsc
- **F7.2.2** Użytkownik może wyszukać miejsca po nazwie
- **F7.2.3** Wyniki wyszukiwania są wyświetlane na liście
- **F7.2.4** Kliknięcie na miejsce otwiera bottom sheet ze szczegółami

#### 7.3 Wyszukiwanie Miejsc
- **F7.3.1** Ekran `SearchPlacesScreen` pozwala wyszukać miejsca
- **F7.3.2** Wyszukiwanie jest case-insensitive
- **F7.3.3** Rezultaty filtrują się na żywo podczas pisania

---

### 8. INTERFEJS UŻYTKOWNIKA

#### 8.1 Nawigacja
- **F8.1.1** Główny ekran to `MainScaffold` z navigacją bottom tab/drawer
- **F8.1.2** Dostępne ekrany:
  - MapScreen (ekran mapy)
  - ProfileScreen (profil użytkownika)
- **F8.1.3** AppDrawer zawiera menu z opcjami:
  - Wybór miasta
  - Ustawienia
  - Wylogowanie
  - Dostęp do ekranów (Achievement, Favourite Places, itp.)

#### 8.2 LoadingScreen
- **F8.2.1** Wyświetlany podczas inicjalizacji aplikacji i ładowania danych
- **F8.2.2** Wyświetla loading indicator

#### 8.3 Dialogi i Notyfikacje
- **F8.3.1** Błędy są wyświetlane jako Toastification (toast notifications)
  - Typ: error/success/info
  - Pozycja: bottom center
  - Auto close: 4 sekundy
- **F8.3.2** Osiągnięcia wyświetlane w dedykowanych dialogach z animacjami
- **F8.3.3** Bottom sheets dla szczegółów miejsca i informacji o trasie

#### 8.4 Dostępność (A11y)
- **F8.4.1** Markery mają semantyczne etykiety (`Semantics` widgety)
- **F8.4.2** Etykiety zawierają: nazw miejsca, numer porządkowy (jeśli w trasie), status odwiedzenia

---

### 9. INNE FUNKCJONALNOŚCI

#### 9.1 Text-to-Speech (TTS)
- **F9.1.1** TTS Service obsługuje mowę w języku polskim (pl-PL)
- **F9.1.2** TTS może czytać informacje o trasie (dystans, czas)
- **F9.1.3** Kontrola: play, pause, stop
- **F9.1.4** ValueNotifier śledzi stan mówienia (`isSpeaking`)

#### 9.2 Ustawienia
- **F9.2.1** Ekran SettingsScreen pozwala konfigurować:
  - Tryb transportu (pieszych, rowerowy, samochód)
  - (Opcjonalnie) innych ustawień
- **F9.2.2** Ustawienia są przechowywane w `SharedPreferences`

#### 9.3 Ulubione Miejsca
- **F9.3.1** Użytkownik widzi swoją listę ulubionych miejsc na ekranie FavouritePlacesScreen
- **F9.3.2** Lista synchronizuje się z Firestore (`favouritePlaces` field)

#### 9.4 Ekran Zarządzania Osiągnięciami
- **F9.4.1** ManageAchievementsScreen pozwala wybrać osiągnięcia do wyposażenia
- **F9.4.2** Zmiana wyposażenia jest zapisywana w Firestore

---

## WYMAGANIA NIEFUNKCJONALNE

### 1. WYDAJNOŚĆ

#### 1.1 Mapa i Rendering
- **NF1.1.1** Mapa powinna być responsywna (< 100ms do przesunięcia/powiększenia)
- **NF1.1.2** Cache obrazów ogranicony do 100 obrazów i ~50 MB (max)
- **NF1.1.3** Obrazy markerów ładowane asynchronicznie (flutter_cache_manager)
- **NF1.1.4** Rendering markerów z RepaintBoundary do optymalizacji

#### 1.2 Firestore Queries
- **NF1.2.1** Zapytania do Firestore powinny być efektywne (indeksowanie w Firestore)
- **NF1.2.2** Pobieranie miejsc jednorazowo przy inicjalizacji (z possibility cache'owania)
- **NF1.2.3** Stream subskrypcji dla visitedPlaces (real-time updates)

#### 1.3 Location Service
- **NF1.3.1** Aktualizacja pozycji backendowa bez blokownia UI (stream na osobnym procesie)
- **NF1.3.2** Filtrowanie pozycji zmniejsza liczbę event'ów wysyłanych do UI

#### 1.4 OpenRouteService API
- **NF1.4.1** Cache wyników tras (SharedPreferences) — opcjonalnie
- **NF1.4.2** Retry'e z backoffem (2s, 4s, 6s) dla krótkoterminowych błędów
- **NF1.4.3** Timeouty (30s) na żądania sieciowe

### 2. BEZPIECZEŃSTWO

#### 2.1 Autentyfikacja
- **NF2.1.1** Hasła przechowywane są przez Firebase Auth (hashed, secure)
- **NF2.1.2** Tokeny dostępu (JWT) zarządzane przez Firebase
- **NF2.1.3** Google OAuth używa officjalnych bibliotek (google_sign_in, firebase_auth)

#### 2.2 API Keys
- **NF2.2.1** OpenRouteService API key przechowywany w `.env` (NOT zacommitowany do Git)
- **NF2.2.2** API key w `.env` jest ładowany przez `flutter_dotenv`
- **NF2.2.3** **ZAGROŻENIE**: API key jest widoczny w kodzie klienckiego (apk/ipa) — zalecane: backend-proxy

#### 2.3 Firestore Security Rules
- **NF2.3.1** Reguły powinny być restrykcyjne:
  - Użytkownik może czytać/pisać tylko swój dokument
  - Publiczne kolekcje (places, cities, achievements) tylko do odczytu
- **NF2.3.2** Operacje powinny być validowane na backendzie (Firebase Cloud Functions)

#### 2.4 Dane Wrażliwe
- **NF2.4.1** Email i dane profilu są przechowywane w Firestore
- **NF2.4.2** Wizyta do miejsca (odwiedzane lokalizacje) są przechowywane — RODO considerations
- **NF2.4.3** Brak szyfrowania end-to-end na klienta (szyfrowanie transmisji HTTPS)

#### 2.5 Walidacja Danych
- **NF2.5.1** Username walidowany regexem na klienta i serwerze
- **NF2.5.2** Email walidowany przez Firebase Auth
- **NF2.5.3** Współrzędne lokalizacji walidowane (lat -90 to +90, lng -180 to +180)

### 3. OBSŁUGA OFFLINE

#### 3.1 Mapy
- **NF3.1.1** Mapy wymagają połączenia internetowego (Carto basemap online)
- **NF3.1.2** Brak offline map cache'a
- **NF3.1.3** **ZAGROŻENIE**: W offline aplikacja nie wyświetli mapy

#### 3.2 Lokalizacja
- **NF3.2.1** Lokalizacja GPS działa bez internetu
- **NF3.2.2** Proximity detection działa offline (logika lokalna)

#### 3.3 OpenRouteService
- **NF3.3.1** Routing wymaga internetu
- **NF3.3.2** Brak offline routingu lub pre-cache tras
- **NF3.3.3** **ZAGROŻENIE**: Bez internetu użytkownik nie może generować tras

#### 3.4 Firestore
- **NF3.4.1** Firestore obsługuje offline persistence (domyślnie włączone)
- **NF3.4.2** Dane mogą być czytane z cache offline
- **NF3.4.3** Zapisy offline są synchronizowane gdy połączenie wróci

### 4. SKALOWALNOŚĆ

#### 4.1 Baza Danych
- **NF4.1.1** Firestore: pay-per-read/write model
- **NF4.1.2** Każda wizyta = 1 read + 1-2 writes (raporty + achievement check)
- **NF4.1.3** Przy 10k użytkowników, 5 wizyt/dzień = ~250k writes/dzień
- **NF4.1.4** **ZAGROŻENIE**: Koszty mogą rosnąć nielinearly przy wzroście użytkowników

#### 4.2 API Routing
- **NF4.2.1** OpenRouteService: free tier ma limitacje na żądania
- **NF4.2.2** Brak rate limiting na stronie klienta (risk of overuse)
- **NF4.2.3** **ZAGROŻENIE**: Masowe generowanie tras może wyczerpać free tier

#### 4.3 Storage
- **NF4.3.1** Cache obrazów: ~50 MB per device
- **NF4.3.2** Cache SharedPreferences: ustawienia + małe dane
- **NF4.3.3** Firestore: każdy dokument ~ kilka KB

### 5. RESPONSYWNOŚĆ URZĄDZENIA

#### 5.1 Orientacja Ekranu
- **NF5.1.1** Aplikacja obsługuje tylko orientację pionową (portrait)
- **NF5.1.2** Landscape jest wyłączona w `main.dart` (SystemChrome.setPreferredOrientations)

#### 5.2 Rozdzielczość Ekranu
- **NF5.2.1** UI responsywny na ekranach od ~5" do ~7" (telefony i tablety)
- **NF5.2.2** Bottom sheets i dialogi dostosowują się do rozmiaru ekranu

#### 5.3 Czcionka i Kontrast
- **NF5.3.1** Material Design 3 (default Flutter tema)
- **NF5.3.2** Brak dedykowanego dark mode (domyślnie light theme)

### 6. KOMPATYBILNOŚĆ PLATFORMY

#### 6.1 Android
- **NF6.1.1** Cel: API level 21+ (Android 5.0)
- **NF6.1.2** Uprawnienia: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`
- **NF6.1.3** Używane biblioteki Android-specific:
  - `geolocator_android` (AndroidSettings, intervalDuration)

#### 6.2 iOS
- **NF6.2.1** Cel: iOS 12.0+
- **NF6.2.2** Info.plist: `NSLocationWhenInUseUsageDescription`
- **NF6.2.3** Wspomnianie geolocator i firebase_auth działa na iOS

#### 6.3 Web
- **NF6.3.1** Aplikacja prawdopodobnie NIE jest zoptymalizowana dla web
- **NF6.3.2** Flutter web support jest częściowy

### 7. PRYWATNOŚĆ I ZGODNOŚĆ PRAWNA

#### 7.1 RODO (EU General Data Protection Regulation)
- **NF7.1.1** Aplikacja zbiera: email, nazwa, zdjęcie profilowe, lokalizacje (wizyta)
- **NF7.1.2** **WYMAGANE**: Privacy Policy i Terms of Service
- **NF7.1.3** **WYMAGANE**: Jawna zgoda użytkownika na przetwarzanie danych
- **NF7.1.4** **WYMAGANE**: Możliwość usunięcia konta i powiązanych danych
- **NF7.1.5** Brak dedicated funkcji do RODO compliance w kodzie (NIEZAIMPLEMENTOWANE)

#### 7.2 Cookies i Tracking
- **NF7.2.1** Brak cookies (aplikacja natywna, nie web)
- **NF7.2.2** Google Sign-In może wysyłać dane do Google (analytics, etc.)
- **NF7.2.3** Firebase zbiera usage analytics (domyślnie włączone)

#### 7.3 Ochrona Danych
- **NF7.3.1** Transmisja HTTPS (Firebase)
- **NF7.3.2** Brak end-to-end encryption (ETE) na klienta
- **NF7.3.3** Firestore encryption at-rest (Google Cloud)

### 8. NIEZAWODNOŚĆ I STABILNOŚĆ

#### 8.1 Error Handling
- **NF8.1.1** Błędy sieciowe obsługiwane z timeoutami i retry'ami
- **NF8.1.2** Błędy Firestore obsługiwane (permission denied, network, etc.)
- **NF8.1.3** Błędy lokalizacji komunikowane użytkownikowi (toasts)
- **NF8.1.4** Crash logs: brak dedykowanego serwisu (Crashlytics opcjonalny)

#### 8.2 Logging
- **NF8.2.1** Debug logs w kodzie (debugPrint)
- **NF8.2.2** Nie ma centralizowanego logging serwisu
- **NF8.2.3** **ZAGROŻENIE**: W produkcji debugPrint może być wyłączony

#### 8.3 Testing
- **NF8.3.1** Brak unit testów w przydzielonym kodzie
- **NF8.3.2** Brak integration testów
- **NF8.3.3** **REKOMENDACJA**: Dodać testy dla RouteService, AchievementService, ProximityService

#### 8.4 Wydania (Releases)
- **NF8.4.1** Android: bundle (AAB) dla Play Store
- **NF8.4.2** iOS: ipa dla App Store
- **NF8.4.3** Brak dedykowanego CI/CD (GitHub Actions, Fastlane)

### 9. DOSTĘPNOŚĆ (A11y)

#### 9.1 Screen Reader Support
- **NF9.1.1** Widgety mają `Semantics` labels dla voice-over
- **NF9.1.2** Markery na mapie mają semantic labels

#### 9.2 Kontrast i Czcionka
- **NF9.2.1** Material Design 3 zapewnia contrast ratios zgodnie z WCAG
- **NF9.2.2** Domyślny rozmiar czcionki: system default

#### 9.3 Nawigacja
- **NF9.3.1** Wszystkie elementy nawigowalne z klawiatury (Focus nodes)
- **NF9.3.2** Bottom sheets i dialogi dostępne dla czytnika ekranu

### 10. LOKALIZACJA (I18n / L10n)

#### 10.1 Języki
- **NF10.1.1** Interfejs głównie w **języku polskim**
- **NF10.1.2** TTS w języku polskim (pl-PL)
- **NF10.1.3** Brak dedykowanej obsługi wielojęzyczności (flutter_localizations)

#### 10.2 Formaty
- **NF10.2.1** Daty: Firestore timestamps (serverTimestamp)
- **NF10.2.2** Liczby: ',' jako separator dziesiętny (locale polish)
- **NF10.2.3** Odległości: metry, kilometry

### 11. INFRASTRUKTURA I DEPLOYMENT

#### 11.1 Firebase
- **NF11.1.1** Firebase Project Setup (firebase.json, google-services.json)
- **NF11.1.2** Firestore Database (Fire store emulator opcjonalnie)
- **NF11.1.3** Firebase Auth
- **NF11.1.4** Firebase Hosting (opcjonalnie dla web)

#### 11.2 Environment Variables
- **NF11.2.1** `.env` plik z OpenRouteService API key
- **NF11.2.2** `.env` nie powinien być zacommitowany (`.gitignore`)

#### 11.3 Build Configuration
- **NF11.3.1** Android: build.gradle.kts, local.properties
- **NF11.3.2** iOS: Podfile, Runner.xcodeproj
- **NF11.3.3** Web: pubspec.yaml konfiguracja

---

## PODSUMOWANIE

### Główne Siły Aplikacji
✅ Interaktywna mapa z clustering i obsługą GPS  
✅ System gamifikacji (achievements) z automatycznym odblokowywaniem  
✅ Routing pieszych z optymalizacją wielopunktowych tras  
✅ Proximity detection w real-time  
✅ Integracja Firebase (Auth, Firestore)  
✅ UX z bottom sheets, animacjami, notyfikacjami  
✅ TTS (polskiego)  

### Główne Zagrożenia / Brakujące Funkcjonalności
❌ Brak offline map i offline routingu  
❌ API key OpenRouteService widoczny w kodzie (security risk)  
❌ Brak RODO compliance w kodzie (privacy policy, consent, delete account)  
❌ Brak unit/integration testów  
❌ Brak centralized error logging/monitoring  
❌ Brak user-generated content (recenzje, zdjęcia)  
❌ Brak dark mode / theme customization  
❌ Brak multi-language support  
❌ Potencjalne wysokie koszty Firestore przy skalowaniu  

### Rekomendacje do Rozwoju
1. **Security**: Przenieść ORS API na backend-proxy
2. **Offline**: Implementować offline maps cache + local routing engine
3. **Privacy**: Dodać Privacy Policy, consent dialog, delete account flow
4. **Testing**: Napisać unit testy dla serwisów
5. **Monitoring**: Integrować Firebase Crashlytics / Custom Logging
6. **UGC**: Rozważyć recenzje i zdjęcia użytkowników
7. **Monetization**: Planować free/premium model
8. **i18n**: Przygotować struktur do wielojęzyczności

---

**Data dokument**: 4 Stycznia 2026  
**Status**: Wersja 1.0 (based on code analysis)
