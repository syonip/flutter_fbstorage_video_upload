import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_video_sharing/video_info.dart';

class FirebaseDAL {
  static saveVideo(VideoInfo video) async {
    await Firestore.instance.collection('videos').document().setData({
        "videoUrl": video.videoUrl,
        "thumbUrl": video.thumbUrl,
        "coverUrl": video.coverUrl,
        "aspectRatio": video.aspectRatio,
      });
  }

  static listenToVideos(callback) async {
    Firestore.instance.collection('videos').snapshots().listen((qs) {
      final videos = mapQueryToVideoInfo(qs);
      callback(videos);
    });
  }

  static mapQueryToVideoInfo(QuerySnapshot qs) {
    return qs.documents.map((DocumentSnapshot ds) {
      return VideoInfo(
        videoUrl: ds.data["videoUrl"],
        thumbUrl: ds.data["thumbUrl"],
        coverUrl: ds.data["coverUrl"],
        aspectRatio: ds.data["aspectRatio"],
      );
    }).toList();
  }
}