import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_video_sharing/video_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_publitio/flutter_publitio.dart';
import 'package:flutter/services.dart';
import 'package:transparent_image/transparent_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Video Sharing App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<VideoInfo> _videos = <VideoInfo>[];

  bool _imagePickerActive = false;
  bool _uploading = false;

  @override
  void initState() {
    configurePublitio();
    super.initState();
  }

  static configurePublitio() async {
    await DotEnv().load('.env');
    await FlutterPublitio.configure(
        DotEnv().env['PUBLITIO_KEY'], DotEnv().env['PUBLITIO_SECRET']);
  }

  Future<dynamic> _uploadVideo(videoFile) async {
    print('starting upload');
    final uploadOptions = {
      "privacy": "1",
      "option_download": "1",
      "option_transform": "1"
    };
    final response =
        await FlutterPublitio.uploadFile(videoFile.path, uploadOptions);
    return response;
  }

  void _takeVideo() async {
    if (_imagePickerActive) return;

    _imagePickerActive = true;
    final File videoFile =
        await ImagePicker.pickVideo(source: ImageSource.camera);
    _imagePickerActive = false;

    if (videoFile == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final response = await _uploadVideo(videoFile);
      setState(() {
        _videos.add(VideoInfo(
            videoUrl: response["url_preview"],
            thumbUrl: response["url_thumbnail"]));
      });
    } on PlatformException catch (e) {
      print('${e.code}: ${e.message}');
      //result = 'Platform Exception: ${e.code} ${e.details}';
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _videos.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
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
                        Padding(padding: EdgeInsets.only(top: 20.0)),
                        ListTile(
                          title: Text(_videos[index].videoUrl),
                        ),
                      ],
                    ),
                  ),
                );
              })),
      floatingActionButton: FloatingActionButton(
          child: _uploading
              ? CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Icon(Icons.add),
          onPressed: _takeVideo),
    );
  }
}
