import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:new_test/AIChatScreen.dart';
import 'package:new_test/modules.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'audio_note_player.dart';
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';


void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black87,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

// --- App Constants & Design System ---
class AppColors {
  // Define a mapping of color names to actual Color objects
  static final Map<String, Color> accentColors = {
    'Default': Color(0xFF2D80EC), // Indigo
    'Green': Color(0xFF50C555), // Green
    'Red': Color(0xFFEF5350), // Red
    'Blue': Color(0xFF2196F3), // Blue (a different blue than default indigo)
    'Yellow': Color(0xFFFFC613), // Yellow
  };
  // Light theme specific colors
  static Color lightPrimaryNeutral = Color(0xFFF5F5F5); // Light Gray
  static Color lightSecondaryNeutral = Color(0xFFE0E0E0); // Lighter Gray
  static Color lightDarkNeutral = Color(0xFF424242); // Dark Gray

  // Dark theme specific colors
  static Color darkPrimaryNeutral = Color(0xFF121212); // Very Dark Gray
  static Color darkSecondaryNeutral = Color(0xFF212121); // Darker Gray
  static Color darkDarkNeutral = Color(0xFFE0E0E0); // Light Gray for text

  static Color successColor = Color(0xFF66BB6A); // Green for positive
  static Color warningColor = Color(0xFFFFCA28); // Yellow for caution
  static Color errorColor = Color(0xFFEF5350); // Red for error

  // Default vibrant color will be used if no preference is set or if key is invalid
  static Color get defaultVibrantColor => accentColors['Default']!;
}

class AppConstants {
  static const String appName = "Saathi";
  static const String tagline = "Your Mental Wellness Ally";
  static const String journalEntriesKey = 'journalEntries'; // Key for journal entries
  static const String userNameKey = 'user_name'; // New key for user name
  static const String accentColorKey = 'accent_color'; // New key for accent color
  static const String dailyMindResetsCountKey = 'dailyMindResetsCount'; // New key for daily mind resets count
  static const String themeModeKey = 'theme_mode'; // New key for theme mode

  static const List<Map<String, dynamic>> introSlides = [
    {
      'title': 'Master your mindset',
      'icon': Icons.psychology_rounded,
    },
    {
      'title': 'Empower your inner self',
      'icon': Icons.record_voice_over_rounded,
    },
    {
      'title': 'Track your mental performance',
      'icon': Icons.show_chart_rounded,
    },
  ];
}

// --- New: ColorProvider for State Management ---
class ColorProvider with ChangeNotifier {
  Color _currentAccentColor = AppColors.defaultVibrantColor;
  String _currentAccentColorName = 'Default';

  Color get currentAccentColor => _currentAccentColor;
  String get currentAccentColorName => _currentAccentColorName;

  ColorProvider() {
    _loadAccentColor();
  }

  Future<void> _loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorName = prefs.getString(AppConstants.accentColorKey) ?? 'Default';
    _setAccentColor(savedColorName); // Use the internal setter to update state
  }

  Future<void> setAccentColor(String colorName) async {
    if (AppColors.accentColors.containsKey(colorName)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accentColorKey, colorName);
      _setAccentColor(colorName);
    }
  }

  void _setAccentColor(String colorName) {
    _currentAccentColor = AppColors.accentColors[colorName] ?? AppColors.defaultVibrantColor;
    _currentAccentColorName = colorName;
    notifyListeners(); // Notify all listening widgets to rebuild
  }
}

// --- New: ThemeProvider for State Management ---
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(AppConstants.themeModeKey);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == 'ThemeMode.$savedThemeMode',
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, _themeMode.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, _themeMode.name);
    notifyListeners();
  }
}


// --- Journal Entry Model ---
class JournalEntry {
  final String text;
  final DateTime timestamp;
  final String? audioPath;

  JournalEntry({
    required this.text,
    required this.timestamp,
    this.audioPath,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'audioPath': audioPath,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],
    );
  }
}


