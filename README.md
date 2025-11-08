# 🌍 VoyaGo - Complete Travel Management App

<div align="center">

![VoyaGo Logo](https://img.shields.io/badge/VoyaGo-Travel%20Companion-blue?style=for-the-badge&logo=airplane)

**A comprehensive Flutter travel application with Firebase backend, featuring intelligent trip planning, real-time navigation, and AI-powered assistance.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFA000?style=flat&logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)

</div>

## 🚀 Features

### 🔐 **Authentication & Security**
- **Multi-Platform Login**: Email/Password + Google Sign-in integration
- **Secure Profile Management**: Photo upload, profile editing with Firebase Auth
- **Account Recovery**: Password reset and account verification

### 🗺️ **Smart Trip Planning**
- **AI-Powered Itineraries**: Intelligent trip suggestions based on preferences
- **Collaborative Planning**: Share and edit trips with travel companions
- **Detailed Trip Management**: Activities, locations, dates, and notes
- **Offline Trip Access**: Cached trip data for offline viewing

### 🧭 **Navigation & Maps**
- **Google Maps Integration**: Real-time navigation with offline support
- **Location Services**: Current location tracking and place search
- **Interactive Maps**: Trip route visualization and landmark discovery
- **Offline Maps**: Download areas for offline navigation

### 💰 **Expense Management**
- **Real-Time Tracking**: Categorized expense logging with photos
- **Smart Cost Splitting**: Automatic expense sharing among travelers
- **Analytics Dashboard**: Spending insights and budget tracking
- **Currency Support**: Multi-currency expense tracking

### 📖 **Travel Journal**
- **Photo Memories**: Rich media journal entries with location tagging
- **Trip Documentation**: Detailed daily logs with photos and notes
- **Memory Timeline**: Chronological view of your travel experiences
- **Export & Share**: Share journal entries and trip memories

### 🤖 **AI Travel Assistant**
- **Multilingual Chatbot**: Travel assistance in multiple languages
- **Smart Recommendations**: Personalized suggestions for activities and places
- **Real-Time Help**: Instant answers to travel questions
- **Context-Aware**: Location and trip-based intelligent responses

### 🏨 **Booking Integration**
- **Flight Search**: Mock flight booking with real-time price comparison
- **Hotel Reservations**: Hotel search and booking simulation
- **Ground Transport**: Bus and local transport booking options
- **Integrated Payments**: Secure payment processing simulation

### 🚨 **Safety Features**
- **Emergency SOS**: One-tap emergency location broadcasting
- **Real-Time Alerts**: Location sharing with emergency contacts
- **Safety Check-ins**: Automated safety status updates
- **Emergency Contacts**: Quick access to local emergency services

### 📱 **User Experience**
- **Material Design 3**: Modern, accessible UI with consistent theming
- **Offline Support**: Core functionality available without internet
- **Multi-Platform**: iOS and Android support
- **Responsive Design**: Optimized for tablets and phones

## 🏗️ Architecture

### **Frontend**
- **Framework**: Flutter 3.0+ with Dart 3.0+
- **State Management**: Provider pattern for reactive UI updates
- **Navigation**: Go Router for declarative navigation
- **UI Framework**: Material Design 3 with custom theming

### **Backend**
- **Authentication**: Firebase Authentication with multi-provider support
- **Database**: Cloud Firestore with real-time synchronization
- **Storage**: Firebase Storage for photos and documents
- **Functions**: Cloud Functions for AI integration and backend logic
- **Analytics**: Firebase Analytics for user behavior insights

### **External Services**
- **Maps**: Google Maps SDK for Android/iOS
- **AI**: Dialogflow for chatbot functionality
- **Geolocation**: Flutter location services
- **Image Processing**: Flutter image picker and compression

## 📱 Screenshots

<div align="center">

| Home Screen | Trip Planning | Navigation | Expense Tracker |
|------------|---------------|------------|-----------------|
| <img src="screenshots/home.png" width="200"> | <img src="screenshots/trip-planning.png" width="200"> | <img src="screenshots/navigation.png" width="200"> | <img src="screenshots/expenses.png" width="200"> |

| Travel Journal | AI Chatbot | Profile | Booking |
|---------------|------------|---------|---------|
| <img src="screenshots/journal.png" width="200"> | <img src="screenshots/chatbot.png" width="200"> | <img src="screenshots/profile.png" width="200"> | <img src="screenshots/booking.png" width="200"> |

</div>

## 🛠️ Setup & Installation

### **Prerequisites**
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** / **Xcode** for platform development
- **Firebase Project** with required services enabled
- **Google Cloud Console** access for Maps API

### **Firebase Configuration**

1. **Create Firebase Project**
   ```bash
   # Visit https://console.firebase.google.com
   # Create new project: "voyago-travel-app"
   ```

