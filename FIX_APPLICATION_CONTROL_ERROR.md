# Fix: Application Control Policy Blocking gen_snapshot.EXE

## Problem
When building a Flutter app for Android release (AOT compilation), Windows Application Control (Smart App Control or Windows Defender Application Control) blocks the `gen_snapshot.EXE` file, causing the build to fail.

**Error Message:**
```
Target android_aot_release_android-x64 failed: ProcessException: 
An Application Control policy has blocked this file 
(at ../../runtime/bin/process_win.cc:577)
```

## Solutions (Try in Order)

### Solution 1: Whitelist Flutter Directory in Windows Security (Recommended)

1. **Open Windows Security:**
   - Press `Win + I` to open Settings
   - Go to **Privacy & security** > **Windows Security**
   - Click **Open Windows Security**

2. **Navigate to App & Browser Control:**
   - Click **App & browser control**
   - Click **Reputation-based protection settings**

3. **Add Flutter to Exclusions:**
   - Scroll down to **Exclusions**
   - Click **Add or remove exclusions**
   - Click **Add an exclusion** > **Folder**
   - Add your Flutter installation folder (e.g., `C:\flutter`)
   - Also add your project folder if needed

4. **Retry the build:**
   ```bash
   flutter build apk --release
   ```

---

### Solution 2: Disable Smart App Control Temporarily

1. **Open Windows Security:**
   - Press `Win + I` > **Privacy & security** > **Windows Security**

2. **Disable Smart App Control:**
   - Go to **App & browser control**
   - Scroll to **Smart App Control**
   - Click **Settings** and turn it **Off**

3. **Retry the build:**
   ```bash
   flutter build apk --release
   ```

4. **Re-enable after build completes** (recommended for security)

---

### Solution 3: Run Command Prompt as Administrator

1. **Open Command Prompt as Admin:**
   - Press `Win + X`
   - Select **Windows Terminal (Admin)** or **Command Prompt (Admin)**

2. **Navigate to your Flutter project:**
   ```bash
   cd "D:\Antony\projects\Flutter app\AMS Project\ams"
   ```

3. **Run the build command:**
   ```bash
   flutter build apk --release
   ```

---

### Solution 4: Add Exclusion via PowerShell (Advanced)

Run PowerShell as Administrator and execute:

```powershell
# Add Flutter directory to Windows Defender exclusions
Add-MpPreference -ExclusionPath "C:\flutter"

# Add your project directory (optional)
Add-MpPreference -ExclusionPath "D:\Antony\projects\Flutter app\AMS Project\ams"

# Verify exclusions were added
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
```

---

### Solution 5: Check and Configure Antivirus Software

If you have third-party antivirus (e.g., Norton, McAfee, Avast):

1. **Open your antivirus software**
2. **Find the exclusion/whitelist settings**
3. **Add exclusions for:**
   - `C:\flutter` folder
   - `C:\flutter\bin\cache\artifacts\engine\` folder
   - Your project folder: `D:\Antony\projects\Flutter app\AMS Project\ams`

4. **Retry the build**

---

### Solution 6: Reinstall Flutter SDK

If the above solutions don't work, the executable might be corrupted:

1. **Backup your Flutter projects** (they're safe, but just in case)

2. **Delete Flutter folder:**
   ```bash
   # Make sure Flutter is not running
   # Delete C:\flutter folder
   ```

3. **Re-download Flutter:**
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Extract to `C:\flutter`

4. **Update PATH** (if needed)

5. **Verify installation:**
   ```bash
   flutter doctor
   ```

6. **Retry the build:**
   ```bash
   flutter build apk --release
   ```

---

### Solution 7: Use JIT Build for Development (Temporary Workaround)

If you only need to test and don't need a release build:

```bash
# Build a debug APK (uses JIT compilation, not AOT)
flutter build apk --debug

# Or build for development
flutter build apk --profile
```

**Note:** Debug builds are slower and larger, but they don't require AOT compilation.

---

### Solution 8: Clean and Rebuild

Sometimes cleaning the build cache helps:

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Try building again
flutter build apk --release
```

---

## Recommended Approach

**For one-time build:**
1. Use **Solution 3** (Run as Administrator) - Quick and easy
2. Or use **Solution 2** (Disable Smart App Control temporarily)

**For frequent development:**
1. Use **Solution 1** (Whitelist Flutter directory) - Permanent fix
2. Keep Smart App Control enabled for security

**If nothing works:**
1. Try **Solution 6** (Reinstall Flutter)

---

## Prevention

To avoid this issue in the future:

1. **Whitelist Flutter directories** during initial setup
2. **Keep Flutter updated** to the latest stable version:
   ```bash
   flutter upgrade
   ```
3. **Ensure your Windows is updated** (some Windows updates improve Application Control policies)

---

## Additional Troubleshooting

If you still face issues:

1. **Check Flutter installation:**
   ```bash
   flutter doctor -v
   ```

2. **Verify the blocked file exists:**
   ```bash
   dir "C:\flutter\bin\cache\artifacts\engine\android-x64-release\windows-x64\gen_snapshot.EXE"
   ```

3. **Check Windows Event Viewer for detailed error logs:**
   - Press `Win + R`, type `eventvwr.msc`
   - Go to **Windows Logs** > **Security**
   - Look for Application Control events

4. **Update Flutter to latest version:**
   ```bash
   flutter upgrade
   flutter doctor
   ```

---

## Quick Reference Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build release App Bundle (for Google Play)
flutter build appbundle --release

# Check Flutter installation
flutter doctor -v

# Upgrade Flutter
flutter upgrade
```

---

## Still Having Issues?

If none of these solutions work:

1. **Check if your organization has group policies** that block executables
   - Contact your IT administrator if this is a work computer
   
2. **Try building on a different machine** to isolate the issue

3. **Report the issue** to Flutter team:
   - https://github.com/flutter/flutter/issues

4. **Consider using WSL2** (Windows Subsystem for Linux) for Flutter development
   - This bypasses Windows Application Control entirely

---

**Last Updated:** Based on Flutter stable channel, Windows 11