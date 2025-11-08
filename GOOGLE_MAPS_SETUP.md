# Google Maps API Setup Guide for VoyaGo

## 🗺️ Quick Setup Instructions

### 1. Google Cloud Console Setup

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Create a new project or select existing project

2. **Enable Required APIs**
   Navigate to "APIs & Services" > "Library" and enable:
   - ✅ Maps SDK for Android
   - ✅ Maps SDK for iOS
   - ✅ Directions API
   - ✅ Geocoding API

3. **Create API Key**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy your API key

4. **Secure Your API Key** (Recommended)
   - Click on your API key to edit
   - Under "Application restrictions":
     - For Android: Add your app's package name and SHA-1 fingerprint
     - For iOS: Add your app's bundle identifier
   - Under "API restrictions":
     - Select "Restrict key"
     - Choose the 4 APIs listed above

### 2. Configure VoyaGo App

**Update the API key in your app:**

1. Open `lib/config/app_config.dart`
2. Replace the placeholder:
   ```dart
   static const String googleMapsApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```
   With your actual key:
   ```dart
   static const String googleMapsApiKey = 'AIzaSyB...your-key-here';
   ```

### 3. Platform-Specific Setup

#### **Android Setup**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_API_KEY_HERE"/>
</application>
```

#### **iOS Setup**
Add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 4. Permissions Setup

#### **Android Permissions** (already in AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### **iOS Permissions** (add to Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>VoyaGo needs location access to show your position on the map and provide directions.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>VoyaGo needs location access to show your position on the map and provide directions.</string>
```

### 5. Test Your Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Test Map Features**
   - Create a trip
   - Add itinerary items with addresses
   - Tap the map button (🗺️) in trip details
   - Grant location permissions when prompted
   - Verify map loads with markers

### 🚨 Troubleshooting

#### **Map Not Loading**
- Check API key is correctly set in `app_config.dart`
- Verify APIs are enabled in Google Cloud Console
- Check platform-specific API key configuration

#### **Geocoding Not Working**
- Ensure Geocoding API is enabled
- Check internet connectivity
- Verify API key has geocoding permissions

#### **Directions Not Showing**
- Ensure Directions API is enabled
- Check API key restrictions
- Verify internet connectivity

#### **Location Permission Issues**
- Check platform-specific permission declarations
- Grant permissions in device settings if needed
- Test location services are enabled on device

### 💡 Best Practices

1. **Security**: Always restrict your API keys to your app only
2. **Billing**: Monitor API usage in Google Cloud Console
3. **Testing**: Test on both Android and iOS devices
4. **Offline**: The app gracefully handles offline scenarios

### 🔗 Useful Links

- [Google Maps Platform](https://developers.google.com/maps)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)

---

**Once configured, VoyaGo will have full mapping and navigation capabilities! 🎉**