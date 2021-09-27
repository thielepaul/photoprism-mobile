# PhotoPrism Flutter App for iOS and Android (community maintained)

![alt text](assets/iphone_photo.png "iPhone App Photos View")

## :warning: App is Currently Incompatible with Backend :warning:

This app is currently incompatible with the latest version of the PhotoPrism backend (to get the latest compatible version, use the [legacy links below](#installation)).  
The status of the pull request with the necessary backend api changes can be seen [here](https://github.com/photoprism/photoprism/pull/995).  
If you want to use the latest version of the app until this is merged, you can either build the photoprism backend with the patches from [source](https://github.com/thielepaul/photoprism/tree/db-api) or use the docker image `thielepaul/photoprism:db-api`.

Get the latest version of the mobile app including the backend incompatible changes:
* [APK for Android](https://github.com/photoprism/photoprism-mobile/releases/download/latest-db-api/photoprism.apk)
* [Testflight for iOS](https://testflight.apple.com/join/3NL12xyh)

## Features
- View your photoprism photos and albums
- Photos and albums will be cached so they are available even without internet connection
- Create, rename and delete albums
- Add photos to albums
- Remove photos from album
- Archive photos
- Manual photo upload
- Automatic photo upload (experimental)
- Share photos with other apps
- Use PhotoPrism instances behind HTTP Basic Authentication
- Support for password protected photoprism instances

## Planned features
- Archived photos view
- Improve cache management
- Improve auto uploader
- View meta data

## How to contribute
If you like the app and the project, please give us a star on GitHub. This keeps us motivated. We are also happy about every bug and ideas for improving the app.

If you'd like to make an enhancement to the application, please see [the contributing docs](CONTRIBUTING.md) for information on how to build and run the application.

## Installation
:warning: This is the legacy version of the app with many known bugs, please do not open issues regarding this version of the app. :warning:

### Android
- The latest .apk file can be downloaded [here](https://github.com/photoprism/photoprism-mobile/releases/download/latest/photoprism.apk).

![alt text](assets/qrcode_android_apk.png "Android APK QR Code image")

### iOS
- On iOS you can use [testflight to install app](https://testflight.apple.com/join/3NL12xyh).

![alt text](assets/qrcode_ios_testflight.png "TestFlight QR Code image")

## Trademarks ##

PhotoPrism® is a registered trademark of Michael Mayer. You may use it as required to describe 
our software, run your server, for educational purposes, but not for offering commercial 
goods, products, or services without prior written permission. 

Feel free to reach out if you have questions:  
https://photoprism.app/contact