// --- Main App Entry Point ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? userName = prefs.getString(AppConstants.userNameKey); // Get user name

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ColorProvider()), // Provide the ColorProvider
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // Provide the ThemeProvider
      ],
      child: MyApp(userName: userName),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? userName; // Receive the user name
  const MyApp({super.key, this.userName});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? initialScreen;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool("isFirstTime") ?? true;

    if (isFirstTime) {
      await prefs.setBool("isFirstTime", false);
      setState(() => initialScreen = const WelcomeScreen());
    } else if (widget.userName == null || widget.userName!.isEmpty) {
      setState(() => initialScreen = const UserNameInputScreen());
    } else {
      setState(() => initialScreen = const HomeDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // -------------------- Light Theme --------------------
      theme: ThemeData(
        primaryColor: accentColor,
        scaffoldBackgroundColor: AppColors.lightPrimaryNeutral,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightPrimaryNeutral,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.lightDarkNeutral),
          titleTextStyle: TextStyle(
            color: AppColors.lightDarkNeutral,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: Colors.white,
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.lightDarkNeutral,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.lightDarkNeutral,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.lightDarkNeutral,
          ),
          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: AppColors.lightDarkNeutral,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.lightDarkNeutral,
          ),
        ).apply(
          bodyColor: AppColors.lightDarkNeutral,
          displayColor: AppColors.lightDarkNeutral,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: accentColor,
          background: AppColors.lightPrimaryNeutral,
          onBackground: AppColors.lightDarkNeutral,
          surface: Colors.white,
          onSurface: AppColors.lightDarkNeutral,
        ),
      ),

      // -------------------- Dark Theme --------------------
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: accentColor,
        scaffoldBackgroundColor: AppColors.darkPrimaryNeutral,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkPrimaryNeutral,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkDarkNeutral),
          titleTextStyle: TextStyle(
            color: AppColors.darkDarkNeutral,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: AppColors.darkSecondaryNeutral,
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkDarkNeutral,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkDarkNeutral,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.darkDarkNeutral,
          ),
          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkPrimaryNeutral,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: AppColors.darkDarkNeutral,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.darkDarkNeutral,
          ),
        ).apply(
          bodyColor: AppColors.darkDarkNeutral,
          displayColor: AppColors.darkDarkNeutral,
        ),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          secondary: accentColor,
          background: AppColors.darkPrimaryNeutral,
          onBackground: AppColors.darkDarkNeutral,
          surface: AppColors.darkSecondaryNeutral,
          onSurface: AppColors.darkDarkNeutral,
        ),
      ),

      // -------------------- Initial Screen --------------------
      home: initialScreen ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
    );
  }
}


// --- New: User Name Input Screen ---
class UserNameInputScreen extends StatefulWidget {
  const UserNameInputScreen({super.key});

  @override
  State<UserNameInputScreen> createState() => _UserNameInputScreenState();
}

class _UserNameInputScreenState extends State<UserNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveUserName() async {
    if (_formKey.currentState!.validate()) {
      final String userName = _nameController.text.trim();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userNameKey, userName);

