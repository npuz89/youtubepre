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

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Без названия',
      author: json['author'] ?? 'Неизвестный автор',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      duration: json['duration'] ?? '00:00',
      views: json['views'] ?? 0,
      uploadDate: json['uploadDate'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'views': views,
      'uploadDate': uploadDate,
      'description': description,
    };
  }
}