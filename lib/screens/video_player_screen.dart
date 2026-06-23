import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../services/audio_service.dart';
import '../widgets/video_tile.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final audioService = Provider.of<AudioPlayerService>(context, listen: false);
      await audioService.playVideo(
        widget.video.id,
        widget.video.title,
        widget.video.author,
      );

      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка воспроизведения: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель с кнопкой назад
            _buildTopBar(),
            
            // Видео или заглушка
            _buildVideoThumbnail(),
            
            // Информация о видео
            _buildVideoInfo(),
            
            // Кнопки управления
            _buildControls(),
            
            // Рекомендации
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[900],
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startPlayback,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      widget.video.thumbnailUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.video_library, size: 64, color: Colors.grey),
                        );
                      },
                    ),
                    if (!_isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 40,
                        ),
                      ),
                    if (_isPlaying && !_isLoading)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                          value: 0.5, // Здесь был бы реальный прогресс
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                widget.video.author,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${widget.video.views} просмотров',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
            onPressed: () {
              // Предыдущее видео
            },
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
              onPressed: () async {
                final audioService = Provider.of<AudioPlayerService>(context, listen: false);
                if (_isPlaying) {
                  await audioService.pause();
                } else {
                  await audioService.play();
                }
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
            onPressed: () {
              // Следующее видео
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Рекомендации',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Здесь должны быть рекомендации от YouTube
          for (int i = 0; i < 5; i++)
            const VideoTile(
              title: 'Пример рекомендации',
              author: 'Автор канала',
              views: '1.2M',
              thumbnailUrl: '',
            ),
        ],
      ),
    );
  }
}