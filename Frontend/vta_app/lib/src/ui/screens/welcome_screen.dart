import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:logging/logging.dart';


final _log = Logger('WelcomeScreen');
class WelcomeScreen extends StatefulWidget {
  static const String routeName = "/welcome";
  
  final AuthController authController;
  final ArtefactController artifactController;
  final SettingsController settingsController;

  const WelcomeScreen({
    super.key,
    required this.authController,
    required this.artifactController,
    required this.settingsController,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  User? _user;
  Uint8List? _profilePictureBytes;
  bool _isLoading = true;
  Timer? _navigationTimer;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _loadUserData();
    _loadProfilePicture();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _continueToApp();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final token = GetIt.instance.get<Token>();
      if (token.value != null) {
        final userRepository = UserRepository();
        final user = await userRepository.fetchUser(token.value!);
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
          // Start animations
          _fadeController.forward();
          Future.delayed(const Duration(milliseconds: 200), () {
            _scaleController.forward();
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            _slideController.forward();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _log.fine('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // First check for base64 encoded image
      final base64Image = prefs.getString('profilePicture');
      if (base64Image != null) {
        try {
          final bytes = base64Decode(base64Image);
          if (mounted) {
            setState(() {
              _profilePictureBytes = bytes;
            });
          }
          return;
        } catch (e) {
          _log.fine('Error decoding base64 image: $e');
        }
      }
      // Fallback to file path if base64 not found
      final imagePath = prefs.getString('profilePicturePath');
      if (imagePath != null) {
        // If it's a local file path, load it
        if (imagePath.startsWith('/') || imagePath.contains('\\')) {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (mounted) {
              setState(() {
                _profilePictureBytes = bytes;
              });
            }
          }
        }
      }
    } catch (e) {
      _log.fine('Error loading profile picture: $e');
    }
  }


  void _continueToApp() {
    Navigator.of(context).pushReplacementNamed(ArtifactBoardScreen.routeName);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: ExactAssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final username = _user?.username ?? _user?.name ?? 'Bruger';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile picture with animation (read-only)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _profilePictureBytes != null
                              ? Image.memory(
                                  _profilePictureBytes!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Welcome text with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Velkommen $username',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

