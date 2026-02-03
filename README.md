# Flutter Map App

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive Flutter application that combines interactive mapping, location-based services, and gamification features to provide an engaging exploration experience. Built with Firebase for backend services and Flutter Map for seamless cartography.

## 🌟 Features

### Core Functionality
- **Interactive Maps**: Powered by Flutter Map with customizable styles and smooth animations
- **Location Services**: Real-time GPS tracking and geolocation with permission handling
- **Place Discovery**: Explore points of interest with detailed information and photos
- **Route Planning**: Create optimized routes between multiple destinations
- **Navigation Guidance**: Turn-by-turn directions with text-to-speech integration

### User Experience
- **Authentication**: Secure login with email/password and Google Sign-In
- **User Profiles**: Personalized profiles with visit history and statistics
- **Favorites System**: Save and manage favorite places
- **Achievement System**: Gamified experience with unlockable achievements
- **Proximity Alerts**: Notifications when near points of interest

### Technical Features
- **Offline Support**: Cached map tiles and data for offline usage
- **Marker Clustering**: Efficient display of multiple map markers
- **Route Visualization**: Animated polylines showing planned routes
- **Responsive Design**: Optimized for mobile devices with portrait orientation

## 📸 Screenshots

<!-- Add your app screenshots here -->

*Screenshots will be added soon*

## 🚀 Installation

### Prerequisites
- Flutter SDK (^3.7.2)
- Dart SDK (^3.7.2)
- Firebase project with Authentication, Firestore, and Storage enabled
- Google Maps API key (for geocoding and directions)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_map_app.git
   cd flutter_map_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Enable Firestore Database
   - Download `google-services.json` and place it in `android/app/`
   - Configure Firebase options in `lib/firebase_options.dart`

4. **Environment Variables**
   - Create a `.env` file in the root directory
   - Add your API keys:
     ```
     GOOGLE_MAPS_API_KEY=your_api_key_here
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📖 Usage

### Getting Started
1. Launch the app and sign in with your preferred method
2. Select a city from the available options
3. Explore places on the interactive map
4. Tap on markers to view place details
5. Create routes by selecting multiple destinations

### Key Interactions
- **Map Navigation**: Pinch to zoom, drag to pan
- **Place Details**: Tap markers to view information sheets
- **Route Creation**: Use the drawer menu to access city/place selection
- **Achievements**: Check your profile for unlocked achievements
- **Settings**: Customize map styles and app preferences

## 🏗️ Architecture

### Project Structure
```
lib/
├── models/          # Data models (User, Place, City, Achievement)
├── screens/         # UI screens and pages
├── services/        # Business logic and external integrations
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

### Key Technologies
- **Frontend**: Flutter with Material Design
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Mapping**: Flutter Map with OpenStreetMap tiles
- **Location**: Geolocator for GPS services
- **State Management**: Provider pattern
- **Networking**: HTTP client for API calls

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices and effective Dart
- Write clear, concise commit messages
- Test on multiple devices and screen sizes
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter Map](https://pub.dev/packages/flutter_map) for the mapping functionality
- [Firebase](https://firebase.google.com/) for backend services
- [OpenStreetMap](https://www.openstreetmap.org/) for map data
- Flutter community for excellent packages and support

---

*Built with ❤️ using Flutter*