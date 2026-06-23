import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Библиотека',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ваша библиотека пуста',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Переход на главный экран
                Navigator.pop(context);
              },
              child: const Text('Найти видео'),
            ),
          ],
        ),
      ),
    );
  }
}