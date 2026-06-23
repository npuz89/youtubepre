import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'youtube_service.dart';

class AudioPlayerService extends BaseAudioHandler {
  final YouTubeService _youtubeService = YouTubeService();
  final AudioPlayer _player = AudioPlayer();
  String? _currentVideoId;
  Timer? _progressTimer;

  AudioPlayerService() {
    _init();
  }

  Future<void> _init() async {
    // Подписка на события воспроизведения
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.positionStream.listen((position) {
      if (_player.playing) {
        _broadcastState();
      }
    });

    // Обработка завершения воспроизведения
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _broadcastState();
      }
    });
  }

  void _broadcastState() {
    final playing = _player.playing;
    final position = _player.position;
    final duration = _player.duration;
    final processingState = _player.processingState;

    // Определяем состояние обработки для audio_service
    AudioProcessingState processingStateEnum;
    if (processingState == ProcessingState.idle) {
      processingStateEnum = AudioProcessingState.idle;
    } else if (processingState == ProcessingState.loading || 
               processingState == ProcessingState.buffering) {
      processingStateEnum = AudioProcessingState.loading;
    } else if (processingState == ProcessingState.ready) {
      processingStateEnum = playing 
          ? AudioProcessingState.playing 
          : AudioProcessingState.paused;
    } else if (processingState == ProcessingState.completed) {
      processingStateEnum = AudioProcessingState.completed;
    } else {
      processingStateEnum = AudioProcessingState.idle;
    }

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seekTo,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingStateEnum,
      playing: playing,
      updatePosition: position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      duration: duration,
    ));
  }

  Future<void> playVideo(String videoId, String title, String author) async {
    try {
      _currentVideoId = videoId;
      
      // Получаем URL аудио потока
      final audioUrl = await _youtubeService.getAudioStreamUrl(videoId);
      if (audioUrl == null) {
        throw Exception('Не удалось получить аудио поток для видео: $videoId');
      }

      // Создаем MediaItem для уведомления
      final mediaItem = MediaItem(
        id: videoId,
        title: title.isNotEmpty ? title : 'Без названия',
        artist: author.isNotEmpty ? author : 'Неизвестный автор',
        album: 'YouTube',
        artUri: Uri.parse('https://img.youtube.com/vi/$videoId/hqdefault.jpg'),
        duration: const Duration(seconds: 0),
      );

      // Устанавливаем медиа элемент
      mediaItem.add(mediaItem);

      // Загружаем аудио
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
      );

      // Получаем реальную длительность
      final duration = _player.duration;
      if (duration != null) {
        final updatedMediaItem = mediaItem.copyWith(duration: duration);
        mediaItem.add(updatedMediaItem);
      }

      // Начинаем воспроизведение
      await _player.play();
      
      _broadcastState();
      _startProgressTimer();
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      rethrow;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _broadcastState();
    });
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _progressTimer?.cancel();
    _broadcastState();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    print('Skip to next');
  }

  @override
  Future<void> skipToPrevious() async {
    print('Skip to previous');
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
    _broadcastState();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    _broadcastState();
  }

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  String? get currentVideoId => _currentVideoId;

  @override
  Future<void> onTaskRemoved() async {
    await _player.pause();
  }

  Future<void> dispose() async {
    _progressTimer?.cancel();
    await _player.dispose();
    await _youtubeService.dispose();
  }
}