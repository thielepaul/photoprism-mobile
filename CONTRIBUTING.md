## Overview

This application was built using Flutter.

### iOS

Setup instructions:
- Install Cocoapod, Flutter, and XCode
- checkout repository
- `cd` to repo and execute: `flutter pub get && flutter pub run build_runner build && cd ios && pod install`
- open {repo}/ios/Runner.xcodeproj in XCode
- click the build and run button in XCode
- allow certificate on iPhone
- go to Runner > Edit Scheme in XCode and set the Build Configuration to Release instead of Debug

You can now build and run the app again.

### Android (with VSCode and Docker)
Setup instructions:
- Install Docker, VSCode and the VSCode-Remote-Containers-Extension
- checkout repository
- open it in VSCode and select "Reopen in Container"
- install dependencies with "Pub: Get Packages"
- use "flutter: flutter pub run build_runner build" task to autogenerate files (see https://moor.simonbinder.eu/docs/getting-started/#generating-the-code)
- develop and build the app as you like (you can use the checked-in VSCode tasks)
- to debug connect to your phone with adb wireless (adb pair & adb connect)

see also:  
https://code.visualstudio.com/docs/remote/containers-tutorial  
https://developer.android.com/studio/command-line/adb
