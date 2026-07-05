# Fix: Complete Build Error Guide - Google Services + Kotlin Compilation

## Current Errors

You're facing **two build failures**:

### Error 1: Google Services JSON Mismatch
```
Execution failed for task ':app:processReleaseGoogleServices'.
> No matching client found for package name 'com.shatechx.ams' in 
  D:\Antony\projects\Flutter app\AMS Project\ams\android\app\google-services.json
```

### Error 2: Kotlin Compilation Cache Error
```
Execution failed for task ':firebase_storage:compileReleaseKotlin'.
> java.lang.Exception: Could not close incremental caches in 
  build\firebase_storage\kotlin\compileReleaseKotlin\cacheable\caches-jvm\jvm\kotlin
```

---

## PART 1: Fix Google Services JSON Error

### Understanding the Problem

Your Android app's package name is `com.shatechx.ams`, but your `google-services.json` file contains configuration for a **different package name**. This happens when:
- The app was registered with a different package name in Firebase Console
- The `google-services.json` is from a different project
- The package name was changed after Firebase setup

---

### Solution 1: Update Application ID in build.gradle.kts (Quick Fix)

**Step 1: Check your current package name**

Open `android/app/build.gradle.kts` and look for:
```kotlin
android {
    namespace = "com.shatechx.ams"  // This is your app's package name
    // OR
    defaultConfig {
        applicationId = "com.shatechx.ams"  // This is the actual app ID
    }
}
```

**Step 2: Check google-services.json**

Open `android/app/google-services.json` and look for the `package_name` field:
```json
{
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.your.firebase.project"  // This should match
        }
      }
    }
  ]
}
```

**Step 3: Make them match**

You have **two options**:

#### Option A: Change build.gradle.kts to match google-services.json
```kotlin
android {
    namespace = "com.your.firebase.project"  // Use the package name from google-services.json
    defaultConfig {
        applicationId = "com.your.firebase.project"
    }
}
```

#### Option B: Download correct google-services.json (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Select your Android app (or create one if it doesn't exist)
6. **Register app** with package name: `com.shatechx.ams`
7. Download `google-services.json`
8. Replace the existing file in `android/app/google-services.json`

---

### Solution 2: Register New Android App in Firebase (Recommended)

**Step 1: Go to Firebase Console**
- Visit: https://console.firebase.google.com/
- Select your project: **AMS Project**

**Step 2: Add Android App**
- Click **Add app** (Android icon)
- **Android package name**: Enter `com.shatechx.ams`
- (Optional) Enter app nickname: `AMS App`
- (Optional) Enter SHA-1 certificate (for authentication)
- Click **Register app**

**Step 3: Download Configuration File**
- Click **Download google-services.json**
- Save the file to: `D:\Antony\projects\Flutter app\AMS Project\ams\android\app\google-services.json`
- **Replace the existing file**

**Step 4: Verify the Configuration**

Open the downloaded `google-services.json` and verify it contains:
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abc123",
        "android_client_info": {
          "package_name": "com.shatechx.ams"  // MUST match your app
        }
      },
      "oauth_client": [...],
      "api_key": [...],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [...]
        }
      }
    }
  ]
}
```

**Step 5: Enable Firebase Services**

In Firebase Console, enable the services you're using:
- **Firestore Database**: Go to Build > Firestore Database > Create Database
- **Storage**: Go to Build > Storage > Get Started
- **Authentication**: Go to Build > Authentication > Get Started
- **Crashlytics**: Go to Build > Crashlytics > Get Started

---

### Solution 3: Check AndroidManifest.xml

Verify your app's package name in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.shatechx.ams">  <!-- This should match google-services.json -->
    
    <application
        android:label="AMS"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
```

---

### Solution 4: Update build.gradle.kts (if needed)

