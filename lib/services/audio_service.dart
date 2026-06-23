import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'youtube_service.dart';
import 'package:flutter/material.dart';

class AudioPlayerService with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final AudioPlayer _player = AudioPlayer();
  String? _currentVideoId;
  Timer? _progressTimer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  AudioPlayerService() {
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen((event) {
      _updateState();
    });

    _player.positionStream.listen((position) {
      _position = position;
      if (_player.playing) {
        _updateState();
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _updateState();
      }
    });
  }

  void _updateState() {
    _isPlaying = _player.playing;
    _duration = _player.duration;
    notifyListeners();
  }

  Future<void> playVideo(String videoId, String title, String author) async {
    try {
      _currentVideoId = videoId;
      
      final audioUrl = await _youtubeService.getAudioStreamUrl(videoId);
      if (audioUrl == null) {
        throw Exception('Не удалось получить аудио поток');
      }

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
      );

      await _player.play();
      _isPlaying = true;
      _updateState();
      _startProgressTimer();
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      rethrow;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateState();
    });
  }

  Future<void> play() async {
    await _player.play();
    _isPlaying = true;
    _updateState();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _updateState();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _progressTimer?.cancel();
    _updateState();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    _position = position;
    _updateState();
  }

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  String? get currentVideoId => _currentVideoId;

  void dispose() {
    _progressTimer?.cancel();
    _player.dispose();
    _youtubeService.dispose();
  }
}