import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoTile extends StatelessWidget {
  final String title;
  final String author;
  final String views;
  final String thumbnailUrl;

  const VideoTile({
    Key? key,
    required this.title,
    required this.author,
    required this.views,
    required this.thumbnailUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Миниатюра
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: thumbnailUrl,
              height: 80,
              width: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 80,
                width: 120,
                color: Colors.grey[900],
              ),
              errorWidget: (context, url, error) => Container(
                height: 80,
                width: 120,
                color: Colors.grey[900],
                child: const Icon(Icons.video_library, color: Colors.grey),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  views,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}