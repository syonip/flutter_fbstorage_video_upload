# Flutter Video Sharing app

![final.gif](https://www.learningsomethingnew.com/flutter-video/final.gif)

An example app to demonstrate video sharing using Firebase and Publitio.

Read the full tutorial in my [blog](https://www.learningsomethingnew.com/how-to-make-a-cross-platform-video-sharing-app-with-flutter-and-firebase).

## Getting Started

You need to setup Firebase and Publitio credentials in order to run the sample:

### Firebase setup
Complete the setup process as described [here](https://firebase.google.com/docs/flutter/setup).

You should add two files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### Publitio setup
- Create a free account at [publit.io](https://publit.io?fpr=jonathan43).
- Create a file named `.env` in the root folder of the project, and add the key and secret:
```
PUBLITIO_KEY=abc123
PUBLITIO_SECRET=abcdefg1234567
```
- Create a file: `ios/Runner/Config.xcconfig`, and add the same:
```
PUBLITIO_KEY = abc123
PUBLITIO_SECRET = abcdefg1234567
```

### Run the project
Run the project as usual using `flutter run`