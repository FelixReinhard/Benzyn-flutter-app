# benzyn

A Flutter android app for counting how much petrol one useses.

## Features
- Simple entry for current mileage and price
- Calculates average fuel consumption from entries
- Simple visualization the data
- Current gas prices near the user using the [Tankerkönig Api](https://creativecommons.tankerkoenig.de/) (only in Germany) 
## Installing

1. Clone the repo

```
git clone https://github.com/FelixReinhard/Benzyn-flutter-app.git
``` 

2. Make sure you have the [flutter sdk](https://docs.flutter.dev/get-started/install) correctly installed for android apps. You can test this by running 
```
flutter doctor
```
For more information check [this](https://docs.flutter.dev/get-started/install/windows#android-setup)

3. Now use flutter to compile the app. For example for android (Note that this app is made for Android only, other versions may not work) 
```
flutter build apk --release
```

4. Find the apk in **build/app/outputs/flutter-apk/** and use it however you like.