Ensure your `android/app/build.gradle.kts` has the correct configuration:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // This must be at the bottom
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.shatechx.ams"  // Must match google-services.json
    compileSdk = 34

    defaultConfig {
        applicationId = "com.shatechx.ams"  // Must match google-services.json
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.google.firebase:firebase-storage:20.3.0")
    implementation("com.google.firebase:firebase-firestore:24.9.1")
    implementation("com.google.firebase:firebase-auth:22.3.0")
    // ... other dependencies
}

// Apply Google Services plugin at the BOTTOM
apply(plugin = "com.google.gms.google-services")
```

---

## PART 2: Fix Kotlin Compilation Cache Error

After fixing the Google Services error, you may still encounter the Kotlin cache error. Here's how to fix it:

### Quick Fix (Apply After Fixing Google Services)

```bash
# Navigate to project directory
cd "D:\Antony\projects\Flutter app\AMS Project\ams"

# Stop Gradle daemons
cd android
./gradlew --stop
cd ..

# Clean everything
flutter clean

# Manually remove build directories (Windows)
# Command Prompt:
rmdir /s /q build
rmdir /s /q android\.gradle
rmdir /s /q android\app\build

# PowerShell:
# Remove-Item -Recurse -Force build, android\.gradle, android\app\build

# Get dependencies
flutter pub get

# Try building again
flutter build apk --release
```

---

### Permanent Fix: Modify gradle.properties

Create or edit `android/gradle.properties` and add:

```properties
# Disable Kotlin incremental compilation to prevent cache locking
kotlin.incremental=false

# Disable Gradle build cache
org.gradle.caching=false

# Disable parallel builds (can cause file locking)
org.gradle.parallel=false

# Increase heap size
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8

# Use in-process compilation
kotlin.compiler.execution.strategy=in-process

# Disable configuration cache
org.gradle.configuration-cache=false
```

---

## COMPLETE FIX STEPS (Do in Order)

### Step 1: Fix Google Services Configuration

**Option A: Download new google-services.json (Recommended)**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Go to Project Settings > Your apps > Android
4. If app doesn't exist, click "Add app" and register with package name: `com.shatechx.ams`
5. Download `google-services.json`
6. Replace `android/app/google-services.json` with the downloaded file

**Option B: Change package name**
1. Open `android/app/build.gradle.kts`
2. Change `namespace` and `applicationId` to match your Firebase project's package name
3. Also update `android/app/src/main/AndroidManifest.xml`

---

### Step 2: Clean Build Cache

```bash
# Navigate to project
cd "D:\Antony\projects\Flutter app\AMS Project\ams"

# Stop Gradle daemons
cd android
./gradlew --stop
cd ..

# Clean Flutter build
flutter clean

# Remove build directories manually
# Windows Command Prompt:
rmdir /s /q build
rmdir /s /q android\.gradle
rmdir /s /q android\app\build

# PowerShell:
# Remove-Item -Recurse -Force build, android\.gradle, android\app\build

# Get dependencies
flutter pub get
```

---

### Step 3: Configure gradle.properties

Create/edit `android/gradle.properties` and add:

```properties
# Disable problematic caching
kotlin.incremental=false
org.gradle.caching=false
org.gradle.parallel=false
kotlin.compiler.execution.strategy=in-process
org.gradle.configuration-cache=false

# Increase memory
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
```

---

### Step 4: Update Firebase Dependencies

Check `pubspec.yaml` and update Firebase packages:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_storage: ^11.5.5
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.16.0
  # ... other dependencies
```

Then run:
```bash
flutter pub upgrade
```

---

### Step 5: Build as Administrator

**Important:** Run Command Prompt or PowerShell as Administrator

1. Press `Win + X`
2. Select "Windows Terminal (Admin)" or "Command Prompt (Admin)"
3. Navigate to project:
   ```bash
   cd "D:\Antony\projects\Flutter app\AMS Project\ams"
   ```
4. Build:
   ```bash
   flutter build apk --release
   ```

---

