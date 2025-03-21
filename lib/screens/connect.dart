import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/location_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _identifierController = TextEditingController();
  String? _errorMessage;
  bool _isConnecting = false;
  bool _isInputEmail = true;
  final LocationService _locationService = LocationService();

  // IMPROVED: Add more UI feedback
  bool _hasExistingConnection = false;
  String? _existingPatientEmail;

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
    _identifierController.dispose();
    super.dispose();
  }

  // IMPROVED: Better connection checking with error handling
  Future<void> _checkExistingConnection() async {
    try {
      final connectionInfo = await _locationService.getConnectedPatient();
      setState(() {
        _hasExistingConnection = connectionInfo['connected'] == true;
        _existingPatientEmail = connectionInfo['patientEmail'] as String?;
      });

      if (_hasExistingConnection && _existingPatientEmail != null) {
        // Pre-fill the email field if there's an existing connection
        _identifierController.text = _existingPatientEmail!;
        print("Prefilled email with existing connection: $_existingPatientEmail");
      }
    } catch (e) {
      print("Error checking existing connection: $e");
      // Don't update state here as we want to allow connection attempts even if check fails
    }
  }

  // Validate input with better error messages
  bool _validateInput() {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter an email address or ID');
      return false;
    }

    // Check if input is an email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    _isInputEmail = emailRegex.hasMatch(identifier);

    // If it's supposed to be an email but doesn't look valid
    if (_isInputEmail && !emailRegex.hasMatch(identifier)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }

  // IMPROVED: Connect with patient with better feedback and reliable tracking
  Future<void> _connectWithPatient() async {
    if (!_validateInput()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;  // Clear any previous errors
    });

    final identifier = _identifierController.text.trim();

    try {
      print("Attempting to connect with patient: $identifier");

      // Show searching message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Searching for patient...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Improved connection logic
      final result = await _locationService.connectWithPatient(identifier);

      if (mounted) {
        if (result['success']) {
          // Success - Set local connection state and trigger location updates
          setState(() {
            _hasExistingConnection = true;
            _existingPatientEmail = result['patientEmail'];
            _isConnecting = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected with ${result['patientEmail']}'),
              backgroundColor: Colors.green,
            ),
          );

          // CRITICAL FIX: Ensure we immediately trigger patient location update
          await _locationService.triggerUrgentLocationUpdate(result['patientId']);

          // Make another attempt after a short delay
          Future.delayed(Duration(seconds: 1), () {
            _locationService.triggerUrgentLocationUpdate(result['patientId']);
          });

          // Restore system UI before popping
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          Navigator.pop(context, result['patientId']);
        } else {
          // Error
          setState(() {
            _errorMessage = result['message'];
            _isConnecting = false;
          });

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
          _errorMessage = 'Error connecting: $e';
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // IMPROVED: Disconnect from patient with better feedback
  Future<void> _disconnectFromPatient() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      print("Attempting to disconnect from patient");

      // Show that we're processing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnecting...'),
          duration: Duration(seconds: 2),
        ),
      );

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
            _identifierController.clear();
            _errorMessage = null;
            _hasExistingConnection = false;
            _existingPatientEmail = null;
            _isConnecting = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Error disconnecting from patient';
            _isConnecting = false;
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
          _errorMessage = 'Error: $e';
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _hasExistingConnection
                              ? 'Currently connected to: $_existingPatientEmail'
                              : 'Enter the patient\'s email address or ID to track their location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _hasExistingConnection ?
                            Colors.green.shade700 : Colors.black54,
                            fontWeight: _hasExistingConnection ?
                            FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Input field - centered
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email or Patient ID',
                            errorText: _errorMessage,
                            prefixIcon: const Icon(
                              Icons.person,
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
                              onPressed: _isConnecting || !_hasExistingConnection
                                  ? null
                                  : _disconnectFromPatient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                disabledBackgroundColor: Colors.grey[300],
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
                              label: Text(
                                _hasExistingConnection ? 'Reconnect' : 'Connect',
                                style: const TextStyle(
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