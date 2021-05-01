# vimeoplayer

**Since ^0.2.0 plugin supports null-safety and flutter 2.
For previous versions use version ^0.1.8**

A new Flutter package for playing any videos from Vimeo by ID. 

Functions:
* Download video from link
* Quality change
* Responsive full screen
* Pause and play
* Rewind
* Double tap rewind

## Getting Started

## Installation
First, add vimeoplayer as a dependency in your `pubspec.yaml` file.

## iOS
Warning: The video player is not functional on iOS simulators. An iOS device must be used during development/testing.

Add the following entry to your `Info.plist` file, located in `<project root>/ios/Runner/Info.plist`:

```<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
This entry allows your app to access video files by URL.

## Android
Ensure the following permission is present in your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

```<uses-permission android:name="android.permission.INTERNET"/>```

The Flutter project template adds it, so it may already be there.

## Supported Formats
On iOS, the backing player is AVPlayer. The supported formats vary depending on the version of iOS, AVURLAsset class has audiovisualTypes that you can query for supported av formats.
On Android, the backing player is ExoPlayer, please refer here for list of supported formats.
On Web, available formats depend on your users' browsers (vendor and version). Check package:video_player_web for more specific information.

## Example

```import 'package:flutter/material.dart';
import 'package:vimeoplayer/vimeoplayer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      //primarySwatch: Colors.red,
      theme: ThemeData.dark().copyWith(
        accentColor: Color(0xFF22A3D2),
      ),
      home: VideoScreen(),
    );
  }
}

class VideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Color(0xFF15162B), //FF15162B // 0xFFF2F2F2
        appBar: MediaQuery.of(context).orientation == Orientation.portrait
            ? AppBar(
                leading: BackButton(color: Colors.white),
                title: Text('Название видео'),
                backgroundColor: Color(0xAA15162B),
              )
            : PreferredSize(
                child: Container(
                  color: Colors.transparent,
                ),
                preferredSize: Size(0.0, 0.0),
              ),
        body: ListView(children: <Widget>[
          VimeoPlayer(id: '395212534', autoPlay: true),
        ]));
  }
}
```
