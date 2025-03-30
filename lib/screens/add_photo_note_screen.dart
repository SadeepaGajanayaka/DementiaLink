import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../widgets/photo_note_card.dart';

class AddPhotoNoteScreen extends StatefulWidget {
  final String albumId;
  final File imageFile;

  const AddPhotoNoteScreen({
    Key? key,
    required this.albumId,
    required this.imageFile,
  }) : super(key: key);

  @override
  _AddPhotoNoteScreenState createState() => _AddPhotoNoteScreenState();
}

class _AddPhotoNoteScreenState extends State<AddPhotoNoteScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF673AB7),
      appBar: AppBar(
        title: Text('Add Photo'),
        backgroundColor: Color(0xFF673AB7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display selected image
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Note input field
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add some note....',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Skip button
                  ElevatedButton(
                    onPressed: () {
                      _savePhotoToAlbum(context, null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('SKIP'),
                  ),

                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      String? note = _noteController.text.isNotEmpty
                          ? _noteController.text.trim()
                          : null;
                      _savePhotoToAlbum(context, note);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhotoToAlbum(BuildContext context, String? note) async {
    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    try {
      await storageProvider.addPhotoWithNote(
        widget.albumId,
        widget.imageFile,
        note: note,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo added successfully')),
      );

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding photo: ${e.toString()}')),
      );
    }
  }
}