class VideoModel {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String duration;
  final int views;
  final String uploadDate;
  final String description;

  VideoModel({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.views,
    required this.uploadDate,
    required this.description,
  });
}