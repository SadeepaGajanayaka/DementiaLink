import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/location_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isConnecting = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Hide system UI to ensure full coverage
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _checkExistingConnection();
  }

  @override
  void dispose() {
    // Restore system UI when dialog is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _emailController.dispose();
    super.dispose();
  }

  // Check if there's already a connection
  Future<void> _checkExistingConnection() async {
    try {
      final connectionInfo = await _locationService.getConnectedPatient();
      if (connectionInfo['connected']) {
        // Pre-fill the email field if there's an existing connection
        setState(() {
          _emailController.text = connectionInfo['patientEmail'] ?? '';
        });
      }
    } catch (e) {
      print("Error checking existing connection: $e");
    }
  }

  // Email validation function
  bool _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter an email address');
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return false;
    }

    setState(() => _emailError = null);
    return true;
  }

  // Connect with patient
  Future<void> _connectWithPatient() async {
    if (!_validateEmail()) return;

    setState(() {
      _isConnecting = true;
      _emailError = null;  // Clear any previous errors
    });

    try {
      print("Attempting to connect with patient: ${_emailController.text.trim()}");
      final result = await _locationService.connectWithPatient(_emailController.text.trim());

      if (mounted) {
        if (result['success']) {
          // Success - Return to maps screen with the patient ID
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected with ${_emailController.text.trim()}'),
              backgroundColor: Colors.green,
            ),
          );

          // Restore system UI before popping
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          Navigator.pop(context, result['patientId']);
        } else {
          // Error
          setState(() {
            _emailError = result['message'];
          });

          // Show error in SnackBar for better visibility
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error in connect with patient: $e");
      if (mounted) {
        setState(() {
          _emailError = 'Error connecting: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  // Disconnect from patient
  Future<void> _disconnectFromPatient() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      print("Attempting to disconnect from patient");
      bool success = await _locationService.disconnectFromPatient();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully disconnected from patient'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _emailController.clear();
            _emailError = null;
          });
        } else {
          setState(() {
            _emailError = 'Error disconnecting from patient';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error disconnecting from patient'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error disconnecting from patient: $e");
      if (mounted) {
        setState(() {
          _emailError = 'Error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen dialog that covers everything including the navigation bar
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Restore system UI mode
        if (didPop) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      },
      child: Scaffold(
        // Make sure we have a transparent background so our overlay shows
        backgroundColor: Colors.transparent,
        // Use SafeArea.minimum to ensure we draw under the status bar and navigation bar
        body: Container(
          // Cover the entire screen including navigation and status bars
          width: MediaQuery.of(context).size.width,
          // Use double.infinity to ensure we go beyond safe areas
          height: double.infinity,
          // This is the semi-transparent background
          color: const Color(0xFF503663).withOpacity(0.95),
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Close button in top right corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF77588D)),
                        onPressed: () {
                          // Restore system UI before popping
                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Image and text centered
                      Center(
                        child: SizedBox(
                          height: 100,
                          child: Image.asset(
                            'lib/assets/location_pin.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.location_on,
                                size: 80,
                                color: Color(0xFF77588D),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Connect with Patient',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF503663),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Enter the patient\'s email to track their location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Input field - centered
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'patient@example.com',
                            errorText: _emailError,
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Color(0xFF77588D),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF77588D)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Disconnect button on the left
                            ElevatedButton.icon(
                              onPressed: _isConnecting
                                  ? null
                                  : _disconnectFromPatient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: const Icon(
                                Icons.link_off,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Disconnect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Connect button on the right
                            ElevatedButton.icon(
                              onPressed: _isConnecting
                                  ? null
                                  : _connectWithPatient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF77588D),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: _isConnecting
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.link,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}