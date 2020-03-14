import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:transparent_image/transparent_image.dart';
import 'apis/encoding_provider.dart';
import 'apis/firebase_provider.dart';
import 'package:path/path.dart' as p;
import 'models/video_info.dart';
import 'widgets/player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Sharing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Video Sharing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<VideoInfo> _videos = <VideoInfo>[];
  bool _imagePickerActive = false;
  bool _processing = false;
  bool _canceled = false;
  double _progress = 0.0;
  int _videoDuration = 0;
  String _processPhase = "";

  @override
  void initState() {
    FirebaseProvider.listenToVideos((newVideos) {
      setState(() {
        _videos = newVideos;
      });
    });

    EncodingProvider.enableStatisticsCallback((int time,
        int size,
        double bitrate,
        double speed,
        int videoFrameNumber,
        double videoQuality,
        double videoFps) {
      if (_canceled) return;

      setState(() {
        _progress = time / _videoDuration;
      });
    });

    super.initState();
  }

  void onUploadProgress(event) {
    if (event.type == StorageTaskEventType.progress) {
      final double progress =
          event.snapshot.bytesTransferred / event.snapshot.totalByteCount;
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<String> _uploadFile(filePath) async {
    final file = new File(filePath);
    final basename = p.basename(filePath);

    final StorageReference ref = FirebaseStorage.instance.ref().child(basename);
    StorageUploadTask uploadTask = ref.putFile(file);
    uploadTask.events.listen(onUploadProgress);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String videoUrl = await taskSnapshot.ref.getDownloadURL();
    return videoUrl;
  }

  Future<void> _processVideo(File rawVideoFile) async {
    final rawVideoPath = rawVideoFile.path;
    final info = await EncodingProvider.getMediaInformation(rawVideoPath);

    setState(() {
      _processPhase = "Generating thumbnail";
      _videoDuration = info["duration"];
      _progress = 0.0;
    });

    final thumbFilePath =
        await EncodingProvider.getThumb(rawVideoPath, 100, 150);

    setState(() {
      _processPhase = "Uploading thumbnail to firebase storage";
      _progress = 0.0;
    });

    final thumbUrl = await _uploadFile(thumbFilePath);

    setState(() {
      _processPhase = "Encoding video";
      _progress = 0.0;
    });

    final encodedVideoPath = await EncodingProvider.encode(rawVideoPath);

    final aspectRatio = await EncodingProvider.getAspectRatio(encodedVideoPath);

    setState(() {
      _processPhase = "Uploading video to firebase storage";
      _progress = 0.0;
    });

    final videoUrl = await _uploadFile(encodedVideoPath);

    final videoInfo = VideoInfo(
      videoUrl: videoUrl,
      thumbUrl: thumbUrl,
      coverUrl: thumbUrl,
      aspectRatio: aspectRatio,
    );

    setState(() {
      _processPhase = "Saving video metadata to cloud firestore";
      _progress = 0.0;
    });

    await FirebaseProvider.saveVideo(videoInfo);

    setState(() {
      _processPhase = "";
      _progress = 0.0;
      _processing = false;
    });
  }

  void _takeVideo() async {
    if (_imagePickerActive) return;

    _imagePickerActive = true;
    final File videoFile =
        await ImagePicker.pickVideo(source: ImageSource.camera);
    _imagePickerActive = false;

    if (videoFile == null) return;

    setState(() {
      _processing = true;
    });

    try {
      await _processVideo(videoFile);
    } on PlatformException catch (e) {
      print('${e.code}: ${e.message}');
      //result = 'Platform Exception: ${e.code} ${e.details}';
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  _getListView() {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _videos.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Player(
                      video: _videos[index],
                    );
                  },
                ),
              );
            },
            child: Card(
              child: new Container(
                padding: new EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Center(child: CircularProgressIndicator()),
                        Center(
                          child: ClipRRect(
                            borderRadius: new BorderRadius.circular(8.0),
                            child: FadeInImage.memoryNetwork(
                              placeholder: kTransparentImage,
                              image: _videos[index].thumbUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Padding(padding: EdgeInsets.only(top: 20.0)),
                    // ListTile(
                    //   title: Text(_videos[index].videoUrl),
                    // ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _getProgressBar() {
    return Container(
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 30.0),
            child: Text(_processPhase),
          ),
          LinearProgressIndicator(
            value: _progress,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: _processing ? _getProgressBar() : _getListView()),
      floatingActionButton: FloatingActionButton(
          child: _processing
              ? CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Icon(Icons.add),
          onPressed: _takeVideo),
    );
  }
}
