# Appium Setup via Nix Configuration

This document describes how Appium testing tools are configured in this Nix setup.

## What's Installed

### NPM Global Packages (via home/packages.nix)
- **appium-doctor** - Diagnose and fix Node, iOS, and Android configuration issues
- **appium** - The Appium server for mobile app automation
- **webdriverio** - WebDriver client library for testing

### Homebrew GUI Apps (via darwin/homebrew.nix)
- **appium-desktop** - UI for the Appium server
- **appium-inspector** - Tool to inspect app elements and interact with them

### Environment Variables (via home/appium.nix)
- `APPIUM_HOME=$HOME/.appium` - Appium configuration directory
- `APPIUM_LOG_LEVEL=info` - Log level for Appium server

## Pre-configured Environment

The shell already includes necessary variables for Appium to work with mobile testing:
- `JAVA_HOME` - Points to Zulu 17 JDK (required for Android)
- `ANDROID_HOME` - Points to Android SDK location
- `ANDROID_NDK_HOME` - Points to latest Android NDK
- `NODEJS` - Node.js v22 from nixpkgs
- `fnm` - Fast Node Manager for version switching

## Setup Steps

1. **Apply the Nix configuration:**
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

2. **Verify Appium Doctor:**
   ```bash
   appium-doctor
   ```
   This will check all dependencies. Fix any issues it reports.

3. **Start Appium Server:**
   ```bash
   appium
   ```

4. **Use Appium Inspector:**
   - Open Appium Inspector from your Applications
   - Connect to your running Appium server
   - Point it at your app (iOS/Android)

## Project-Specific Usage

### For iOS Testing
Requires Xcode and CocoaPods (already configured). Configure your test with:
```js
{
  "platformName": "iOS",
  "appium:deviceName": "iPhone 15",
  "appium:platformVersion": "17.0",
  "appium:app": "/path/to/app.zip"
}
```

### For Android Testing
Requires Android SDK (path in ANDROID_HOME). Configure your test with:
```js
{
  "app": "/path/to/app.apk",
  "platformName": "Android",
  "deviceName": "Pixel_XL",
  "automationName": "UiAutomator2"
}
```

## Troubleshooting

If appium-doctor reports missing dependencies:
1. Check that `JAVA_HOME` is properly set: `echo $JAVA_HOME`
2. Verify Android SDK exists: `ls $ANDROID_HOME`
3. Ensure Xcode is installed for iOS: `xcode-select --install`
4. Run `appium-doctor --fix` to auto-fix common issues

## Additional Resources

- [Appium Documentation](https://appium.io/docs/)
- [Appium Desktop Guide](https://github.com/appium/appium-desktop)
- [WebdriverIO Configuration](https://webdriver.io/docs/configuration)
