import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:audio_session/audio_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Настраиваем аудио-сессию для фонового воспроизведения музыкального/видео контента
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const YouTubePlayerScreen(),
    );
  }
}

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({Key? key}) : super(key: key);

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController(
    text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  );
  
  VideoPlayerController? _videoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Следим за сворачиванием приложения
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Самая важная магия: не даем видео встать на паузу при уходе приложения в фон
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Обычно Flutter ставит видео на паузу здесь. 
      // Мы просто принудительно продолжаем играть поток.
      _videoController?.play();
    }
  }

  Future<void> _startVideo(String url) async {
    setState(() { _isLoading = true; });
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      // Для фонового режима лучше всего брать muxed стрим (аудио+видео вместе)
      final streamInfo = manifest.muxed.withHighestVideoQuality();
      yt.close();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(streamInfo.url.toString()))
        ..initialize().then((_) {
          setState(() { _isLoading = false; });
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка парсинга: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pure YT Background')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'URL видео с YouTube',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _startVideo(_controller.text),
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Запустить поток'),
            ),
            const SizedBox(height: 24),
            if (_videoController != null && _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
          ],
        ),
      ),
    );
  }
}