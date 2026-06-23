import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/youtube_service.dart';
import '../models/video_model.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingVideos();
  }

  Future<void> _loadTrendingVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    final videos = await _youtubeService.getTrendingVideos();
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  Future<void> _searchVideos(String query) async {
    if (query.isEmpty) {
      _loadTrendingVideos();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final results = await _youtubeService.searchVideos(query);
    setState(() {
      _videos = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: _isSearching
            ? TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
                onSubmitted: _searchVideos,
                autofocus: true,
              )
            : const Text(
                'YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              // Реализация голосового поиска
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Ничего не найдено' : 'Видео не найдены',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  });
                  _loadTrendingVideos();
                },
                child: const Text('Вернуться к трендам'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrendingVideos,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return VideoCard(
            video: _videos[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    video: _videos[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}