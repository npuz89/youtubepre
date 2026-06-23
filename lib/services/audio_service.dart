import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.youtube.audio',
      androidNotificationChannelName: 'YouTube Background Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );

    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.positionStream.listen((position) {
      if (_player.playing) {
        _broadcastState();
      }
    });
  }

  void _broadcastState() {
    final state = _player.playing
        ? PlaybackState.playing
        : PlaybackState.paused;
    
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seekTo,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _player.playing
          ? ProcessingState.ready
          : ProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  Future<void> playVideo(String videoId, String title, String author) async {
    try {
      _currentVideoId = videoId;
      
      final audioUrl = await _youtubeService.getAudioStreamUrl(videoId);
      if (audioUrl == null) throw Exception('Не удалось получить аудио');

      final mediaItem = MediaItem(
        id: videoId,
        title: title,
        artist: author,
        artUri: Uri.parse('https://img.youtube.com/vi/$videoId/hqdefault.jpg'),
      );

      mediaItem.add(mediaItem);

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
      );

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
    // Реализуйте переход к следующему видео в плейлисте
  }

  @override
  Future<void> skipToPrevious() async {
    // Реализуйте переход к предыдущему видео в плейлисте
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _broadcastState();
  }

  Future<void> dispose() async {
    _progressTimer?.cancel();
    await _player.dispose();
    _youtubeService.dispose();
  }
}