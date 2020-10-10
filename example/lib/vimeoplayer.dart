library vimeoplayer;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'src/quality_links.dart';
import 'dart:async';
import 'src/fullscreen_player.dart';

class VimeoPlayer extends StatefulWidget {
  final String id;
  final bool autoPlay;
  final bool looping;
  int position;

  VimeoPlayer({
    @required this.id,
    this.autoPlay,
    this.looping,
    this.position,
    Key key,
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState(id, autoPlay, looping, position);
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  String _id;
  bool autoPlay = false;
  bool looping = false;
  bool _overlay = true;
  bool fullScreen = false;
  int position;

  _VimeoPlayerState(this._id, this.autoPlay, this.looping, this.position);

  VideoPlayerController _controller; //Custom controller
  Future<void> initFuture;

  QualityLinks _quality; // Quality Class
  Map _qualityValues;
  var  _qualityValue;
  bool _seek = false;

  double videoHeight;
  double videoWidth;
  double videoMargin;

  @override
  void initState() {
    _quality = QualityLinks(_id); //Create class
    //Инициализация контроллеров видео при получении данных из Vimeo
    _quality.getQualitiesSync().then((value) {
      _qualityValues = value;
      _qualityValue = value[value.lastKey()];
      _controller = VideoPlayerController.network(_qualityValue);
      _controller.setLooping(looping);
      if (autoPlay) _controller.play();
      initFuture = _controller.initialize();

      //Обновление состояние приложения и перерисовка
      setState(() {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitDown,
          DeviceOrientation.portraitUp
        ]);
      });
    });

    //На странице видео преимущество за портретной ориентацией
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    super.initState();
  }

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
                  //Управление шириной и высотой видео
                  double delta = MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.height *
                          _controller.value.aspectRatio;
                  if (MediaQuery.of(context).orientation ==
                          Orientation.portrait ||
                      delta < 0) {
                    videoHeight = MediaQuery.of(context).size.width /
                        _controller.value.aspectRatio;
                    videoWidth = MediaQuery.of(context).size.width;
                    videoMargin = 0;
                  } else {
                    videoHeight = MediaQuery.of(context).size.height - 36;
                    videoWidth = videoHeight * _controller.value.aspectRatio;
                    videoMargin =
                        (MediaQuery.of(context).size.width - videoWidth) / 2;
                  }

                  if (_seek && _controller.value.duration.inSeconds > 2) {
                    _controller.seekTo(Duration(seconds: position));
                    _seek = false;
                  }

                  //Отрисовка элементов плеера
                  return Stack(
                    children: <Widget>[
                      Container(
                        height: videoHeight,
                        width: videoWidth,
                        margin: EdgeInsets.only(left: videoMargin),
                        child: VideoPlayer(_controller),
                      ),
                      _videoOverlay(),
                    ],
                  );
                } else {
                  return Center(
                      heightFactor: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF22A3D2)),
                      ));
                }
              }),
          onTap: () {
            setState(() {
              _overlay = !_overlay;
            });
          },
        ),
        GestureDetector(
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 30,
              height: MediaQuery.of(context).size.width / 16 * 9 - 40,
              margin: EdgeInsets.fromLTRB(0, 0, MediaQuery.of(context).size.width / 2 + 30, 40),
              decoration: BoxDecoration(
                //color: Colors.red,
              ),
            ),
            onTap: () {
              setState(() {
                _overlay = !_overlay;
              });
            },
            onDoubleTap:(){
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds - 10));
              });
            }
        ), GestureDetector(
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 45,
              height: MediaQuery.of(context).size.width / 16 * 9 - 60,
              margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width / 2 + 45, 0, 0, 60),
              decoration: BoxDecoration(
                //color: Colors.red,
              ),
            ),
            onTap: () {
              setState(() {
                _overlay = !_overlay;
              });
            },
            onDoubleTap:(){
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + 10));
              });
            }
        ),
      ],
    ));
  }

  //================================ Quality ================================//
  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          final children = <Widget>[];
          _qualityValues.forEach((elem, value) => (children.add(new ListTile(
              title: new Text(" ${elem.toString()} fps"),
              onTap: () => {
                    //Обновление состояние приложения и перерисовка
                    setState(() {
                      _controller.pause();
                      _qualityValue = value;
                      _controller = VideoPlayerController.network(_qualityValue);
                      _controller.setLooping(true);
                      _seek = true;
                      initFuture = _controller.initialize();
                      _controller.play();
                    }),
                  }))));

          return Container(
            child: Wrap(
              children: children,
            ),
          );
        });
  }

  //================================ OVERLAY ================================//
  Widget _videoOverlay() {
    return _overlay
        ? Stack(
            children: <Widget>[
              GestureDetector(
                child: Center(
                  child: Container(
                    width: videoWidth,
                    height: videoHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          const Color(0x662F2C47),
                          const Color(0x662F2C47)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: IconButton(
                    padding: EdgeInsets.only(
                        top: videoHeight / 2 - 30,
                        bottom: videoHeight / 2 - 30),
                    icon: _controller.value.isPlaying
                        ? Icon(Icons.pause, size: 60.0)
                        : Icon(Icons.play_arrow, size: 60.0),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    }),
              ),
              Container(
                margin: EdgeInsets.only(
                    top: videoHeight - 70, left: videoWidth + videoMargin - 50),
                child: IconButton(
                    alignment: AlignmentDirectional.center,
                    icon: Icon(Icons.fullscreen, size: 30.0),
                    onPressed: () async {
                      setState(() {
                        _controller.pause();
                      });
                      position = await Navigator.push(context, PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (BuildContext context, _, __) => FullscreenPlayer(
                            id: _id, autoPlay: true, controller: _controller, position: _controller.value.position.inSeconds,
                              initFuture: initFuture, qualityValue: _qualityValue),
                          transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
                            print(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            );
                          }
                      ));
                      setState(() {
                        _controller.play();
                        _seek = true;
                      });
                    }),
              ),
              Container(
                margin: EdgeInsets.only(left: videoWidth + videoMargin - 48),
                child: IconButton(
                    icon: Icon(Icons.settings, size: 26.0),
                    onPressed: () {
                      position = _controller.value.position.inSeconds;
                      _seek = true;
                      _settingModalBottomSheet(context);
                      setState(() {});
                    }),
              ),
              Container(
                //===== Ползунок =====//
                margin: EdgeInsets.only(
                    top: videoHeight - 26, left: videoMargin), //CHECK IT
                child: _videoOverlaySlider(),
              )
            ],
          )
        : Center(
            child: Container(
              height: 5,
              width: videoWidth,
              margin: EdgeInsets.only(top: videoHeight - 5),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Color(0xFF22A3D2),
                  backgroundColor: Color(0x5515162B),
                  bufferedColor: Color(0x5583D8F7),
                ),
                padding: EdgeInsets.only(top: 2),
              ),
            ),
          );
  }

  //=================== ПОЛЗУНОК ===================//
  Widget _videoOverlaySlider() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.hasError && value.initialized) {
          return Row(
            children: <Widget>[
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(value.position.inMinutes.toString() +
                    ':' +
                    (value.position.inSeconds - value.position.inMinutes * 60)
                        .toString()),
              ),
              Container(
                height: 20,
                width: videoWidth - 92,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Color(0xFF22A3D2),
                    backgroundColor: Color(0x5515162B),
                    bufferedColor: Color(0x5583D8F7),
                  ),
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                ),
              ),
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(value.duration.inMinutes.toString() +
                    ':' +
                    (value.duration.inSeconds - value.duration.inMinutes * 60)
                        .toString()),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
