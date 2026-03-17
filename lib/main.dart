import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/ad_banner.dart';
import 'utils/ad_manager.dart';


import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/app_localizations.dart';
import 'pages/settings_page.dart';
import 'utils/purchase_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const MyApp());
}

// -----------------------------------------------------------------------------
// 1. Data Models & Helpers
// -----------------------------------------------------------------------------

class Quiz {
  final String question;
  final bool isCorrect;
  final String explanation;
  final String? imagePath;

  Quiz({
    required this.question,
    required this.isCorrect,
    required this.explanation,
    this.imagePath,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    dynamic imagePathVal = json['imagePath'];
    String? finalImagePath;
    if (imagePathVal is List) {
      if (imagePathVal.isNotEmpty) {
        finalImagePath = imagePathVal.first as String?;
      }
    } else if (imagePathVal is String) {
      finalImagePath = imagePathVal;
    }

    return Quiz(
      question: (json['question'] as String).replaceAll('\n', ''),
      isCorrect: json['isCorrect'] as bool,
      explanation: json['explanation'] as String,
      imagePath: finalImagePath,
    );
  }
}

enum QuizMode { shuffle, sequential }

class PrefsHelper {
  static const String _keyWeakQuestions = 'weak_questions';
  static const String _keyAdCounter = 'ad_counter';
  static const String _keyIsPremium = 'is_premium';

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  static Future<bool> shouldShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyAdCounter) ?? 0;
    current++;
    await prefs.setInt(_keyAdCounter, current);
    return (current % 3 == 0);
  }
  
  static Future<void> saveHighScore(String categoryKey, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(categoryKey) ?? 0;
    if (score > currentHigh) {
      await prefs.setInt(categoryKey, score);
    }
  }

  static Future<int> getHighScore(String categoryKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(categoryKey) ?? 0;
  }

  static Future<void> addWeakQuestions(List<String> questions) async {
    if (questions.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_keyWeakQuestions) ?? [];
    
    bool changed = false;
    for (final q in questions) {
      if (!current.contains(q)) {
        current.add(q);
        changed = true;
      }
    }
    
    if (changed) {
      await prefs.setStringList(_keyWeakQuestions, current);
    }
  }

  static Future<void> removeWeakQuestions(List<String> questions) async {
    if (questions.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_keyWeakQuestions) ?? [];
    
    bool changed = false;
    for (final q in questions) {
       if (current.remove(q)) {
         changed = true;
       }
    }
    
    if (changed) {
      await prefs.setStringList(_keyWeakQuestions, current);
    }
  }

  static Future<List<String>> getWeakQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyWeakQuestions) ?? [];
  }
}

class QuizData {
  static Map<String, List<Quiz>> _data = {};

  static Future<void> load(BuildContext context) async {
    try {
      final locale = Localizations.localeOf(context);
      final isSpanish = locale.languageCode == 'es';
      final fileName = isSpanish ? 'assets/quiz_data_ES.json' : 'assets/quiz_data_EN.json';
      
      final String jsonString = await rootBundle.loadString(fileName);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _data = {};
      jsonData.forEach((key, value) {
        if (value is List) {
          _data[key] = value.map((q) => Quiz.fromJson(q)).toList();
        }
      });
    } catch (e) {
      debugPrint("Error loading quiz data: $e");
      _data = {};
    }
  }

  static List<Quiz> get part1 => _data['part1'] ?? [];
  static List<Quiz> get part2 => _data['part2'] ?? [];
  static List<Quiz> get part3 => _data['part3'] ?? [];
  static List<Quiz> get part4 => _data['part4'] ?? [];


  static List<Quiz> getQuizzesFromTexts(List<String> texts) {
    final allQuizzes = [
      ...part1,
      ...part2,
      ...part3,
      ...part4,

    ];
    return allQuizzes.where((q) => texts.contains(q.question)).toList();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBC6474)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F1F2), // Chic Pink Background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFBC6474),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.loraTextTheme(Theme.of(context).textTheme),
      ),
      home: const HomePage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Home Page
