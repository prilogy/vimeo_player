library vimeoplayer;

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'src/quality_links.dart';
import 'dart:async';

//Video player class
class VimeoPlayer extends StatefulWidget {
  final String id;
  final bool autoPlay;
  final bool looping;
  final int position;
  final bool allowFullScreen;

  VimeoPlayer({
    @required this.id,
    this.autoPlay,
    this.looping,
    this.position,
    @required this.allowFullScreen,
    Key key,
  })  : assert(id != null && allowFullScreen != null),
        super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState(id, autoPlay, looping, position, allowFullScreen);
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  String _id;
  bool autoPlay = false;
  bool looping = false;
  bool _overlay = true;
  bool fullScreen = false;
  bool allowFullScreen = false;
  int position;

  _VimeoPlayerState(this._id, this.autoPlay, this.looping, this.position, this.allowFullScreen);

  //Custom controller
  VideoPlayerController _controller;
  ChewieController _chewieController;

  Future<void> initFuture;

  //Quality Class
  QualityLinks _quality;
  var _qualityValue;

  //Variable rewind
  bool _seek = false;

  //Video variables
  double videoHeight;
  double videoWidth;
  double videoMargin;

  //Variables for double-tap zones
  double doubleTapRMargin = 36;
  double doubleTapRWidth = 400;
  double doubleTapRHeight = 160;
  double doubleTapLMargin = 10;
  double doubleTapLWidth = 400;
  double doubleTapLHeight = 160;

  @override
  void initState() {
    fullScreen = allowFullScreen;

    //Create class
    _quality = QualityLinks(_id);

    //Initializing video controllers when receiving data from Vimeo
    _quality.getQualitiesSync().then((value) {
      _qualityValue = value[value.lastKey()];
      _controller = VideoPlayerController.network(_qualityValue);
      _controller.setLooping(looping);
      if (autoPlay) _controller.play();
      initFuture = _controller.initialize().then((value) {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          // Prepare the video to be played and display the first frame
          autoInitialize: true,
          allowFullScreen: fullScreen,
          deviceOrientationsOnEnterFullScreen: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
          systemOverlaysOnEnterFullScreen: [SystemUiOverlay.bottom],
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],
          systemOverlaysAfterFullScreen: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          aspectRatio: _controller.value.aspectRatio,
          looping: looping,
          autoPlay: autoPlay,
          // Errors can occur for example when trying to play a video
          // from a non-existent URL
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        );
      });

      //Update orientation and rebuilding page
      setState(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
      });
    });

    //The video page takes precedence over portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    super.initState();
  }

  //Build player element
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        GestureDetector(
          child: FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  //Controlling width and height
                  double delta = MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.height * _controller.value.aspectRatio;

                  //Calculating the width and height of the video player relative to the sides
                  // and orientation of the device
                  if (MediaQuery.of(context).orientation == Orientation.portrait || delta < 0) {
                    videoHeight = MediaQuery.of(context).size.width / _controller.value.aspectRatio;
                    videoWidth = MediaQuery.of(context).size.width;
                    videoMargin = 0;
                  } else {
                    videoHeight = MediaQuery.of(context).size.height;
                    videoWidth = videoHeight * _controller.value.aspectRatio;
                    videoMargin = (MediaQuery.of(context).size.width - videoWidth) / 2;
                  }

                  //We start from the same place where we left off when changing quality
                  if (_seek && _controller.value.duration.inSeconds > 2) {
                    _controller.seekTo(Duration(seconds: position));
                    _seek = false;
                  }

                  return Container(
                    margin: EdgeInsets.only(left: videoMargin),
                    child: Chewie(controller: _chewieController),
                  );
                } else {
                  return Center(
                      heightFactor: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22A3D2)),
                      ));
                }
              }),
          onTap: () {
            //Editing the size of the double tap area when showing the overlay.
            // Made to open the "Full Screen" and "Quality" buttons
            setState(() {
              _overlay = !_overlay;
              if (_overlay) {
                doubleTapRHeight = videoHeight - 36;
                doubleTapLHeight = videoHeight - 10;
                doubleTapRMargin = 36;
                doubleTapLMargin = 10;
              } else if (!_overlay) {
                doubleTapRHeight = videoHeight + 36;
                doubleTapLHeight = videoHeight + 16;
                doubleTapRMargin = 0;
                doubleTapLMargin = 0;
              }
            });
          },
        ),
        GestureDetector(
            //======= Rewind =======//
            child: Container(
              width: doubleTapLWidth / 2 - 30,
              height: doubleTapLHeight - 46,
              margin: EdgeInsets.fromLTRB(0, 10, doubleTapLWidth / 2 + 30, doubleTapLMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),

            // Resize double tap blocks. Needed to open the
            // "Full Screen" and "Quality" buttons when overlay is enabled
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds - 10));
              });
            }),
        GestureDetector(
            child: Container(
              //======= Flash forward =======//
              width: doubleTapRWidth / 2 - 45,
              height: doubleTapRHeight - 60,
              margin: EdgeInsets.fromLTRB(doubleTapRWidth / 2 + 45, doubleTapRMargin, 0, doubleTapRMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),
            // Resize double tap blocks. Needed to open the
            // "Full Screen" and "Quality" buttons when overlay is enabled
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + 10));
              });
            }),
      ],
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    initFuture = null;
    super.dispose();
  }
}