### Step 6: If Still Failing - Use Stacktrace

```bash
# Navigate to android directory
cd android

# Build with detailed error info
./gradlew assembleRelease --stacktrace

# Or with more details
./gradlew assembleRelease --info
```

---

## Verification Steps

After applying fixes, verify:

### 1. Check google-services.json
```bash
# Open the file and verify:
# - "package_name" field matches "com.shatechx.ams"
# - project_id matches your Firebase project
# - storage_bucket is configured
```

### 2. Check build.gradle.kts
```bash
# Verify:
# - namespace = "com.shatechx.ams"
# - applicationId = "com.shatechx.ams"
# - com.google.gms.google-services plugin is applied
```

### 3. Check AndroidManifest.xml
```bash
# Verify package="com.shatechx.ams" matches
```

### 4. Test Firebase Connection

Create a test file `test_firebase.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('Firebase initialized successfully!');
}
```

Run:
```bash
flutter run test_firebase.dart
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong Package Name
```json
// google-services.json has:
"package_name": "com.oldproject.app"

// But app has:
applicationId = "com.shatechx.ams"
```

**Fix:** Make them match!

### ❌ Mistake 2: google-services.json in Wrong Location
```
❌ Wrong: android/google-services.json
✓ Correct: android/app/google-services.json
```

### ❌ Mistake 3: Plugin Not Applied
```kotlin
// Missing this at the BOTTOM of build.gradle.kts:
apply(plugin = "com.google.gms.google-services")
```

### ❌ Mistake 4: Not Cleaning After Changes
Always run `flutter clean` after changing configuration files.

---

## Automated Fix Script

Create `fix_all_build_issues.bat` in your project root:

```batch
@echo off
echo ==========================================
echo Fixing Build Issues...
echo ==========================================

echo.
echo Step 1: Stopping Gradle daemons...
cd android
call gradlew --stop
cd ..

echo.
echo Step 2: Cleaning build...
flutter clean

echo.
echo Step 3: Removing cache directories...
rmdir /s /q build
rmdir /s /q android\.gradle
rmdir /s /q android\app\build

echo.
echo Step 4: Getting dependencies...
flutter pub get

echo.
echo Step 5: Checking google-services.json...
if not exist "android\app\google-services.json" (
    echo ERROR: google-services.json not found!
    echo Please download it from Firebase Console.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Fix complete! Now run:
echo flutter build apk --release
echo ==========================================
pause
```

Run it:
```bash
fix_all_build_issues.bat
```

---

## Still Having Issues?

### Check Firebase Console Setup

1. **Verify Android app is registered:**
   - Firebase Console > Project Settings > Your apps
   - Should show Android app with package: `com.shatechx.ams`

2. **Verify SHA-1 certificate** (optional but recommended):
   ```bash
   # Get SHA-1 from debug keystore
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Add this SHA-1 to Firebase Console > Project Settings > Your app > SHA certificate fingerprints

3. **Enable required Firebase services:**
   - Firestore Database
   - Storage
   - Authentication (if used)

### Check Network Connection

Firebase initialization requires internet:
```bash
# Test internet connection
ping firebase.google.com
```

### Check Flutter Firebase Setup

```bash
# Verify FlutterFire CLI is installed
dart pub global activate flutterfire_cli

# Configure Firebase (if needed)
flutterfire configure
```

---

## Summary

**Primary Issue:** Package name mismatch between app and google-services.json

**Solution:**
1. Download correct `google-services.json` from Firebase Console for package `com.shatechx.ams`
2. Clean build cache
3. Configure gradle.properties to disable problematic caching
4. Build as Administrator

**Commands to run:**
```bash
# 1. Download google-services.json from Firebase Console first!

# 2. Clean and rebuild
flutter clean
flutter pub get

# 3. Build as Administrator
flutter build apk --release
```

---

**Last Updated:** Complete guide for Firebase + Kotlin compilation errors on Windows