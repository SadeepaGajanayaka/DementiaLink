import 'media_type.dart';

class Photo {
  final String id;
  final String albumId;
  final String path;
  final DateTime createdAt;
  bool isFavorite;
  String? note;
  final MediaType mediaType;

  Photo({
    required this.id,
    required this.albumId,
    required this.path,
    required this.createdAt,
    this.isFavorite = false,
    this.note,
    this.mediaType = MediaType.image,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      albumId: map['albumId'],
      path: map['path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isFavorite: map['isFavorite'] == 1,
      note: map['note'],
      mediaType: map['mediaType'] == 'video' ? MediaType.video : MediaType.image,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'albumId': albumId,
      'path': path,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'note': note,
      'mediaType': mediaType == MediaType.video ? 'video' : 'image',
    };
  }
}