import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_model.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();
  
  // Кеш для результатов
  final Map<String, List<VideoModel>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Поиск видео
  Future<List<VideoModel>> searchVideos(String query) async {
    // Проверяем кеш
    final cacheKey = 'search_$query';
    if (_cache.containsKey(cacheKey) && 
        DateTime.now().difference(_cacheTime[cacheKey]!) < _cacheDuration) {
      return _cache[cacheKey]!;
    }

    try {
      final searchResults = await _yt.search.getVideos(query);
      
      final videos = searchResults.map((video) {
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

      // Сохраняем в кеш
      _cache[cacheKey] = videos;
      _cacheTime[cacheKey] = DateTime.now();

      return videos;
    } catch (e) {
      print('Ошибка поиска: $e');
      return [];
    }
  }

  // Получение популярных видео
  Future<List<VideoModel>> getTrendingVideos() async {
    const cacheKey = 'trending';
    if (_cache.containsKey(cacheKey) && 
        DateTime.now().difference(_cacheTime[cacheKey]!) < _cacheDuration) {
      return _cache[cacheKey]!;
    }

    try {
      // Используем поиск по популярным запросам вместо getTrending
      final searchResults = await _yt.search.getVideos('trending');
      
      final videos = searchResults.map((video) {
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

      _cache[cacheKey] = videos;
      _cacheTime[cacheKey] = DateTime.now();

      return videos;
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
      
      // Получаем лучший аудио поток
      final audioStreams = manifest.audio;
      if (audioStreams.isEmpty) {
        throw Exception('Аудио потоки не найдены');
      }
      
      // Берем первый аудио поток (обычно наилучшего качества)
      final audioStream = audioStreams.first;
      return audioStream.url.toString();
    } catch (e) {
      print('Ошибка получения аудио: $e');
      return null;
    }
  }

  // Очистка кеша
  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  void dispose() {
    _yt.close();
    clearCache();
  }
}