import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';
import 'photo_detail_screen.dart';
import 'album_details_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Photo> _matchedPhotos = [];
  List<Album> _matchedAlbums = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _matchedPhotos = [];
        _matchedAlbums = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    // Search albums by title
    final filteredAlbums = storageProvider.searchAlbumsByTitle(query);

    // Search photos by note content
    final notePhotos = await storageProvider.searchPhotosByNote(query);

    // Get all photos to search by date
    final allPhotos = await storageProvider.getAllPhotos();
    final datePhotos = allPhotos.where((photo) => _dateMatchesSearch(photo.createdAt, query)).toList();

    // Combine photo results and remove duplicates
    final Set<String> photoIds = {};
    final List<Photo> uniquePhotos = [];

    for (var photo in [...notePhotos, ...datePhotos]) {
      if (!photoIds.contains(photo.id)) {
        photoIds.add(photo.id);
        uniquePhotos.add(photo);
      }
    }

    setState(() {
      _matchedAlbums = filteredAlbums;
      _matchedPhotos = uniquePhotos;
      _isSearching = false;
    });
  }

  // Helper method to check if a date matches the search query
  bool _dateMatchesSearch(DateTime date, String query) {
    if (query.isEmpty) return false;

    try {
      // Format the date in various ways to check against the search
      final DateFormat fullFormat = DateFormat('yyyy-MM-dd');
      final DateFormat monthYearFormat = DateFormat('MMM yyyy');
      final DateFormat monthFormat = DateFormat('MMMM');
      final DateFormat yearFormat = DateFormat('yyyy');

      final String fullDate = fullFormat.format(date);
      final String monthYear = monthYearFormat.format(date);
      final String month = monthFormat.format(date);
      final String year = yearFormat.format(date);

      query = query.toLowerCase();

      return fullDate.toLowerCase().contains(query) ||
          monthYear.toLowerCase().contains(query) ||
          month.toLowerCase().contains(query) ||
          year.contains(query);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF673AB7),
      appBar: AppBar(
        title: Text('Search'),
        backgroundColor: Color(0xFF673AB7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search albums, dates, notes...',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
                    : null,
              ),
              style: TextStyle(color: Colors.white),
              onChanged: _performSearch,
            ),
          ),

          // Loading indicator
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // Results
          if (!_isSearching && (_matchedAlbums.isNotEmpty || _matchedPhotos.isNotEmpty))
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab bar
                    TabBar(
                      tabs: [
                        Tab(
                          icon: Icon(Icons.collections),
                          text: 'Albums (${_matchedAlbums.length})',
                        ),
                        Tab(
                          icon: Icon(Icons.photo_library),
                          text: 'Photos (${_matchedPhotos.length})',
                        ),
                      ],
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Albums tab
                          _matchedAlbums.isEmpty
                              ? _buildEmptyResults('No albums match your search')
                              : _buildAlbumResults(),

                          // Photos tab
                          _matchedPhotos.isEmpty
                              ? _buildEmptyResults('No photos match your search')
                              : _buildPhotoResults(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // No results message
          if (!_isSearching && _matchedAlbums.isEmpty && _matchedPhotos.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: _buildEmptyResults('No results found'),
            ),

          // Initial state
          if (!_isSearching && _searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 80,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Search for albums, photos, dates, or notes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try searching for month names, years, or keywords in notes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumResults() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _matchedAlbums.length,
      itemBuilder: (context, index) {
        final album = _matchedAlbums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumDetailScreen(album: album),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Album preview
                album.photos.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(album.photos.first.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 48,
                        ),
                      );
                    },
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                // Album info overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${album.photos.length} items',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoResults() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _matchedPhotos.length,
      itemBuilder: (context, index) {
        final photo = _matchedPhotos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoDetailScreen(
                  photo: photo,
                  photos: _matchedPhotos,
                  currentIndex: index,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo.mediaType == MediaType.video
                    ? VideoThumbnailUtil.buildVideoThumbnail(
                  photo.path,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade800,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              if (photo.isFavorite)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              // Show media type indicator
              if (photo.mediaType == MediaType.video)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              // Show note indicator if the photo has a note
              if (photo.note != null && photo.note!.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              // Highlight search match in note
              if (photo.note != null &&
                  photo.note!.toLowerCase().contains(_searchController.text.toLowerCase()) &&
                  _searchController.text.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Note match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}