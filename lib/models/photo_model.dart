import 'media_type.dart';

class Photo {
  final String id;
  final String albumId;
  final String path;
  final DateTime createdAt;
  bool isFavorite;
  String? note;
  final MediaType mediaType;
  bool isDeleted;
  DateTime? deletedAt;

  Photo({
    required this.id,
    required this.albumId,
    required this.path,
    required this.createdAt,
    this.isFavorite = false,
    this.note,
    this.mediaType = MediaType.image,
    this.isDeleted = false,
    this.deletedAt,
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
      isDeleted: map['isDeleted'] == 1,
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'])
          : null,
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
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }
  int getDaysUntilPermanentDeletion() {
    if (!isDeleted || deletedAt == null) return 0;

    final deletionDate = deletedAt!.add(Duration(days: 30));
    final remaining = deletionDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
