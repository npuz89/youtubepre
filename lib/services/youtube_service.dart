import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_model.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  // Поиск видео
  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      final searchResults = await _yt.search.getVideos(query);
      
      return searchResults.map((video) {
        return VideoModel(
          id: video.id.value,
          title: video.title,
          author: video.author.name,
          thumbnailUrl: video.thumbnails.first.url.toString(),
          duration: video.duration?.toString() ?? '00:00',
          views: 0, // В бесплатном API не всегда доступно
          uploadDate: video.uploadDate?.toString() ?? '',
          description: '',
        );
      }).toList();
    } catch (e) {
      print('Ошибка поиска: $e');
      return [];
    }
  }

  // Получение популярных видео
  Future<List<VideoModel>> getTrendingVideos() async {
    try {
      final trending = await _yt.videos.getTrending();
      
      return trending.map((video) {
        return VideoModel(
          id: video.id.value,
          title: video.title,
          author: video.author.name,
          thumbnailUrl: video.thumbnails.first.url.toString(),
          duration: video.duration?.toString() ?? '00:00',
          views: 0,
          uploadDate: video.uploadDate?.toString() ?? '',
          description: '',
        );
      }).toList();
    } catch (e) {
      print('Ошибка получения трендов: $e');
      return [];
    }
  }

  // Получение детальной информации о видео
  Future<VideoModel?> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      
      return VideoModel(
        id: video.id.value,
        title: video.title,
        author: video.author.name,
        thumbnailUrl: video.thumbnails.first.url.toString(),
        duration: video.duration?.toString() ?? '00:00',
        views: video.views ?? 0,
        uploadDate: video.uploadDate?.toString() ?? '',
        description: video.description ?? '',
      );
    } catch (e) {
      print('Ошибка получения деталей: $e');
      return null;
    }
  }

  // Получение ссылки на аудио для фонового воспроизведения
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId);
      final audioStream = manifest.audio.first;
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