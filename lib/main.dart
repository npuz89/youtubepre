import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const YouTubeFeedScreen(),
    );
  }
}

class YouTubeFeedScreen extends StatefulWidget {
  const YouTubeFeedScreen({Key? key}) : super(key: key);

  @override
  State<YouTubeFeedScreen> createState() => _YouTubeFeedScreenState();
}

class _YouTubeFeedScreenState extends State<YouTubeFeedScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Рилток для теста
  );
  
  BetterPlayerController? _betterPlayerController;
  bool _isLoading = false;

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startPlayback(String url) async {
    setState(() { _isLoading = true; });

    try {
      final yt = YoutubeExplode();
      // Парсим видео и получаем стрим
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      // Берём поток с наилучшим качеством, содержащий и видео, и аудио
      final streamInfo = manifest.muxed.withHighestVideoQuality();
      yt.close();

      // Настройка BetterPlayer с конфигурацией фонового режима
      BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        streamInfo.url.toString(),
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: video.title,
          author: video.author,
          imageUrl: video.thumbnails.mediumResUrl,
          activityName: "MainActivity",
        ),
      );

      _betterPlayerController = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
          handleLifecycle: true, // Важно для работы в фоне
        ),
        betterPlayerDataSource: dataSource,
      );

      // Включаем фоновое воспроизведение
      _betterPlayerController?.enablePictureInPicture(GlobalKey());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Background Player')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ссылка на YouTube видео',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _startPlayback(_controller.text),
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Воспроизвести в фоне'),
            ),
            const SizedBox(height: 24),
            if (_betterPlayerController != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController!),
              ),
          ],
        ),
      ),
    );
  }
}