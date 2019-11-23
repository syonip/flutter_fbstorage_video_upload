import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_publitio/flutter_publitio.dart';

import '../video_info.dart';

class PublitioDAL {
  static const PUBLITIO_PREFIX = "https://media.publit.io/file";

  static configurePublitio() async {
    await DotEnv().load('.env');
    await FlutterPublitio.configure(
        DotEnv().env['PUBLITIO_KEY'], DotEnv().env['PUBLITIO_SECRET']);
  }

  static getAspectRatio(response) {
    final width = response["width"];
    final height = response["height"];
    final double aspectRatio = width / height;
    return aspectRatio;
  }

  static getCoverUrl(response) {
    final publicId = response["public_id"];
    return "$PUBLITIO_PREFIX/$publicId.jpg";
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

    return VideoInfo(
      videoUrl: response["url_preview"],
      thumbUrl: response["url_thumbnail"],
      coverUrl: getCoverUrl(response),
      aspectRatio: getAspectRatio(response),
    );
  }
}
