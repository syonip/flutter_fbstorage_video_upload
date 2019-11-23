import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_info.dart';

class ChewiePlayer extends StatefulWidget {
  final VideoInfo video;

  const ChewiePlayer({Key key, @required this.video}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChewiePlayerState();
}

class _ChewiePlayerState extends State<ChewiePlayer> {
  ChewieController chewieCtrl;
  VideoPlayerController videoPlayerCtrl;

  @override
  void initState() {
    super.initState();
    videoPlayerCtrl = VideoPlayerController.network(widget.video.videoUrl);
    chewieCtrl = ChewieController(
      videoPlayerController: videoPlayerCtrl,
      autoPlay: true,
      autoInitialize: true,
      aspectRatio: widget.video.aspectRatio,
      placeholder: Center(
        child: Image.network(widget.video.coverUrl),
      ),
    );
  }

  @override
  void dispose() {
    if (chewieCtrl != null) chewieCtrl.dispose();
    if (videoPlayerCtrl != null) videoPlayerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Chewie(
            controller: chewieCtrl,
          ),
          Container(
            padding: EdgeInsets.all(30.0),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
