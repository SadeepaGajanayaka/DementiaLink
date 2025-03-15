import 'package:flutter/material.dart';

class AddScreen extends StatefulWidget {
  final Function(String safezone, String location) onSafezoneAdded;

  const AddScreen({super.key, required this.onSafezoneAdded});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _safezoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _setInMap = false;

  @override
  void dispose() {
    _safezoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image
                        SizedBox(
                          height: 120,
                          child: Image.asset(
                            'assets/map_location.png',
                            fit: BoxFit.contain,
                            // If you don't have this image, you can use a placeholder:
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                width: 120,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.map,
                                  size: 50,
                                  color: Colors.blue[300],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Enter safe zone
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter safe zone',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: _safezoneController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Enter Location
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Set in map toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Set in map',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _setInMap,
                              onChanged: (value) {
                                setState(() {
                                  _setInMap = value;
                                });
                              },
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF503663),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Delete and Checkbox
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.check_box_outlined,
                                      color: Color(0xFF503663),
                                    ),
                                    onPressed: () {
                                      // Checkbox action
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFF503663),
                                    ),
                                    onPressed: () {
                                      _safezoneController.clear();
                                      _locationController.clear();
                                      setState(() {
                                        _setInMap = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Save button
                            ElevatedButton(
                              onPressed: () {
                                // Validate inputs
                                if (_safezoneController.text.trim().isEmpty ||
                                    _locationController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill all fields'),
                                      backgroundColor: Color(0xFF503663),
                                    ),
                                  );
                                  return;
                                }

                                // Call the callback function to add the safezone
                                widget.onSafezoneAdded(
                                  _safezoneController.text.trim(),
                                  _locationController.text.trim(),
                                );

                                // Navigate back
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF503663),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}