      // Navigator.of(context).pushReplacement ensures no going back to this screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeDashboard()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor; // Get accent color

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Just one more step!', style: textTheme.headlineMedium),
        automaticallyImplyLeading: false, // Don't allow going back
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What should we call you?',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(
                    color: Colors.grey, // Color when not focused
                  ),
                  floatingLabelStyle: TextStyle(
                    color: accentColor, // Color when focused
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'e.g., Alex',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2), // Use accent color
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveUserName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // Use accent color
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text('Continue', style: textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Onboarding Flow (Screens 1-3) ---

// Screen 1: Welcome
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor; // Get accent color

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: AppConstants.introSlides.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder for your app logo
                      Image.asset(
                        'assets/app_logo.png', // Your app logo - make sure this path is correct
                        height: 120,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: textTheme.displayLarge,
                      ),
                      Text(
                        AppConstants.tagline,
                        style: textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Intro slide content
                      Icon(
                        AppConstants.introSlides[index]['icon'] as IconData,
                        size: 150,
                        color: accentColor, // matches the theme
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.introSlides[index]['title']!,
                        style: textTheme.headlineMedium?.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AppConstants.introSlides.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? accentColor // Use accent color
                        : accentColor.withOpacity(0.5), // Use accent color with opacity
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const UserNameInputScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // Use accent color
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Get Started',
                  style: textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- New: DailyMindResetScreen ---
class DailyMindResetScreen extends StatefulWidget {
  const DailyMindResetScreen({super.key});

  @override
  State<DailyMindResetScreen> createState() => _DailyMindResetScreenState();
}

class _DailyMindResetScreenState extends State<DailyMindResetScreen> {
  static const int _sessionDurationSeconds = 5 * 60; // 5 minutes
  int _remainingSeconds = _sessionDurationSeconds;
  Timer? _timer;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Create an instance of AudioPlayer

  @override
  void initState() {
    super.initState();
    // Pre-load the audio for faster playback if needed, or play directly.
    // _audioPlayer.setSourceAsset('audio/timer_end.mp3'); // Optional: pre-load
  }

  Future<void> _incrementDailyMindResetsCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(AppConstants.dailyMindResetsCountKey) ?? 0;
    await prefs.setInt(AppConstants.dailyMindResetsCountKey, currentCount + 1);
    print('Daily Mind Resets Count: ${currentCount + 1}'); // For debugging
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return; // Prevent multiple timers
    setState(() {
      _isPlaying = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isPlaying = false;
        });
        _playCompletionSound(); // Play sound when timer ends
        _incrementDailyMindResetsCount(); // Increment count when session completes
        showToast('Mind Reset Session Completed!');
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _sessionDurationSeconds;
      _isPlaying = false;
    });
  }

  Future<void> _playCompletionSound() async {
    await _audioPlayer.play(AssetSource('audio/timer_end.mp3')); // Ensure the path matches your pubspec.yaml and asset folder structure
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel timer to prevent memory leaks
    _audioPlayer.dispose(); // Dispose the audio player when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor; // Get accent color

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Daily Mind Reset', style: textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textTheme.bodyLarge?.color),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Take a moment to center yourself.',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Placeholder for guided visualization image or animation
              Icon(Icons.self_improvement, size: 100, color: accentColor), // Use accent color
              const SizedBox(height: 40),
              Text(
                _formatDuration(_remainingSeconds),
                style: textTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'playPauseBtn', // Unique tag for multiple FABs
                    onPressed: _isPlaying ? _pauseTimer : _startTimer,
                    backgroundColor: accentColor, // Use accent color
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: textTheme.labelLarge?.color),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton(
                    heroTag: 'resetBtn', // Unique tag
                    onPressed: _resetTimer,
                    backgroundColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    child: Icon(Icons.refresh, color: Theme.of(context).scaffoldBackgroundColor),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Focus on your breath. Inhale deeply, exhale slowly.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- InnerJournalScreen ---
class InnerJournalScreen extends StatefulWidget {
  const InnerJournalScreen({super.key});

  @override
  State<InnerJournalScreen> createState() => _InnerJournalScreenState();
}

class _InnerJournalScreenState extends State<InnerJournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  String? _audioPath;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
  }

  @override
  void dispose() {
    _journalController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecordingTimer() {
    _recordDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  void _stopRecordingTimer() {
    _timer?.cancel();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _recordVoiceNote() async {
    // Ask for microphone permission first
    var status = await Permission.microphone.request();

    if (status == PermissionStatus.permanentlyDenied) {
      // Show dialog to guide user to settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Microphone Permission Needed'),
          content: const Text(
              'Microphone access is permanently denied. Please enable it from app settings to record voice notes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Takes user to app settings
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    if (status != PermissionStatus.granted) {
      showToast('Microphone permission is required to record.');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.aac';

    if (!_isRecording) {
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
      );

      setState(() {
        _audioPath = path;
        _isRecording = true;
      });

      _startRecordingTimer();
    } else {
      await _recorder.stopRecorder();
      _stopRecordingTimer();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _saveJournalEntry() async {
    // Stop recording if still in progress
    if (_isRecording) {
      await _recorder.stopRecorder();
      _stopRecordingTimer();
      setState(() => _isRecording = false);
    }

    final String entryText = _journalController.text.trim();
    if (entryText.isEmpty && _audioPath == null) {
      showToast('Journal entry cannot be empty.');
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> journalEntriesJson =
        prefs.getStringList(AppConstants.journalEntriesKey) ?? [];

    final newEntry = JournalEntry(
      text: entryText,
      timestamp: DateTime.now(),
      audioPath: _audioPath,
    );

    journalEntriesJson.add(jsonEncode(newEntry.toJson()));
    await prefs.setStringList(
        AppConstants.journalEntriesKey, journalEntriesJson);

    _journalController.clear();
    setState(() {
      _audioPath = null;
      _recordDuration = Duration.zero;
    });
    showToast('Journal entry saved!');
  }

  void _discardAudioNote() {
    if (_audioPath != null) {
      File(_audioPath!).delete().catchError((_) {});
      setState(() => _audioPath = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Your Inner Journal', style: textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s on your mind today?',
              style: textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isLightMode ? Colors.grey.shade200 : Colors.grey.shade800,
                  border: Border.all(
                    color: isLightMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _journalController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Start writing here...',
                      hintStyle: textTheme.bodyLarge?.copyWith(color: textTheme.bodyLarge?.color?.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                    style: textTheme.bodyLarge,
                    cursorColor: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recording timer
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(left: 5.0, bottom: 12),
                child: Text(
                  'Recording: ${_formatDuration(_recordDuration)}',
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

            // Audio controls before save
            if (_audioPath != null && !_isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _discardAudioNote,
                      tooltip: 'Discard Audio Note',
                    ),
                    Expanded(
                      child: AudioNotePlayer(filePath: _audioPath!),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Voice note button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _recordVoiceNote,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Voice Note',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 16,
                        color: isLightMode ? Colors.white : Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textTheme.bodyLarge?.color,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Save entry button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveJournalEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Save Entry', style: textTheme.labelLarge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Existing AccountManagementScreen modified to include Edit Name option
class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor; // Get accent color

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Account Settings', style: textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAccountTile(
              context,
              title: 'Edit Name',
              icon: Icons.person_rounded,
              accentColor: accentColor, // Pass accent color
              onTap: () {
                // Navigate to the new EditNameScreen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const EditNameScreen()),
                ).then((_) {
                  // This callback runs when EditNameScreen is popped.
                  // This will trigger the HomeDashboard to refresh its name.
                  // For the current structure, we rely on HomeDashboard's
                  // initState to reload the name when it becomes active again.
                });
              },
            ),
            // Add other account management options here
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color accentColor, // Receive accent color
        VoidCallback? onTap,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentColor), // Use accent color
        title: Text(title, style: textTheme.bodyLarge),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textTheme.bodyLarge?.color?.withOpacity(0.7)),
        onTap: onTap,
      ),
    );
  }
}

// New: EditNameScreen
class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _currentName;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  Future<void> _loadCurrentName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentName = prefs.getString(AppConstants.userNameKey);
      _nameController.text = _currentName ?? ''; // Set current name to controller
    });
  }

  Future<void> _saveNewName() async {
    if (_formKey.currentState!.validate()) {
      final String newName = _nameController.text.trim();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userNameKey, newName);
      if (context.mounted) {
        showToast('Name updated successfully!');
        Navigator.of(context).pop(); // Go back to Account Management screen
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor; // Get accent color

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Your Name', style: textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your new name:',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'New Name',
                  hintText: 'e.g., Sarah',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2), // Use accent color
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveNewName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // Use accent color
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text('Save Name', style: textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New: AccentColorScreen
class AccentColorScreen extends StatelessWidget {
  const AccentColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorProvider = Provider.of<ColorProvider>(context);
    final currentAccentColorName = colorProvider.currentAccentColorName;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Change Accent Color', style: textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferred accent color:',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: AppColors.accentColors.length,
                itemBuilder: (context, index) {
                  final colorName = AppColors.accentColors.keys.elementAt(index);
                  final colorValue = AppColors.accentColors.values.elementAt(index);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Theme.of(context).cardColor,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: currentAccentColorName == colorName ? colorValue // Highlight selected with its own color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorValue,
                        radius: 16,
                      ),
                      title: Text(colorName, style: textTheme.bodyLarge),
                      trailing: currentAccentColorName == colorName ?
                      Icon(Icons.check_circle, color: colorValue) // Checkmark in its own color
                          : null,
                      onTap: () {
                        colorProvider.setAccentColor(colorName);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Privacy Policy', style: textTheme.headlineMedium)),
      body: Center(child: Text('Our privacy policy details.', style: textTheme.bodyLarge)),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Help & Support', style: textTheme.headlineMedium)),
      body: Center(child: Text('Find help resources or contact support.', style: textTheme.bodyLarge)),
    );
  }
}

// --- Home Dashboard (Screen 4) ---
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _selectedIndex = 0;
  String _userName = 'User'; // Default name

  // List of widgets for the bottom navigation bar - NOW initialized in initState
  // to ensure context is available for Provider.
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // Initialize _widgetOptions here as it doesn't strictly depend on context that changes rapidly
    _widgetOptions = <Widget>[
      const _DashboardContent(),
      const TrackProgressScreen(),
      SettingsScreen(onNameUpdated: _loadUserName), // Pass the callback here
    ];
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final newName = prefs.getString(AppConstants.userNameKey) ?? 'User';
    if (_userName != newName) { // Only update if it's different to avoid unnecessary rebuilds
      setState(() {
        _userName = newName;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Consumer widget ensures rebuilds when ColorProvider changes
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        final accentColor = colorProvider.currentAccentColor;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false, // Show welcome message only on Dashboard
            title: _selectedIndex == 0 ? Text(
              'Welcome, $_userName!',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ) : _selectedIndex == 1 ? Text(
              'Your Journal Entries',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ): _selectedIndex == 2 ? Text(
              'Settings',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ): null , // No title for other tabs in the bottom navigation
            actions: const [
              // Notifications icon removed from HomeDashboard AppBar if it's solely in settings now
              // If you want notifications to remain as a global access point, you can re-add it.
            ],
          ),
          body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes_rounded),
                label: 'Progress',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: accentColor, // Use accent color
            unselectedItemColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            onTap: _onItemTapped,
            backgroundColor: Theme.of(context).cardColor,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: textTheme.bodySmall,
            unselectedLabelStyle: textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            context,
            title: 'Daily Mind Reset',
            subtitle: 'Start your day with a clear mind.',
            icon: Icons.self_improvement,
            accentColor: accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DailyMindResetScreen()),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildCard(
            context,
            title: 'Inner Journal',
            subtitle: 'Reflect on your thoughts and feelings.',
            icon: Icons.edit_note,
            accentColor: accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InnerJournalScreen()),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildCard(
            context,
            title: 'Ask Saathi',
            subtitle: 'Chat with your mental strength coach.',
            icon: Icons.chat_bubble_outline,
            accentColor: accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AIChatScreen()),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildCard(
            context,
            title: 'Mental Modules',
            subtitle: 'Interactive drills to train your brain.',
            icon: Icons.videogame_asset,
            accentColor: accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LearningModulesScreen()),
              );
            },
          ),
          // Quick Actions section removed
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
        required String subtitle,
        required IconData icon,
        required Color accentColor,
        VoidCallback? onTap}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(25.0), // Increased padding
          child: Row(
            children: [
              Icon(icon, size: 50, color: accentColor), // Increased icon size
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 20), // Slightly larger title
                    ),
                    const SizedBox(height: 8), // Increased space
                    Text(
                      subtitle,
                      style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyLarge?.color?.withOpacity(0.7)), // Slightly larger subtitle
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 25, color: textTheme.bodyLarge?.color?.withOpacity(0.7)), // Increased arrow size
            ],
          ),
        ),
      ),
    );
  }

  // _buildQuickActionButton is no longer used, can be removed if not used elsewhere
  // but keeping it for now in case it's used by other features not shown.
  Widget _buildQuickActionButton(BuildContext context,
      {required String label,
        required IconData icon,
        required VoidCallback onTap,
        required Color accentColor}) {
    final textTheme = Theme.of(context).textTheme;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: textTheme.labelLarge?.copyWith(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}


class TrackProgressScreen extends StatefulWidget {
  const TrackProgressScreen({super.key});

  @override
  State<TrackProgressScreen> createState() => _TrackProgressScreenState();
}

class _TrackProgressScreenState extends State<TrackProgressScreen> {
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = true;
  DateTime? _selectedDate; // New state variable for selected date
  int _journalEntryCount = 0; // New state variable for journal entry count
  int _dailyMindResetsCount = 0; // New state variable for daily mind resets count

  @override
  void initState() {
    super.initState();
    _loadProgressData(); // Load all progress data
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load Journal Entries
    List<String> journalEntriesJson =
        prefs.getStringList(AppConstants.journalEntriesKey) ?? [];
    List<JournalEntry> loadedEntries = [];
    for (String jsonString in journalEntriesJson) {
      try {
        loadedEntries.add(JournalEntry.fromJson(jsonDecode(jsonString)));
      } catch (e) {
        // Log the error or print it for debugging purposes
        print('Error decoding journal entry JSON: $e, Malformed JSON: $jsonString');
        // If an entry is malformed, we skip it.
      }
    }
    // Sort entries by timestamp in descending order (newest first)
    loadedEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    // Filter entries if a date is selected
    if (_selectedDate != null) {
      loadedEntries = loadedEntries.where((entry) {
        return entry.timestamp.year == _selectedDate!.year &&
            entry.timestamp.month == _selectedDate!.month &&
            entry.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    // Load Daily Mind Resets Count
    final loadedMindResetsCount = prefs.getInt(AppConstants.dailyMindResetsCountKey) ?? 0;

    setState(() {
      _journalEntries = loadedEntries;
      _journalEntryCount = loadedEntries.length; // Update the count
      _dailyMindResetsCount = loadedMindResetsCount; // Update mind resets count
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Provider.of<ColorProvider>(context).currentAccentColor, // Use accent color
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadProgressData(); // Reload all progress data for the selected date
    }
  }

  void _clearSelectedDate() {
    setState(() {
      _selectedDate = null;
    });
    _loadProgressData(); // Reload all entries
  }

  Future<void> _deleteEntry(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this journal entry?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Provider.of<ColorProvider>(context).currentAccentColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> journalEntriesJson = prefs.getStringList(AppConstants.journalEntriesKey) ?? [];

      final entryToDelete = _journalEntries[index];
      final entryToDeleteJson = jsonEncode(entryToDelete.toJson());

      // 🗑 Delete audio file if it exists
      if (entryToDelete.audioPath != null) {
        final audioFile = File(entryToDelete.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      // Remove from stored list
      journalEntriesJson.removeWhere((jsonString) => jsonString == entryToDeleteJson);
      await prefs.setStringList(AppConstants.journalEntriesKey, journalEntriesJson);

      showToast('Journal entry deleted!');
      _loadProgressData(); // Refresh list & data
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView( // Made the entire body scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Reflect on your past entries and track your progress.',
                style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyLarge?.color?.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 10), // Reduced from 20
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: Icon(Icons.calendar_today, color: textTheme.labelLarge?.color),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter by Date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        style: textTheme.labelLarge?.copyWith(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 50, // Fixed width for the clear button
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _clearSelectedDate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero, // Remove padding to fit icon
                        ),
                        child: Icon(Icons.clear, color: Theme.of(context).scaffoldBackgroundColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildProgressCard(
                context: context,
                title: 'Journaling Consistency',
                content: 'You have written $_journalEntryCount journal entries.',
                icon: Icons.calendar_month_rounded,
                onTap: null, // Make it unclickable
                accentColor: accentColor, // Pass accentColor to the card
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildProgressCard(
                context: context,
                title: 'Mind Resets Completed',
                content: 'You have completed $_dailyMindResetsCount mind reset sessions.',
                icon: Icons.self_improvement_rounded,
                onTap: null, // Make it unclickable
                accentColor: accentColor,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                'Entries',
                style: textTheme.headlineMedium?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _journalEntries.isEmpty
                ? Padding( // Add padding for the empty state message
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Center(
                child: Text(
                  _selectedDate == null
                      ? 'No journal entries yet. Start writing in your Inner Journal!'
                      : 'No entries found for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}.',
                  style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyLarge?.color?.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true, // Crucial for nested ListView in SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Apply padding to the list items
              itemCount: _journalEntries.length,
              itemBuilder: (context, index) {
                final entry = _journalEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(entry.timestamp),
                      style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.6)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.text.isNotEmpty)
                          Text(
                            entry.text,
                            style: textTheme.bodyLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (entry.audioPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AudioNotePlayer(filePath: entry.audioPath!),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Optionally, show full journal entry
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(entry.timestamp)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry.text.isNotEmpty)
                                Text(entry.text),
                              if (entry.audioPath != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final file = File(entry.audioPath!);
                                      if (await file.exists()) {
                                        final player = AudioPlayer();
                                        await player.play(DeviceFileSource(entry.audioPath!));
                                      } else {
                                        showToast('Audio file missing.');
                                      }
                                    },
                                    icon: Icon(Icons.play_arrow, color: accentColor),
                                    label: Text('Play Voice Note', style: TextStyle(color: accentColor)),
                                  ),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Close', style: TextStyle(color: accentColor)),
                            ),
                          ],
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppColors.errorColor.withOpacity(0.8)),
                      onPressed: () => _deleteEntry(index),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required VoidCallback? onTap, // Made nullable
    required Color accentColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap, // Can now be null
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: accentColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      content,
                      style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              // Only show arrow if it's clickable
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 20, color: textTheme.bodyLarge?.color?.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
class LearningModulesScreen extends StatelessWidget {
  const LearningModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Mental Agility Drills',
        'icon': Icons.bolt,
        'emoji': '🌟',
        'description': 'Sharpen your reaction and focus skills.',
      },
      {
        'title': 'Cognitive Flexibility Games',
        'icon': Icons.extension,
        'emoji': '🧩',
        'description': 'Train your brain to adapt and switch tasks.',
      },
      {
        'title': 'Generative Storytelling',
        'icon': Icons.menu_book,
        'emoji': '📖',
        'description': 'Reflect on challenges through calming AI-generated stories.',
      },
      {
        'title': 'Name It To Reframe It',
        'icon': Icons.menu_book,
        'emoji': '📚',
        'description': 'Short 1–2 min skills: Breathing, Reframing, etc.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('🎮 Mental Modules', style: textTheme.headlineMedium),
        leading: BackButton(color: textTheme.bodyLarge?.color),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              onTap: () {
                final title = module['title'] as String;
                if (title == 'Mental Agility Drills') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentalAgilityDrillsScreen()));
                } else if (title == 'Cognitive Flexibility Games') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CognitiveFlexibilityScreen()));
                } else if (title == 'Generative Storytelling') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GenerativeStorytellingScreen()),);
                } else if (title == 'Name It To Reframe It') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NameItToReframeItScreen()));
                }
                else {
                  showToast('${module['title']} coming soon!');
                }
              },

              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Text(module['emoji'], style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module['title'],
                            style: textTheme.headlineMedium?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            module['description'],
                            style: textTheme.bodyLarge?.copyWith(
                              color: textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: accentColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onNameUpdated;
  const SettingsScreen({super.key, required this.onNameUpdated});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Provider.of<ColorProvider>(context).currentAccentColor;
    final themeProvider = Provider.of<ThemeProvider>(context);


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView( // Made the entire body scrollable
        child: Padding( // Added consistent padding here
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _buildSettingsTile(
                context,
                title: 'Account',
                icon: Icons.person_rounded,
                accentColor: accentColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AccountManagementScreen()),
                  ).then((_) => onNameUpdated()); // Trigger callback when returning
                },
              ),
              _buildSettingsTile(
                context,
                title: 'Accent Color',
                icon: Icons.color_lens_rounded,
                accentColor: accentColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AccentColorScreen()),
                  );
                },
              ),

              const SizedBox(height: 20), // Reduced from 30
              Text( // No longer needs individual Padding widget
                'Appearance',
                style: textTheme.headlineMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 15),
              _buildSettingsTile(
                context,
                title: 'Dark Mode',
                icon: Icons.dark_mode_rounded,
                accentColor: accentColor,
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: accentColor,
                  inactiveTrackColor: Colors.grey.shade400, // Visible track in light mode
                  inactiveThumbColor: Colors.grey.shade600, // Visible thumb in light mode
                ),
              ),
              const SizedBox(height: 20), // Reduced from 30
              Text( // No longer needs individual Padding widget
                'About App',
                style: textTheme.headlineMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 15),
              _buildSettingsTile(
                context,
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_rounded,
                accentColor: accentColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                title: 'Help & Support',
                icon: Icons.help_center_rounded,
                accentColor: accentColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                title: 'Rate App',
                icon: Icons.star_rate_rounded,
                accentColor: accentColor,
                onTap: () {
                  showToast('Thank you for rating us!');
                  // Implement logic to direct to app store for rating
                },
              ),
              const SizedBox(height: 20), // Reduced from 30
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // Clear all user data
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                            (Route<dynamic> route) => false,
                      );
                    }
                  },
                  child: Text('Reset App Data', style: textTheme.labelLarge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Reduced from 30
              Center(
                child: Text(
                  'Saathi v1.0.0',
                  style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)), // Using theme color
                ),
              ),
              Center(
                child: Text(
                  'By Binary Brains',
                  style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)), // Using theme color
                ),
              ),
              const SizedBox(height: 10), // Reduced from 20
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {
        required String title,
        required IconData icon,
        required Color accentColor, // Receive accent color
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentColor), // Use accent color
        title: Text(title, style: textTheme.bodyLarge),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textTheme.bodyLarge?.color?.withOpacity(0.7)),
        onTap: onTap,
      ),
    );
  }
}