2. **Enable Required Services**
   - ✅ Authentication (Email/Password, Google)
   - ✅ Cloud Firestore Database
   - ✅ Firebase Storage
   - ✅ Cloud Functions
   - ✅ Firebase Analytics

3. **Download Configuration Files**
   ```bash
   # Android: Download google-services.json
   # Place in: android/app/google-services.json
   
   # iOS: Download GoogleService-Info.plist  
   # Place in: ios/Runner/GoogleService-Info.plist
   ```

### **Google Maps Setup**

1. **Enable APIs in Google Cloud Console**
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API

2. **Get API Key**
   ```bash
   # Visit: https://console.cloud.google.com/apis/credentials
   # Create API Key with appropriate restrictions
   ```

3. **Configure API Key**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY" />
   ```

### **Installation Steps**

1. **Clone Repository**
   ```bash
   git clone https://github.com/shakeel-33-code/voyago-travel-app.git
   cd voyago-travel-app
   ```

2. **Install Dependencies**
   ```bash
   # Flutter dependencies
   flutter pub get
   
   # Firebase Functions dependencies
   cd functions
   npm install
   cd ..
   ```

3. **Deploy Firebase Functions**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Deploy functions
   firebase deploy --only functions
   ```

4. **Deploy Security Rules**
   ```bash
   # Deploy Firestore and Storage rules
   firebase deploy --only firestore:rules,storage
   ```

5. **Run Application**
   ```bash
   # Run on connected device/simulator
   flutter run
   
   # Or build release version
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## 🔧 Configuration

### **Environment Variables**
Create `.env` file in project root:
```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
DIALOGFLOW_PROJECT_ID=your_dialogflow_project_id
FIREBASE_WEB_API_KEY=your_firebase_web_api_key
```

### **Firebase Security Rules**

**Firestore Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /trips/{tripId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid in resource.data.participants || 
         request.auth.uid == resource.data.createdBy);
    }
  }
}
```

**Storage Rules** (`storage.rules`):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 2 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 📁 Project Structure

```
voyago/
├── 📁 lib/
│   ├── 📁 models/              # Data models (User, Trip, Expense, etc.)
│   ├── 📁 services/            # Business logic and API services
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   └── location_service.dart
│   ├── 📁 screens/             # UI screens
│   │   ├── auth/              # Authentication screens
│   │   ├── home/              # Home and trip management
│   │   ├── navigation/        # Maps and navigation
│   │   ├── expenses/          # Expense tracking
│   │   ├── journal/           # Travel journal
│   │   ├── chatbot/           # AI assistant
│   │   ├── booking/           # Booking system
│   │   ├── sos/               # Emergency features
│   │   └── profile/           # User profile
│   ├── 📁 widgets/             # Reusable UI components
│   ├── 📁 utils/               # Helper functions and constants
│   └── main.dart              # Application entry point
├── 📁 functions/               # Firebase Cloud Functions
│   ├── index.js
│   ├── package.json
│   └── 📁 src/
├── 📁 android/                 # Android-specific configuration
├── 📁 ios/                     # iOS-specific configuration
├── firestore.rules            # Firestore security rules
├── storage.rules              # Firebase Storage rules
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## 🧪 Testing

### **Run Tests**
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### **Test Coverage**
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🚀 Deployment

### **Android Release**
```bash
# Build signed APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

### **iOS Release**
```bash
# Build iOS release
flutter build ios --release

# Archive for App Store
open ios/Runner.xcworkspace
# Use Xcode to archive and upload
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open Pull Request**

### **Development Guidelines**
- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Write unit tests for new features
- Update documentation for API changes
- Use meaningful commit messages

## 📋 Roadmap

### **Version 2.0 (Planned)**
- [ ] **Real-Time Collaboration**: Live trip editing with multiple users
- [ ] **Advanced Analytics**: Detailed travel statistics and insights
- [ ] **Social Features**: Trip sharing and travel community
- [ ] **Offline AI**: On-device AI assistance
- [ ] **Wearable Support**: Apple Watch and Wear OS integration

### **Version 1.5 (In Progress)**
- [ ] **Push Notifications**: Real-time trip updates and reminders
- [ ] **Dark Mode**: Complete dark theme implementation
- [ ] **Accessibility**: Enhanced screen reader and keyboard navigation
- [ ] **Performance**: Improved loading times and battery usage

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Shakeel Ahmed** - *Initial work* - [@shakeel-33-code](https://github.com/shakeel-33-code)

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase Team** for the robust backend platform
- **Material Design** for the beautiful design system
- **Open Source Community** for the incredible packages and tools

## 📞 Support

- **Email**: support@voyago.app
- **Issues**: [GitHub Issues](https://github.com/shakeel-33-code/voyago-travel-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shakeel-33-code/voyago-travel-app/discussions)

---

<div align="center">

**Made with ❤️ for travelers around the world**

[⭐ Star this repository](https://github.com/shakeel-33-code/voyago-travel-app) if you found it helpful!

</div>