// -----------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _weaknessCount = 0;
  bool _isLoading = true;
  bool _isPremium = true;
  QuizMode _quizMode = QuizMode.shuffle;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // 1. Wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    // 2. Request ATT
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    debugPrint("ATT Status: $status");

    // 3. Initialize Ads
    await MobileAds.instance.initialize();
    

    if (!await PrefsHelper.isPremium()) {
      AdManager.instance.preloadAd('home');
    }

    // 5. Init Purchase Manager
    await PurchaseManager.instance.initialize();
    PurchaseManager.instance.isPremiumNotifier.addListener(_onPremiumChanged);
    _onPremiumChanged(); // initial check

    if (context.mounted) {
      await QuizData.load(context);
    }
    await _loadUserData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPremiumChanged() {
    final val = PurchaseManager.instance.isPremiumNotifier.value;
    if (mounted) {
      setState(() {
        _isPremium = val;
      });
    }
  }

  @override
  void dispose() {
    PurchaseManager.instance.isPremiumNotifier.removeListener(_onPremiumChanged);
    super.dispose();
  }

  
  Future<void> _loadUserData() async {
    final weakList = await PrefsHelper.getWeakQuestions();
    // Filter to only include questions that exist in the current language data
    final validCount = QuizData.getQuizzesFromTexts(weakList).length;
    if (mounted) {
      setState(() {
        _weaknessCount = validCount;
      });
    }
  }

  void _startQuiz(BuildContext context, List<Quiz> quizList, String categoryKey, {bool isRandom10 = true}) async {
    List<Quiz> questionsToUse = List<Quiz>.from(quizList);
    
    if (_quizMode == QuizMode.shuffle) {
      questionsToUse.shuffle();
      if (questionsToUse.length > 10) {
        questionsToUse = questionsToUse.take(10).toList();
      }
    } else {
      // Sequential mode: Just use the list as is.
      // Already handles list length in QuizPage via totalQuestions
    }
    
    if (!_isPremium) {
      AdManager.instance.preloadAd('result');
      AdManager.instance.preloadInterstitial();
    }
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizPage(
          quizzes: questionsToUse,
          categoryKey: categoryKey,
          totalQuestions: isRandom10 ? 10 : questionsToUse.length,
        ),
      ),
    );
    if (!mounted) return;
    _loadUserData();
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Gradient
            Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Color(0xFFFFB300), size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.premiumUpgradeTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FeatureItem(
                    icon: Icons.format_list_numbered,
                    text: AppLocalizations.of(context)!.premiumFeatureSequential,
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.block,
                    text: AppLocalizations.of(context)!.premiumFeatureAds,
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.category,
                    text: AppLocalizations.of(context)!.premiumFeatureCategory,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      PurchaseManager.instance.buyPremium(null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 4,
                      shadowColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.upgradeNow,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryReviewSheet() async {
    final weakTexts = await PrefsHelper.getWeakQuestions();
    if (!mounted) return;

    // Calculate counts for each partition based on what's available in the current language
    int p1 = 0, p2 = 0, p3 = 0, p4 = 0;

    final weakSet = weakTexts.toSet();

    for (var q in QuizData.part1) { if (weakSet.contains(q.question)) p1++; }
    for (var q in QuizData.part2) { if (weakSet.contains(q.question)) p2++; }
    for (var q in QuizData.part3) { if (weakSet.contains(q.question)) p3++; }
    for (var q in QuizData.part4) { if (weakSet.contains(q.question)) p4++; }

    int totalCount = p1 + p2 + p3 + p4;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                AppLocalizations.of(context)!.whichPartToReview,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              
              // List Items
              _CategoryReviewItem(
                title: AppLocalizations.of(context)!.allCategories,
                count: totalCount,
                icon: Icons.all_inclusive,
                iconColor: Colors.blueGrey,
                onTap: () {
                  Navigator.pop(context);
                  _startWeaknessReview(null);
                },
              ),
              const Divider(height: 32),
              _CategoryReviewItem(
                title: AppLocalizations.of(context)!.part1Title,
                count: p1,
                icon: Icons.water_drop,
                iconColor: Colors.cyan,
                onTap: () {
                  Navigator.pop(context);
                  _startWeaknessReview('part1');
                },
              ),
              const SizedBox(height: 12),
              _CategoryReviewItem(
                title: AppLocalizations.of(context)!.part2Title,
                count: p2,
                icon: Icons.science,
                iconColor: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _startWeaknessReview('part2');
                },
              ),
              const SizedBox(height: 12),
              _CategoryReviewItem(
                title: AppLocalizations.of(context)!.part3Title,
                count: p3,
                icon: Icons.label,
                iconColor: Colors.purpleAccent,
                onTap: () {
                  Navigator.pop(context);
                  _startWeaknessReview('part3');
                },
              ),
              const SizedBox(height: 12),
              _CategoryReviewItem(
                title: AppLocalizations.of(context)!.part4Title,
                count: p4,
                icon: Icons.wine_bar,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _startWeaknessReview('part4');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _startWeaknessReview(String? partKey) async {
    final navigator = Navigator.of(context);
    final weakTexts = await PrefsHelper.getWeakQuestions();
    if (!mounted) return;
    if (weakTexts.isEmpty) return;

    List<Quiz> weakQuizzes = QuizData.getQuizzesFromTexts(weakTexts);
    
    // Filter by category if partKey is provided
    if (partKey != null) {
      List<Quiz> categoryQuizzes;
      switch (partKey) {
        case 'part1': categoryQuizzes = QuizData.part1; break;
        case 'part2': categoryQuizzes = QuizData.part2; break;
        case 'part3': categoryQuizzes = QuizData.part3; break;
        case 'part4': categoryQuizzes = QuizData.part4; break;
        default: categoryQuizzes = [];
      }
      
      final categoryQuestions = categoryQuizzes.map((q) => q.question).toSet();
      weakQuizzes = weakQuizzes.where((q) => categoryQuestions.contains(q.question)).toList();
    }

    if (weakQuizzes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noData)),
      );
      return;
    }

    if (!_isPremium) {
      AdManager.instance.preloadAd('result');
      AdManager.instance.preloadInterstitial();
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (context) => QuizPage(
          quizzes: weakQuizzes,
          isWeaknessReview: true,
          totalQuestions: weakQuizzes.length,
        ),
      ),
    );
    if (!mounted) return;
    _loadUserData();
  }

  void _startQuizByCategory(BuildContext context, String partKey) {
    List<Quiz> quizzes;
    String highScoreKey;
    switch(partKey) {
      case 'part1': quizzes = QuizData.part1; highScoreKey = 'highscore_part1'; break;
      case 'part2': quizzes = QuizData.part2; highScoreKey = 'highscore_part2'; break;
      case 'part3': quizzes = QuizData.part3; highScoreKey = 'highscore_part3'; break;
      case 'part4': quizzes = QuizData.part4; highScoreKey = 'highscore_part4'; break;

      default: quizzes = []; highScoreKey = '';
    }
    
    if (quizzes.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.noData)),
       );
       return;
    }
    _startQuiz(context, quizzes, highScoreKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.homeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => const SettingsPage()),
               );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // 1. Mode Toggle
                  Center(
                    child: PillToggle(
                      currentMode: _quizMode,
                      isPremium: _isPremium,
                      onModeChanged: (mode) {
                        setState(() {
                          _quizMode = mode;
                        });
                      },
                      onLockedTap: _showPremiumDialog,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    AppLocalizations.of(context)!.homeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Part 1
                  _MenuButton(
                    title: AppLocalizations.of(context)!.part1Title,
                    icon: Icons.water_drop,
                    iconColor: Colors.cyan,
                    onTap: () => _startQuizByCategory(context, 'part1'),
                  ),
                  const SizedBox(height: 16),

                  // Part 2
                  _MenuButton(
                    title: AppLocalizations.of(context)!.part2Title,
                    icon: Icons.science,
                    iconColor: Colors.teal,
                    onTap: () => _startQuizByCategory(context, 'part2'),
                  ),
                  const SizedBox(height: 16),

                  // Part 3
                  _MenuButton(
                    title: AppLocalizations.of(context)!.part3Title,
                    icon: Icons.label,
                    iconColor: Colors.purpleAccent,
                    onTap: () => _startQuizByCategory(context, 'part3'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Part 4
                  _MenuButton(
                    title: AppLocalizations.of(context)!.part4Title,
                    icon: Icons.wine_bar,
                    iconColor: Colors.orange,
                    onTap: () => _startQuizByCategory(context, 'part4'),
                  ),
                  const SizedBox(height: 40),

                  // Weakness Review
                  ElevatedButton.icon(
                    onPressed: _weaknessCount > 0 ? _showCategoryReviewSheet : null,
                    icon: const Icon(Icons.refresh),
                    label: Text("${AppLocalizations.of(context)!.reviewWeakness} ($_weaknessCount)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sister App Promotion
                  _buildSisterAppPromo(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSisterAppPromo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSisterAppDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/sister_app_icon.jpg',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.sisterAppTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.sisterAppSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.launch, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSisterAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/sister_app_icon.jpg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.sisterAppPopupTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.sisterAppPopupBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse('https://apps.apple.com/app/id6757799033');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.open, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLocked;

  const _MenuButton({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock : Icons.chevron_right, 
                  color: isLocked ? Colors.grey : Colors.grey[400]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PillToggle extends StatelessWidget {
  final QuizMode currentMode;
  final ValueChanged<QuizMode> onModeChanged;
  final bool isPremium;
  final VoidCallback onLockedTap;

  const PillToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.isPremium,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: currentMode == QuizMode.shuffle
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 100,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(QuizMode.shuffle),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Icon(
                      Icons.shuffle,
                      color: currentMode == QuizMode.shuffle
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isPremium) {
                      onModeChanged(QuizMode.sequential);
                    } else {
                      onLockedTap();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: currentMode == QuizMode.sequential
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        if (!isPremium)
                          Icon(
                            Icons.lock,
                            size: 32,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.orange, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _CategoryReviewItem extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryReviewItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.questionCount(count.toString()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// 3. Quiz Page
// -----------------------------------------------------------------------------

class QuizPage extends StatefulWidget {
  final List<Quiz> quizzes;
  final String? categoryKey;
  final bool isWeaknessReview;
  final int totalQuestions;

  const QuizPage({
    super.key,
    required this.quizzes,
    this.categoryKey,
    this.isWeaknessReview = false,
    required this.totalQuestions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final AppinioSwiperController controller = AppinioSwiperController();
  
  int _score = 0;
  int _currentIndex = 1;
  final List<Quiz> _incorrectQuizzes = [];
  final List<Quiz> _correctQuizzesInReview = [];
  final List<Map<String, dynamic>> _answerHistory = [];
  Color _backgroundColor = const Color(0xFFF9F1F2);

  void _handleSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      final quiz = widget.quizzes[previousIndex];
      bool userVal = (activity.direction == AxisDirection.right);
      bool isCorrect = (userVal == quiz.isCorrect);

      _answerHistory.add({
        'quiz': quiz,
        'result': isCorrect,
      });

      setState(() {
        if (isCorrect) {
          _score++;
          _backgroundColor = Colors.green.withValues(alpha: 0.2);
          HapticFeedback.lightImpact();
          
          if (widget.isWeaknessReview) {
            _correctQuizzesInReview.add(quiz);
          }
        } else {
          _backgroundColor = Colors.red.withValues(alpha: 0.2);
          _incorrectQuizzes.add(quiz);
          HapticFeedback.heavyImpact();
        }
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _backgroundColor = const Color(0xFFF9F1F2);
          });
        }
      });

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 600),
          content: Text(
            isCorrect ? AppLocalizations.of(context)!.correct : AppLocalizations.of(context)!.incorrect,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD64545),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.5,
            left: 50,
            right: 50,
          ),
        ),
      );

      setState(() {
        if (_currentIndex < widget.totalQuestions) {
          _currentIndex++;
        }
      });

      if (previousIndex == widget.quizzes.length - 1) {
        _finishQuiz();
      }
    }
  }

  Future<void> _finishQuiz() async {
    if (widget.categoryKey != null) {
      await PrefsHelper.saveHighScore(widget.categoryKey!, _score);
    }

    if (_incorrectQuizzes.isNotEmpty) {
      final incorrectTexts = _incorrectQuizzes.map((q) => q.question).toList();
      await PrefsHelper.addWeakQuestions(incorrectTexts);
    }

    if (widget.isWeaknessReview && _correctQuizzesInReview.isNotEmpty) {
      final correctTexts = _correctQuizzesInReview.map((q) => q.question).toList();
      await PrefsHelper.removeWeakQuestions(correctTexts);
    }
    
    if (mounted) {
      final isPremium = PurchaseManager.instance.isPremiumNotifier.value;
      if (isPremium) {
        _navigateToResult();
        return;
      }

      final shouldShow = await PrefsHelper.shouldShowInterstitial();
      
      if (shouldShow) {
        AdManager.instance.showInterstitial(
          onComplete: () {
            if (mounted) {
              _navigateToResult();
            }
          },
        );
      } else {
        _navigateToResult();
      }
    }
  }

  void _navigateToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultPage(
          score: _score,
          total: widget.quizzes.length,
          history: _answerHistory,
          incorrectQuizzes: _incorrectQuizzes,
          originalQuizzes: widget.quizzes,
          categoryKey: widget.categoryKey,
          isWeaknessReview: widget.isWeaknessReview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppLocalizations.of(context)!.questionLabel} $_currentIndex",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "$_currentIndex / ${widget.totalQuestions}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _currentIndex / widget.totalQuestions,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              Expanded(
                child: AppinioSwiper(
                  controller: controller,
                  cardCount: widget.quizzes.length,
                  loop: false,
                  backgroundCardCount: 2,
                  swipeOptions: const SwipeOptions.symmetric(horizontal: true, vertical: false),
                  onSwipeEnd: _handleSwipeEnd,
                  cardBuilder: (context, index) {
                    return _buildCard(widget.quizzes[index]);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.unswipe();
                        setState(() {
                          if (_currentIndex > 1) {
                            _currentIndex--;
                          }
                          if (_answerHistory.isNotEmpty) {
                            final last = _answerHistory.removeLast();
                            final bool wasCorrect = last['result'];
                            final Quiz quiz = last['quiz'];
                            
                            if (wasCorrect) {
                              _score--;
                              if (widget.isWeaknessReview) {
                                _correctQuizzesInReview.remove(quiz);
                              }
                            } else {
                              _incorrectQuizzes.remove(quiz);
                            }
                          }
                        });
                      },
                      icon: const Icon(Icons.undo, size: 20),
                      label:  Text(AppLocalizations.of(context)!.retry),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Ad Banner at the bottom of QuizPage
              ValueListenableBuilder<bool>(
                valueListenable: PurchaseManager.instance.isPremiumNotifier,
                builder: (context, isPremium, child) {
                  if (isPremium) return const SizedBox.shrink();
                  return const SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 50,
                      child: AdBanner(adKey: 'quiz'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Quiz quiz) {
    bool hasImage = quiz.imagePath != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage) 
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Image.asset(
                  quiz.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text("Image not found", style: TextStyle(color: Colors.grey[600])),
                      ],
                    );
                  },
                ),
              ),
            )
          else 
            const SizedBox(height: 24),

          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Q.",
                    style: TextStyle(
                      fontSize: hasImage ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFBC6474),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AutoSizeText(
                      quiz.question,
                      style: TextStyle(
                        fontSize: hasImage ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                      minFontSize: 14,
                      maxLines: 20,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.close, color: const Color(0xFFD64545).withValues(alpha: 0.8), size: 44),
                Icon(Icons.check, color: const Color(0xFF2E7D32).withValues(alpha: 0.8), size: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Result Page
// -----------------------------------------------------------------------------

class ResultPage extends StatelessWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> history;
  final List<Quiz> incorrectQuizzes;
  final List<Quiz> originalQuizzes;
  final String? categoryKey;
  final bool isWeaknessReview;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.history,
    required this.incorrectQuizzes,
    required this.originalQuizzes,
    this.categoryKey,
    required this.isWeaknessReview,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea( // 1. SafeArea内
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. 上部エリア
            // -----------------------------------------------------------------
            const AdBanner(adKey: 'result'), // 一番上に広告バナー

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32), // 角丸32px
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        AppLocalizations.of(context)!.scoreLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$score/$total", // 9/10
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  if (score == total)
                    Text(
                      AppLocalizations.of(context)!.perfectMessage,
                      style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      score >= (total * 0.8) ? AppLocalizations.of(context)!.passMessage : AppLocalizations.of(context)!.failMessage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: score >= (total * 0.8) ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // 2. 中央エリア（スクロール可能なリスト）
            // -----------------------------------------------------------------
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final Quiz quiz = item['quiz'];
                  final bool isCorrect = item['result'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // 角丸16px
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quiz.question,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (quiz.imagePath != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.image, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.imageQuestion, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.05), // 薄い青灰色
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "💡 ${quiz.explanation}",
                              style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // -----------------------------------------------------------------
            // 3. 下部エリア（固定フッター）
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF9F9F9),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 左ボタン: 「ミスを確認」 (全問正解時は非表示)
                      if (incorrectQuizzes.isNotEmpty) ...[
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => QuizPage(
                                      quizzes: incorrectQuizzes,
                                      isWeaknessReview: true,
                                      totalQuestions: incorrectQuizzes.length,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(AppLocalizations.of(context)!.reviewMistakes),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Right Button: Retry or Home
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isWeaknessReview) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                return;
                              }

                              final shuffledAgain = List<Quiz>.from(originalQuizzes)..shuffle();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => QuizPage(
                                    quizzes: shuffledAgain,
                                    categoryKey: categoryKey,
                                    totalQuestions: shuffledAgain.length,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              elevation: 0,
                              side: const BorderSide(color: Colors.blueAccent, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: Text(isWeaknessReview ? AppLocalizations.of(context)!.backToHome : AppLocalizations.of(context)!.retry),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  
                  // Back to home link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(AppLocalizations.of(context)!.backToHome, style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
