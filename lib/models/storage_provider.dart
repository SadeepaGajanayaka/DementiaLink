import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'album_model.dart';
import 'photo_model.dart';
import 'media_type.dart';

class StorageProvider with ChangeNotifier {
  List<Album> _albums = [];
  Database? _database;
  final Uuid _uuid = Uuid();
  bool _initialized = false;

  List<Album> get albums => _albums;
  bool get isInitialized => _initialized;

  StorageProvider() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    // Get a location using path_provider
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'memory_journal.db');

    // Open/create the database at a given path
    _database = await openDatabase(
      path,
      version: 4, // Increment version for database migration
      onCreate: (Database db, int version) async {
        // When creating the db, create the tables
        await db.execute(
          'CREATE TABLE albums (id TEXT PRIMARY KEY, title TEXT, type TEXT, createdAt INTEGER)',
        );
        await db.execute(
          'CREATE TABLE photos (id TEXT PRIMARY KEY, albumId TEXT, path TEXT, createdAt INTEGER, isFavorite INTEGER, note TEXT, mediaType TEXT, isDeleted INTEGER DEFAULT 0, deletedAt INTEGER)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Add the note column if upgrading from version 1
          await db.execute('ALTER TABLE photos ADD COLUMN note TEXT');
        }
        if (oldVersion < 3) {
          // Add the mediaType column if upgrading from version 2
          await db.execute('ALTER TABLE photos ADD COLUMN mediaType TEXT DEFAULT "image"');
        }
        if (oldVersion < 4) {
          // Add deletion-related columns if upgrading from version 3
          await db.execute('ALTER TABLE photos ADD COLUMN isDeleted INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE photos ADD COLUMN deletedAt INTEGER');
        }
      },
    );

    // Create app's private media directory if it doesn't exist
    await _createAppMediaDirectories();

    // Add default albums if none exist
    await _createDefaultAlbums();

    // Load albums from database
    await _loadAlbums();

    _initialized = true;
    notifyListeners();
  }

  // Create private directories for media storage
  Future<void> _createAppMediaDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();

    // Create directories for different media types
    final photosDir = Directory('${appDir.path}/photos');
    final videosDir = Directory('${appDir.path}/videos');

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    // Create a .nomedia file on Android to prevent media scanning
    if (Platform.isAndroid) {
      final noMediaFile = File('${appDir.path}/.nomedia');
      if (!await noMediaFile.exists()) {
        await noMediaFile.create();
      }
    }
  }

  Future<void> _createDefaultAlbums() async {
    final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM albums'));

    if (count == 0) {
      // Create default Family and Friends albums
      await addAlbum('Family', 'system');
      await addAlbum('Friends', 'system');
    }
  }

  Future<void> _loadAlbums() async {
    final albumsData = await _database!.query('albums');
    _albums = [];

    for (var albumMap in albumsData) {
      final album = Album.fromMap(albumMap);

      // Load photos for each album that are not deleted
      final photosData = await _database!.query(
        'photos',
        where: 'albumId = ? AND (isDeleted IS NULL OR isDeleted = 0)',
        whereArgs: [album.id],
      );

      final photos = photosData.map((map) => Photo.fromMap(map)).toList();
      album.photos = photos;

      _albums.add(album);
    }

    notifyListeners();
  }

  Future<void> addAlbum(String title, String type) async {
    if (_database == null) await _initDatabase();

    final id = _uuid.v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await _database!.insert(
      'albums',
      {
        'id': id,
        'title': title,
        'type': type,
        'createdAt': createdAt,
      },
    );

    final album = Album(
      id: id,
      title: title,
      type: type,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );

    _albums.add(album);
    notifyListeners();
  }

  Future<void> updateAlbumTitle(String albumId, String newTitle) async {
    if (_database == null) await _initDatabase();

    await _database!.update(
      'albums',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [albumId],
    );

    final albumIndex = _albums.indexWhere((album) => album.id == albumId);
    if (albumIndex != -1) {
      _albums[albumIndex].title = newTitle;
      notifyListeners();
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    if (_database == null) await _initDatabase();

    // Delete all photos in the album
    final photos = await getPhotosByAlbum(albumId);
    for (var photo in photos) {
      await softDeletePhoto(photo.id);
    }

    // Delete the album from the database
    await _database!.delete(
      'albums',
      where: 'id = ?',
      whereArgs: [albumId],
    );

    _albums.removeWhere((album) => album.id == albumId);
    notifyListeners();
  }

  // New method for searching albums by title
  List<Album> searchAlbumsByTitle(String query) {
    if (query.isEmpty) return _albums;

    return _albums.where((album) =>
        album.title.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // New method for searching photos by date range
  Future<List<Photo>> searchPhotosByDateRange(DateTime start, DateTime end) async {
    if (_database == null) await _initDatabase();

    final startTimestamp = start.millisecondsSinceEpoch;
    final endTimestamp = end.millisecondsSinceEpoch;

    final photosData = await _database!.query(
      'photos',
      where: 'createdAt >= ? AND createdAt <= ? AND (isDeleted IS NULL OR isDeleted = 0)',
      whereArgs: [startTimestamp, endTimestamp],
    );

    return photosData.map((map) => Photo.fromMap(map)).toList();
  }

  // New method for searching photos by note content
  Future<List<Photo>> searchPhotosByNote(String query) async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
      'photos',
      where: 'note LIKE ? AND (isDeleted IS NULL OR isDeleted = 0)',
      whereArgs: ['%$query%'],
    );

    return photosData.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
      'photos',
      where: 'albumId = ? AND (isDeleted IS NULL OR isDeleted = 0)',
      whereArgs: [albumId],
    );

    return photosData.map((map) => Photo.fromMap(map)).toList();
  }

  Future<void> addPhoto(String albumId, File imageFile) async {
    await addMediaWithNote(albumId, imageFile, MediaType.image, note: null);
  }

  Future<void> addVideo(String albumId, File videoFile) async {
    await addMediaWithNote(albumId, videoFile, MediaType.video, note: null);
  }

  Future<void> addPhotoWithNote(String albumId, File imageFile, {String? note}) async {
    await addMediaWithNote(albumId, imageFile, MediaType.image, note: note);
  }

  Future<void> addVideoWithNote(String albumId, File videoFile, {String? note}) async {
    await addMediaWithNote(albumId, videoFile, MediaType.video, note: note);
  }

  Future<void> addMediaWithNote(String albumId, File mediaFile, MediaType mediaType, {String? note}) async {
    if (_database == null) await _initDatabase();

    // Get the appropriate directory for storing the media
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = mediaType == MediaType.video
        ? '${appDir.path}/videos'
        : '${appDir.path}/photos';

    // Generate a unique ID and filename
    final id = _uuid.v4();
    final fileExtension = mediaType == MediaType.video ? '.mp4' : '.jpg';
    final fileName = '$id$fileExtension';
    final targetPath = '$mediaDir/$fileName';

    // Copy the file to our app's private directory
    final savedFile = await mediaFile.copy(targetPath);

    final photo = Photo(
      id: id,
      albumId: albumId,
      path: savedFile.path,
      createdAt: DateTime.now(),
      isFavorite: false,
      note: note,
      mediaType: mediaType,
      isDeleted: false,
      deletedAt: null,
    );

    // Save to database
    await _database!.insert(
      'photos',
      photo.toMap(),
    );

    // Update album in memory
    final album = _albums.firstWhere((a) => a.id == albumId);
    album.photos.add(photo);

    notifyListeners();
  }

  Future<void> updatePhotoNote(String photoId, String? note) async {
    if (_database == null) await _initDatabase();

    // Find photo in albums
    Photo? targetPhoto;
    Album? parentAlbum;

    for (var album in _albums) {
      final photo = album.photos.firstWhere(
            (p) => p.id == photoId,
        orElse: () => Photo(id: '', albumId: '', path: '', createdAt: DateTime.now()),
      );

      if (photo.id.isNotEmpty) {
        targetPhoto = photo;
        parentAlbum = album;
        break;
      }
    }

    if (targetPhoto != null) {
      // Update note
      targetPhoto.note = note;

      // Update in database
      await _database!.update(
        'photos',
        {'note': note},
        where: 'id = ?',
        whereArgs: [photoId],
      );

      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String photoId) async {
    if (_database == null) await _initDatabase();

    // Find photo in albums
    Photo? targetPhoto;
    Album? parentAlbum;

    for (var album in _albums) {
      final photo = album.photos.firstWhere(
            (p) => p.id == photoId,
        orElse: () => Photo(id: '', albumId: '', path: '', createdAt: DateTime.now()),
      );

      if (photo.id.isNotEmpty) {
        targetPhoto = photo;
        parentAlbum = album;
        break;
      }
    }

    if (targetPhoto != null && parentAlbum != null) {
      // Toggle favorite status
      targetPhoto.isFavorite = !targetPhoto.isFavorite;

      // Update in database
      await _database!.update(
        'photos',
        {'isFavorite': targetPhoto.isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [photoId],
      );

      notifyListeners();
    }
  }

  // Soft delete a photo (moved to trash)
  Future<void> softDeletePhoto(String photoId) async {
    if (_database == null) await _initDatabase();

    // Find photo to update its deleted status
    Photo? targetPhoto;
    Album? parentAlbum;

    for (var album in _albums) {
      final index = album.photos.indexWhere((p) => p.id == photoId);
      if (index != -1) {
        targetPhoto = album.photos[index];
        parentAlbum = album;
        break;
      }
    }

    if (targetPhoto != null && parentAlbum != null) {
      // Update photo's deleted status
      targetPhoto.isDeleted = true;
      targetPhoto.deletedAt = DateTime.now();

      // Update in database
      await _database!.update(
        'photos',
        {
          'isDeleted': 1,
          'deletedAt': targetPhoto.deletedAt!.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [photoId],
      );

      // Remove from album in memory but keep in database
      parentAlbum.photos.removeWhere((p) => p.id == photoId);

      notifyListeners();
    }
  }

  // Get all soft-deleted photos
  Future<List<Photo>> getDeletedPhotos() async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
      'photos',
      where: 'isDeleted = ?',
      whereArgs: [1],
    );

    final deletedPhotos = photosData.map((map) => Photo.fromMap(map)).toList();

    // Sort by deletion date, most recent first
    deletedPhotos.sort((a, b) => (b.deletedAt ?? DateTime.now())
        .compareTo(a.deletedAt ?? DateTime.now()));

    return deletedPhotos;
  }

  // Recover photos from trash
  Future<void> recoverDeletedPhotos(List<String> photoIds) async {
    if (_database == null) await _initDatabase();

    if (photoIds.isEmpty) return;

    // Update photos in database
    final batch = _database!.batch();

    for (final photoId in photoIds) {
      batch.update(
        'photos',
        {
          'isDeleted': 0,
          'deletedAt': null,
        },
        where: 'id = ?',
        whereArgs: [photoId],
      );
    }

    await batch.commit();

    // Reload albums to reflect changes
    await _loadAlbums();
  }

  // Permanently delete photos
  Future<void> permanentlyDeletePhotos(List<String> photoIds) async {
    if (_database == null) await _initDatabase();

    if (photoIds.isEmpty) return;

    // Get photos to delete their files
    final photosList = <Photo>[];

    for (final photoId in photoIds) {
      final photosData = await _database!.query(
        'photos',
        where: 'id = ?',
        whereArgs: [photoId],
      );

      if (photosData.isNotEmpty) {
        photosList.add(Photo.fromMap(photosData.first));
      }
    }

    // Delete the files
    for (final photo in photosList) {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete from database
    final batch = _database!.batch();

    for (final photoId in photoIds) {
      batch.delete(
        'photos',
        where: 'id = ?',
        whereArgs: [photoId],
      );
    }

    await batch.commit();

    notifyListeners();
  }

  // Check for photos that have been in trash for more than 30 days and delete them
  Future<void> cleanupExpiredDeletedPhotos() async {
    if (_database == null) await _initDatabase();

    final deletedPhotos = await getDeletedPhotos();
    final now = DateTime.now();
    final expiredPhotoIds = deletedPhotos
        .where((photo) => photo.deletedAt != null &&
        now.difference(photo.deletedAt!).inDays > 30)
        .map((photo) => photo.id)
        .toList();

    if (expiredPhotoIds.isNotEmpty) {
      await permanentlyDeletePhotos(expiredPhotoIds);
    }
  }

  // Delete photo now uses soft deletion
  Future<void> deletePhoto(String photoId) async {
    if (_database == null) await _initDatabase();

    await softDeletePhoto(photoId);
  }

  Future<List<Photo>> getFavoritePhotos() async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
      'photos',
      where: 'isFavorite = ? AND (isDeleted IS NULL OR isDeleted = 0)',
      whereArgs: [1],
    );

    return photosData.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getAllPhotos() async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
        'photos',
        where: 'isDeleted IS NULL OR isDeleted = 0'
    );
    return photosData.map((map) => Photo.fromMap(map)).toList();
  }
}