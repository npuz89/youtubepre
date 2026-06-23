import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_model.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      final searchResults = await _yt.search.getVideos(query);
      
      final videos = <VideoModel>[];
      for (var video in searchResults) {
        // Получаем миниатюру
        String thumbnailUrl = '';
        try {
          thumbnailUrl = video.thumbnails.standardRes?.url.toString() ?? 
                        video.thumbnails.mediumRes?.url.toString() ??
                        video.thumbnails.highRes?.url.toString() ?? '';
        } catch (e) {
          thumbnailUrl = '';
        }

        videos.add(VideoModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          thumbnailUrl: thumbnailUrl,
          duration: video.duration?.toString() ?? '00:00',
          views: 0,
          uploadDate: '',
          description: '',
        ));
      }
      return videos;
    } catch (e) {
      print('Ошибка поиска: $e');
      return [];
    }
  }

  Future<List<VideoModel>> getTrendingVideos() async {
    try {
      final searchResults = await _yt.search.getVideos('trending');
      
      final videos = <VideoModel>[];
      for (var video in searchResults.take(20)) {
        String thumbnailUrl = '';
        try {
          thumbnailUrl = video.thumbnails.standardRes?.url.toString() ?? 
                        video.thumbnails.mediumRes?.url.toString() ??
                        video.thumbnails.highRes?.url.toString() ?? '';
        } catch (e) {
          thumbnailUrl = '';
        }

        videos.add(VideoModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          thumbnailUrl: thumbnailUrl,
          duration: video.duration?.toString() ?? '00:00',
          views: 0,
          uploadDate: '',
          description: '',
        ));
      }
      return videos;
    } catch (e) {
      print('Ошибка получения трендов: $e');
      return [];
    }
  }

  Future<VideoModel?> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      
      String thumbnailUrl = '';
      try {
        thumbnailUrl = video.thumbnails.standardRes?.url.toString() ?? 
                      video.thumbnails.mediumRes?.url.toString() ??
                      video.thumbnails.highRes?.url.toString() ?? '';
      } catch (e) {
        thumbnailUrl = '';
      }

      return VideoModel(
        id: video.id.value,
        title: video.title,
        author: video.author,
        thumbnailUrl: thumbnailUrl,
        duration: video.duration?.toString() ?? '00:00',
        views: 0,
        uploadDate: '',
        description: '',
      );
    } catch (e) {
      print('Ошибка получения деталей: $e');
      return null;
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId);
      
      final audioStreams = manifest.audio;
      if (audioStreams.isEmpty) {
        throw Exception('Аудио потоки не найдены');
      }
      
      final audioStream = audioStreams.first;
      return audioStream.url.toString();
    } catch (e) {
      print('Ошибка получения аудио: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}