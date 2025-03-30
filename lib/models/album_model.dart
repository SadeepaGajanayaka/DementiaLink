import 'photo_model.dart';

class Album {
  final String id;
  String title;
  final String type;
  final DateTime createdAt;
  List<Photo> photos = [];

  Album({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    List<Photo>? photos,
  }) {
    if (photos != null) {
      this.photos = photos;
    }
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}