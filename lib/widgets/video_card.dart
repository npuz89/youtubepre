import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Миниатюра
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Icon(Icons.video_library, color: Colors.grey, size: 48),
                  ),
                ),
                if (video.duration.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.black.withOpacity(0.8),
                      child: Text(
                        video.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Информация о видео
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар автора
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[800],
                    child: Text(
                      video.author.isNotEmpty ? video.author[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Текст
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.author,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              NumberFormat.compact().format(video.views),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              video.uploadDate.isNotEmpty 
                                  ? _formatDate(video.uploadDate) 
                                  : 'Дата неизвестна',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Кнопка меню
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                    onPressed: () {
                      // Показать меню с опциями
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} год назад';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} мес. назад';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} дн. назад';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ч. назад';
      } else {
        return '${difference.inMinutes} мин. назад';
      }
    } catch (e) {
      return dateString;
    }
  }
}