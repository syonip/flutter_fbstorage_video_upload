import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

removeExtension(String path) {
  final str = path.substring(0, path.length - 4);
  return str;
}

class EncodingProvider {
  static final FlutterFFmpeg _encoder = FlutterFFmpeg();
  static final FlutterFFprobe _probe = FlutterFFprobe();
  static final FlutterFFmpegConfig _config = FlutterFFmpegConfig();

  static Future<String> encode(videoPath) async {
    assert(File(videoPath).existsSync());

    final noExt = removeExtension(videoPath);
    final String outPath = '$noExt-encoded.mp4';
    List<String> arguments = [
      '-y', // overwrite
      '-i',
      videoPath,
      '-an',
      '-c:v',
      'libx264',
      // '-x265-params',
      // 'lossless=1',
      // '-crf',
      // '22',
      '-preset',
      'ultrafast',
      '-b:v',
      '2M',
      '-bufsize',
      '2M',
      // '-profile:v',
      // 'baseline',
      outPath
    ];

    final int rc = await _encoder.executeWithArguments(arguments);
    assert(rc == 0);
    assert(File(outPath).existsSync());

    return outPath;
  }

  static Future<String> encodeHLS(videoPath, outDirPath) async {
    assert(File(videoPath).existsSync());

    List<String> arguments = [
      '-y', // overwrite
      '-i',
      videoPath,
      '-an',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '20',
      '-g',
      '48',
      '-keyint_min',
      '48',
      '-sc_threshold',
      '0',
      '-b:v',
      '2500k',
      '-maxrate',
      '2675k',
      '-bufsize',
      '3750k',
      '-hls_time',
      '4',
      '-hls_playlist_type',
      'vod',
      '-hls_segment_filename',
      '$outDirPath/720p_%03d.ts',
      '$outDirPath/720p.m3u8',
    ];

    final int rc = await _encoder.executeWithArguments(arguments);
    assert(rc == 0);

    return outDirPath;
  }

  static double getAspectRatio(Map<dynamic, dynamic> info) {
    final int width = info['streams'][0]['width'];
    final int height = info['streams'][0]['height'];
    final double aspect = height / width;
    return aspect;
  }

  static Future<String> getThumb(videoPath, width, height) async {
    assert(File(videoPath).existsSync());

    final String outPath = '$videoPath.jpg';
    List<String> arguments = [
      '-y', // overwrite
      '-i',
      videoPath,
      '-vframes',
      '1',
      '-an',
      '-s',
      '${width}x${height}',
      '-ss',
      '1',
      outPath
    ];
    final int rc = await _encoder.executeWithArguments(arguments);
    assert(rc == 0);
    assert(File(outPath).existsSync());

    return outPath;
  }

  static void enableStatisticsCallback(Function cb) {
    return _config.enableStatisticsCallback(cb);
  }

  static Future<void> cancel() async {
    await _encoder.cancel();
  }

  static Future<Map<dynamic, dynamic>> getMediaInformation(String path) async {
    assert(File(path).existsSync());

    return await _probe.getMediaInformation(path);
  }

  static int getDuration(Map<dynamic, dynamic> info) {
    return info['duration'];
  }

  static void enableLogCallback(void Function(int level, String message) logCallback) {
    _config.enableLogCallback(logCallback);
  }
}
