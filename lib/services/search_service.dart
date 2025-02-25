import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search for photos by folder name (e.g., 'Family', 'Friends')
  Future<List<Map<String, dynamic>>> searchByFolder(String folderName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .where('folder', isEqualTo: folderName)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error searching by folder: $e');
      return [];
    }
  }

  // Search for photos by date
  Future<List<Map<String, dynamic>>> searchByDate(DateTime date) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Get start and end of the day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .where('uploadDate', isGreaterThanOrEqualTo: startOfDay)
          .where('uploadDate', isLessThanOrEqualTo: endOfDay)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error searching by date: $e');
      return [];
    }
  }

  // General search by text (looks in captions or custom tags)
  Future<List<Map<String, dynamic>>> searchByText(String searchText) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Search in captions (this is a simple approach, for more advanced
      // text search you might need to implement a more robust solution)
      final captionSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .where('caption', isGreaterThanOrEqualTo: searchText)
          .where('caption', isLessThanOrEqualTo: searchText + '\uf8ff')
          .get();

      // Search in tags
      final tagSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .where('tags', arrayContains: searchText)
          .get();

      // Combine results and remove duplicates
      final captionResults = captionSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final tagResults = tagSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Combine and remove duplicates
      final allResults = [...captionResults, ...tagResults];
      final uniqueResults = allResults.fold<List<Map<String, dynamic>>>(
        [],
            (previousValue, element) {
          if (!previousValue.any((e) => e['id'] == element['id'])) {
            previousValue.add(element);
          }
          return previousValue;
        },
      );

      return uniqueResults;
    } catch (e) {
      print('Error searching by text: $e');
      return [];
    }
  }
}