import 'dart:io';
import 'package:flutter/material.dart';

class photo_note_card extends StatelessWidget {
  final File imageFile;
  final String? note;
  final Function(String?) onSave;
  final VoidCallback onSkip;
  final TextEditingController noteController = TextEditingController();

  photo_note_card({
    Key? key,
    required this.imageFile,
    this.note,
    required this.onSave,
    required this.onSkip,
  }) : super(key: key) {
    if (note != null) {
      noteController.text = note!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image container
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.file(
              imageFile,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Note input area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Note text field
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Add some note....',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  maxLines: 2,
                ),

                SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('SKIP'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final noteText = noteController.text.trim().isEmpty ? null : noteController.text.trim();
                        onSave(noteText);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('SAVE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}