import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_publitio/flutter_publitio.dart';

import '../video_info.dart';

class PublitioDAL {
  static configurePublitio() async {
    await DotEnv().load('.env');
    await FlutterPublitio.configure(
        DotEnv().env['PUBLITIO_KEY'], DotEnv().env['PUBLITIO_SECRET']);
  }
  
  static uploadVideo(videoFile) async {
    print('starting upload');
    final uploadOptions = {
      "privacy": "1",
      "option_download": "1",
      "option_transform": "1"
    };
    final response =
        await FlutterPublitio.uploadFile(videoFile.path, uploadOptions);

    final width = response["width"];
    final height = response["height"];
    final double aspectRatio = width / height;
    return VideoInfo(
        videoUrl: response["url_preview"],
        thumbUrl: response["url_thumbnail"],
        aspectRatio: aspectRatio);
  }
}
