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
      version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the tables
        await db.execute(
          'CREATE TABLE albums (id TEXT PRIMARY KEY, title TEXT, type TEXT, createdAt INTEGER)',
        );
        await db.execute(
          'CREATE TABLE photos (id TEXT PRIMARY KEY, albumId TEXT, path TEXT, createdAt INTEGER, isFavorite INTEGER)',
        );
      },
    );

    // Create app's private media directory if it doesn't exist
    await _createAppMediaDirectories();

    // Load albums from database
    await _loadAlbums();

    _initialized = true;
    notifyListeners();
  }

  // Create private directories for media storage
  Future<void> _createAppMediaDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    // Create a .nomedia file on Android to prevent media scanning
    if (Platform.isAndroid) {
      final noMediaFile = File('${appDir.path}/.nomedia');
      if (!await noMediaFile.exists()) {
        await noMediaFile.create();
      }
    }
  }

  Future<void> _loadAlbums() async {
    final albumsData = await _database!.query('albums');
    _albums = [];

    for (var albumMap in albumsData) {
      final album = Album.fromMap(albumMap);

      // Load photos for each album
      final photosData = await _database!.query(
        'photos',
        where: 'albumId = ?',
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

  Future<void> addPhoto(String albumId, File imageFile) async {
    if (_database == null) await _initDatabase();

    // Get private directory for storing images
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = '${appDir.path}/photos';

    // Generate a unique ID and filename
    final id = _uuid.v4();
    final fileName = '$id.jpg';
    final targetPath = '$photosDir/$fileName';

    // Copy the file to our app's private directory
    final savedFile = await imageFile.copy(targetPath);

    final photo = Photo(
      id: id,
      albumId: albumId,
      path: savedFile.path,
      createdAt: DateTime.now(),
      isFavorite: false,
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
      await deletePhoto(photo.id);
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

  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    if (_database == null) await _initDatabase();

    final photosData = await _database!.query(
      'photos',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );

    return photosData.map((map) => Photo.fromMap(map)).toList();
  }

  Future<void> deletePhoto(String photoId) async {
    if (_database == null) await _initDatabase();

    // Find photo to get its path
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
      // Delete the file
      final file = File(targetPhoto.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete from database
      await _database!.delete(
        'photos',
        where: 'id = ?',
        whereArgs: [photoId],
      );

      // Remove from memory
      parentAlbum.photos.removeWhere((p) => p.id == photoId);

      notifyListeners();
    }
  }
}