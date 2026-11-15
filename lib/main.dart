import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

// ============================================================================
// CONSTANTS (Fixed - Not editable)
// ============================================================================
const String kDevName = 'YOSSEF JOO';
const String kDevWhatsapp = '01029892573';
const String kAppName = 'DOViD';
const String kApiEndpoint = 'https://zecora0.serv00.net/download/download.php';
const String kApiPrice = '100';
const String kAdminEmail = 'guhfyuggu7@gmail.com';
const String kAdminUsername = 'admin';
const String kAdminPassword = 'guhfyuggu7@855A';

// ============================================================================
// THEME COLORS
// ============================================================================
class AppColors {
  static const primary = Color(0xFFF97316);
  static const primaryDark = Color(0xFFEA580C);
  static const secondary = Color(0xFFEF4444);
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0F0F1A);
  static const surfaceLight = Color(0xFF1A1A2E);
  static const surfaceLighter = Color(0xFF252540);
  static const border = Color(0x0DFFFFFF);
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const textDim = Color(0xFF64748B);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const admin = Color(0xFF8B5CF6);
  static const guest = Color(0xFF06B6D4);
  static const api = Color(0xFFF59E0B);
}

// ============================================================================
// MODELS
// ============================================================================
class AppUser {
  final String id;
  final String username;
  final String passwordHash;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;
  DateTime? lastLogin;

  AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.email = '',
    this.isAdmin = false,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'email': email,
        'isAdmin': isAdmin,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] ?? '',
        username: j['username'] ?? '',
        passwordHash: j['passwordHash'] ?? '',
        email: j['email'] ?? '',
        isAdmin: j['isAdmin'] ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        lastLogin: j['lastLogin'] != null ? DateTime.tryParse(j['lastLogin']) : null,
      );
}

class DownloadEntry {
  final String id;
  final String userId;
  final String url;
  String title;
  String platform;
  String downloadLink;
  String quality;
  String status;
  String strategy;
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadEntry({
    required this.id,
    required this.userId,
    required this.url,
    this.title = '',
    this.platform = 'unknown',
    this.downloadLink = '',
    this.quality = 'auto',
    this.status = 'pending',
    this.strategy = '',
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'url': url,
        'title': title,
        'platform': platform,
        'downloadLink': downloadLink,
        'quality': quality,
        'status': status,
        'strategy': strategy,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> j) => DownloadEntry(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        url: j['url'] ?? '',
        title: j['title'] ?? '',
        platform: j['platform'] ?? 'unknown',
        downloadLink: j['downloadLink'] ?? '',
        quality: j['quality'] ?? 'auto',
        status: j['status'] ?? 'pending',
        strategy: j['strategy'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        completedAt: j['completedAt'] != null ? DateTime.tryParse(j['completedAt']) : null,
      );
}

class ApiKey {
  final String id;
  final String userId;
  final String apiKey;
  final String apiSecret;
  String status;
  DateTime? subscriptionStart;
  DateTime? subscriptionEnd;
  int totalRequests;
  final DateTime createdAt;

  ApiKey({
    required this.id,
    required this.userId,
    required this.apiKey,
    required this.apiSecret,
    this.status = 'active',
    this.subscriptionStart,
    this.subscriptionEnd,
    this.totalRequests = 0,
    required this.createdAt,
  });

  int get daysLeft {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff ~/ 86400 : 0;
  }

  int get hoursLeft {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? (diff % 86400) ~/ 3600 : 0;
  }

  bool get isActive =>
      status == 'active' && (subscriptionEnd?.isAfter(DateTime.now()) ?? false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'status': status,
        'subscriptionStart': subscriptionStart?.toIso8601String(),
        'subscriptionEnd': subscriptionEnd?.toIso8601String(),
        'totalRequests': totalRequests,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ApiKey.fromJson(Map<String, dynamic> j) => ApiKey(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        apiKey: j['apiKey'] ?? '',
        apiSecret: j['apiSecret'] ?? '',
        status: j['status'] ?? 'active',
        subscriptionStart: j['subscriptionStart'] != null
            ? DateTime.tryParse(j['subscriptionStart'])
            : null,
        subscriptionEnd: j['subscriptionEnd'] != null
            ? DateTime.tryParse(j['subscriptionEnd'])
            : null,
        totalRequests: j['totalRequests'] ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class SubscriptionCode {
  final String id;
  final String code;
  final int durationDays;
  String status;
  String? usedBy;
  DateTime? usedAt;
  final DateTime createdAt;

  SubscriptionCode({
    required this.id,
    required this.code,
    this.durationDays = 30,
    this.status = 'active',
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'durationDays': durationDays,
        'status': status,
        'usedBy': usedBy,
        'usedAt': usedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SubscriptionCode.fromJson(Map<String, dynamic> j) => SubscriptionCode(
        id: j['id'] ?? '',
        code: j['code'] ?? '',
        durationDays: j['durationDays'] ?? 30,
        status: j['status'] ?? 'active',
        usedBy: j['usedBy'],
        usedAt: j['usedAt'] != null ? DateTime.tryParse(j['usedAt']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

// ============================================================================
// APP STATE (Singleton)
// ============================================================================
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  SharedPreferences? _prefs;

  AppUser? currentUser;
  bool isGuest = false;
  bool initialized = false;

  List<AppUser> users = [];
  List<DownloadEntry> downloads = [];
  List<ApiKey> apiKeys = [];
  List<SubscriptionCode> codes = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();

    // Create admin if not exists
    if (!users.any((u) => u.username == kAdminUsername)) {
      users.add(AppUser(
        id: _genId(),
        username: kAdminUsername,
        passwordHash: _hash(kAdminPassword),
        email: kAdminEmail,
        isAdmin: true,
        createdAt: DateTime.now(),
      ));
      await _saveUsers();
    }

    // Restore session
    final uid = _prefs!.getString('current_user_id');
    if (uid != null) {
      currentUser = users.where((u) => u.id == uid).firstOrNull;
    }
    isGuest = _prefs!.getBool('guest_mode') ?? false;

    initialized = true;
    notifyListeners();
  }

  void _loadData() {
    final u = _prefs!.getString('users');
    if (u != null) {
      users = (jsonDecode(u) as List)
          .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final d = _prefs!.getString('downloads');
    if (d != null) {
      downloads = (jsonDecode(d) as List)
          .map((e) => DownloadEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final a = _prefs!.getString('api_keys');
    if (a != null) {
      apiKeys = (jsonDecode(a) as List)
          .map((e) => ApiKey.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final c = _prefs!.getString('codes');
    if (c != null) {
      codes = (jsonDecode(c) as List)
          .map((e) => SubscriptionCode.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> _saveUsers() async {
    await _prefs?.setString(
      'users',
      jsonEncode(users.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveDownloads() async {
    await _prefs?.setString(
      'downloads',
      jsonEncode(downloads.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveApiKeys() async {
    await _prefs?.setString(
      'api_keys',
      jsonEncode(apiKeys.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveCodes() async {
    await _prefs?.setString(
      'codes',
      jsonEncode(codes.map((e) => e.toJson()).toList()),
    );
  }

  // ============ AUTH ============
  String _hash(String password) =>
      base64Url.encode(utf8.encode('dovid_salt_${password}_v4'));

  String _genId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  String? login(String username, String password) {
    final user = users.where((u) => u.username == username).firstOrNull;
    if (user == null) return 'اسم المستخدم غير موجود';
    if (user.passwordHash != _hash(password)) return 'كلمة المرور غير صحيحة';
    user.lastLogin = DateTime.now();
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    notifyListeners();
    return null;
  }

  String? register(String username, String password) {
    if (username.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (password.length < 4) {
      return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
    }
    if (users.any((u) => u.username == username)) {
      return 'اسم المستخدم مستخدم بالفعل';
    }
    final user = AppUser(
      id: _genId(),
      username: username,
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    users.add(user);
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    notifyListeners();
    return null;
  }

  void loginAsGuest() {
    isGuest = true;
    currentUser = null;
    _prefs?.remove('current_user_id');
    _prefs?.setBool('guest_mode', true);
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    isGuest = false;
    _prefs?.remove('current_user_id');
    _prefs?.setBool('guest_mode', false);
    notifyListeners();
  }

  // ============ DOWNLOADS ============
  List<DownloadEntry> get myDownloads {
    if (currentUser == null) return [];
    final list =
        downloads.where((d) => d.userId == currentUser!.id).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get totalDownloads => myDownloads.length;
  int get successDownloads =>
      myDownloads.where((d) => d.status == 'success').length;
  int get failedDownloads =>
      myDownloads.where((d) => d.status == 'failed').length;

  Future<DownloadEntry> addDownload(String url, String quality) async {
    final entry = DownloadEntry(
      id: _genId(),
      userId: currentUser?.id ?? 'guest',
      url: url,
      quality: quality,
      platform: detectPlatform(url),
      status: 'processing',
      createdAt: DateTime.now(),
    );
    downloads.insert(0, entry);
    await _saveDownloads();
    notifyListeners();
    return entry;
  }

  Future<void> updateDownload(
    DownloadEntry entry, {
    String? title,
    String? link,
    String? status,
    String? strategy,
  }) async {
    if (title != null) entry.title = title;
    if (link != null) entry.downloadLink = link;
    if (status != null) entry.status = status;
    if (strategy != null) entry.strategy = strategy;
    if (status == 'success' || status == 'failed') {
      entry.completedAt = DateTime.now();
    }
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> clearMyHistory() async {
    if (currentUser == null) return;
    downloads.removeWhere((d) => d.userId == currentUser!.id);
    await _saveDownloads();
    notifyListeners();
  }

  // ============ API KEYS / SUBSCRIPTION ============
  ApiKey? get myApiKey {
    if (currentUser == null) return null;
    final mine =
        apiKeys.where((k) => k.userId == currentUser!.id).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine.first;
  }

  String? activateCode(String code) {
    if (currentUser == null) return 'يجب تسجيل الدخول أولاً';
    final c = codes
        .where((x) => x.code == code && x.status == 'active')
        .firstOrNull;
    if (c == null) return 'كود غير صالح أو مستخدم بالفعل';

    c.status = 'used';
    c.usedBy = currentUser!.id;
    c.usedAt = DateTime.now();

    final now = DateTime.now();
    final end = now.add(Duration(days: c.durationDays));
    final key = ApiKey(
      id: _genId(),
      userId: currentUser!.id,
      apiKey: 'dv_${_randomHex(16)}',
      apiSecret: _randomHex(32),
      subscriptionStart: now,
      subscriptionEnd: end,
      createdAt: now,
    );
    apiKeys.add(key);
    _saveApiKeys();
    _saveCodes();
    notifyListeners();
    return null;
  }

  // ============ ADMIN ============
  List<DownloadEntry> get allDownloads {
    final list = List<DownloadEntry>.from(downloads);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void generateCodes(int count, int days) {
    for (int i = 0; i < count; i++) {
      codes.add(SubscriptionCode(
        id: _genId(),
        code: 'DOViD-${_randomHex(6).toUpperCase()}',
        durationDays: days,
        createdAt: DateTime.now(),
      ));
    }
    _saveCodes();
    notifyListeners();
  }

  void deleteCode(String id) {
    codes.removeWhere((c) => c.id == id);
    _saveCodes();
    notifyListeners();
  }

  void deleteUser(String id) {
    if (currentUser?.id == id) return;
    users.removeWhere((u) => u.id == id && !u.isAdmin);
    downloads.removeWhere((d) => d.userId == id);
    apiKeys.removeWhere((k) => k.userId == id);
    _saveUsers();
    _saveDownloads();
    _saveApiKeys();
    notifyListeners();
  }

  String _randomHex(int length) {
    final r = Random.secure();
    return List.generate(
      length,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

// ============================================================================
// UTILS
// ============================================================================
String detectPlatform(String url) {
  final u = url.toLowerCase();
  if (u.contains('youtube.com') || u.contains('youtu.be')) return 'youtube';
  if (u.contains('instagram.com')) return 'instagram';
  if (u.contains('tiktok.com')) return 'tiktok';
  if (u.contains('facebook.com') || u.contains('fb.watch')) return 'facebook';
  if (u.contains('twitter.com') || u.contains('x.com')) return 'twitter';
  if (u.contains('vimeo.com')) return 'vimeo';
  if (u.contains('dailymotion.com')) return 'dailymotion';
  return 'unknown';
}

IconData platformIcon(String p) {
  switch (p) {
    case 'youtube':
      return Icons.play_circle_fill;
    case 'instagram':
      return Icons.camera_alt;
    case 'tiktok':
      return Icons.music_note;
    case 'facebook':
      return Icons.facebook;
    case 'twitter':
      return Icons.alternate_email;
    case 'vimeo':
      return Icons.videocam;
    case 'dailymotion':
      return Icons.play_arrow;
    default:
      return Icons.video_file;
  }
}

Color platformColor(String p) {
  switch (p) {
    case 'youtube':
      return const Color(0xFFFF0000);
    case 'instagram':
      return const Color(0xFFE4405F);
    case 'tiktok':
      return Colors.white;
    case 'facebook':
      return const Color(0xFF1877F2);
    case 'twitter':
      return const Color(0xFF1DA1F2);
    case 'vimeo':
      return const Color(0xFF1AB7EA);
    case 'dailymotion':
      return const Color(0xFF00AAFF);
    default:
      return AppColors.primary;
  }
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return '${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return '${diff.inHours} ساعة';
  if (diff.inDays < 7) return '${diff.inDays} يوم';
  return DateFormat('yyyy-MM-dd').format(dt);
}

// ============================================================================
// API SERVICE
// ============================================================================
class DownloadService {
  static Future<Map<String, dynamic>> download(String url) async {
    final strategies = <String, Future<Map<String, dynamic>?> Function(String)>{
      'direct_post_json': _directPostJson,
      'direct_post_form': _directPostForm,
      'allorigins_proxy': _alloriginsProxy,
      'corsproxy': _corsproxy,
    };

    for (final entry in strategies.entries) {
      try {
        final result = await entry.value(url);
        if (result != null &&
            result['status'] == 'success' &&
            (result['answer'] ?? '').toString().isNotEmpty) {
          result['strategy'] = entry.key;
          return result;
        }
      } catch (_) {}
    }
    return {
      'status': 'error',
      'message': 'فشلت جميع المحاولات. تأكد من الرابط وحاول لاحقاً.',
    };
  }

  static Future<Map<String, dynamic>?> _directPostJson(String url) async {
    try {
      final res = await http.post(
        Uri.parse(kApiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': url}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _directPostForm(String url) async {
    try {
      final res = await http.post(
        Uri.parse(kApiEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': url},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsProxy(String url) async {
    try {
      final proxy =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http.post(
        Uri.parse(proxy),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': url}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _corsproxy(String url) async {
    try {
      final proxy = 'https://corsproxy.io/?${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http.post(
        Uri.parse(proxy),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': url}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }
}

// ============================================================================
// MAIN APP
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().init();
  runApp(const DOViDApp());
}

class DOViDApp extends StatelessWidget {
  const DOViDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOViD - $kDevName',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        fontFamily: 'Tajawal',
      ),
      home: const RootScreen(),
    );
  }
}

// ============================================================================
// ROOT SCREEN (Auth gate)
// ============================================================================
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final s = AppState();
        if (!s.initialized) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (s.currentUser == null && !s.isGuest) {
          return const AuthScreen();
        }
        return const MainScreen();
      },
    );
  }
}

// ============================================================================
// AUTH SCREEN
// ============================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? error;
  bool loading = false;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      error = null;
      loading = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    final s = AppState();
    final err = isRegister
        ? s.register(userCtrl.text.trim(), passCtrl.text)
        : s.login(userCtrl.text.trim(), passCtrl.text);
    if (!mounted) return;
    setState(() {
      error = err;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _AnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66F97316),
                            blurRadius: 40,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'DV',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Colors.white, AppColors.primary],
                      ).createShader(b),
                      child: Text(
                        isRegister ? 'إنشاء حساب' : 'تسجيل الدخول',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'DOViD - تنزيل الفيديوهات بذكاء',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    if (error != null) _ErrorBanner(message: error!),
                    _AuthField(
                      controller: userCtrl,
                      icon: Icons.person,
                      hint: 'اسم المستخدم',
                    ),
                    const SizedBox(height: 12),
                    _AuthField(
                      controller: passCtrl,
                      icon: Icons.lock,
                      hint: 'كلمة المرور',
                      obscure: true,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isRegister ? 'إنشاء الحساب' : 'تسجيل الدخول',
                      icon: isRegister ? Icons.person_add : Icons.login,
                      loading: loading,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 14),
                    Row(children: const [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'أو',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => AppState().loginAsGuest(),
                        icon: const Icon(Icons.person_outline,
                            color: AppColors.guest),
                        label: const Text(
                          'متابعة كزائر',
                          style: TextStyle(
                            color: AppColors.guest,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.guest),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => isRegister = !isRegister),
                      child: Text(
                        isRegister
                            ? 'لديك حساب؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ سجّل الآن',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    const Text(
                      'Powered by $kDevName',
                      style: TextStyle(fontSize: 11, color: AppColors.textDim),
                    ),
                    const Text(
                      '📞 $kDevWhatsapp',
                      style: TextStyle(fontSize: 10, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;

  const _AuthField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55F97316),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN (with bottom nav)
// ============================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final s = AppState();
        final isAdmin = s.currentUser?.isAdmin ?? false;

        final pages = <Widget>[
          const HomeScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
          if (isAdmin) const AdminScreen(),
        ];
        final items = <_NavItem>[
          _NavItem(Icons.home_rounded, 'الرئيسية'),
          _NavItem(Icons.history_rounded, 'السجل'),
          _NavItem(Icons.settings_rounded, 'الإعدادات'),
          if (isAdmin)
            _NavItem(Icons.admin_panel_settings_rounded, 'الأدمن', admin: true),
        ];

        if (_tab >= pages.length) _tab = 0;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              const _AnimatedBackground(),
              SafeArea(child: IndexedStack(index: _tab, children: pages)),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.9),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    final active = i == _tab;
                    final color =
                        it.admin ? AppColors.admin : AppColors.primary;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tab = i),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                it.icon,
                                size: 22,
                                color: active ? color : AppColors.textMuted,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                it.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      active ? color : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool admin;
  _NavItem(this.icon, this.label, {this.admin = false});
}

// ============================================================================
// ANIMATED BACKGROUND
// ============================================================================
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * pi;
        return Stack(children: [
          Container(color: AppColors.bg),
          Positioned(
            top: -200 + sin(t) * 40,
            right: -150 + cos(t) * 40,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x22F97316), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150 + cos(t) * 30,
            left: -150 + sin(t) * 30,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x15EF4444), Colors.transparent],
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

// ============================================================================
// HOME SCREEN
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final urlCtrl = TextEditingController();
  String quality = 'auto';
  bool loading = false;
  String? error;
  DownloadEntry? result;
  String loadingText = 'جاري الاتصال بالسيرفر...';

  final qualities = const [
    {'key': 'auto', 'label': 'تلقائي', 'icon': Icons.auto_awesome},
    {'key': '4k', 'label': '4K', 'icon': Icons.star},
    {'key': '1080', 'label': 'FHD', 'icon': Icons.tv},
    {'key': '720', 'label': 'HD', 'icon': Icons.phone_android},
    {'key': 'audio', 'label': 'صوت', 'icon': Icons.music_note},
  ];

  @override
  void dispose() {
    urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final url = urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => error = 'يرجى إدخال رابط الفيديو');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => error = 'الرابط غير صالح');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    final s = AppState();
    final entry = await s.addDownload(url, quality);

    final msgs = [
      'جاري الاتصال بالسيرفر...',
      'محاولة الاستخراج...',
      'معالجة الرابط...',
      'استخراج رابط التحميل...',
    ];
    int i = 0;
    final timer = Stream.periodic(const Duration(milliseconds: 1200)).listen((_) {
      if (!mounted) return;
      i = (i + 1) % msgs.length;
      setState(() => loadingText = msgs[i]);
    });

    final response = await DownloadService.download(url);
    timer.cancel();

    if (!mounted) return;

    if (response['status'] == 'success') {
      final link = (response['answer'] ?? response['url'] ?? '').toString();
      final title = (response['title'] ?? 'فيديو ${entry.platform}').toString();
      final strategy = (response['strategy'] ?? 'direct').toString();
      await s.updateDownload(
        entry,
        title: title,
        link: link,
        status: 'success',
        strategy: strategy,
      );
      if (!mounted) return;
      setState(() {
        result = entry;
        loading = false;
      });
    } else {
      await s.updateDownload(entry, status: 'failed');
      if (!mounted) return;
      setState(() {
        loading = false;
        error = (response['message'] ?? 'فشل جلب الرابط، حاول مرة أخرى')
            .toString();
      });
    }
  }

  Future<void> _open(DownloadEntry e) async {
    final uri = Uri.tryParse(e.downloadLink);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الرابط'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _AppHeader(),
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: 'الإجمالي',
                  value: s.totalDownloads,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'ناجح',
                  value: s.successDownloads,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'فاشل',
                  value: s.failedDownloads,
                  color: AppColors.error,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: AppColors.primary, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DOViD Pro',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'الصق رابط الفيديو هنا...',
                      hintStyle: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.link,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      suffixIcon: urlCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() {
                                urlCtrl.clear();
                                result = null;
                                error = null;
                              }),
                            ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: qualities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final q = qualities[i];
                        final active = quality == q['key'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => quality = q['key'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: active
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.secondary,
                                        AppColors.primary,
                                      ],
                                    )
                                  : null,
                              color: active ? null : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                              boxShadow: active
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x55F97316),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  q['icon'] as IconData,
                                  size: 12,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  q['label'] as String,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: loading ? null : _download,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55F97316),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: loading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'جاري المعالجة...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'تحميل الفيديو الآن',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loadingText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  if (result != null && result!.downloadLink.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ResultCard(entry: result!, onOpen: () => _open(result!)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المنصات المدعومة',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _PlatformIcon(
                        Icons.play_circle_fill,
                        Color(0xFFFF0000),
                        'YouTube',
                      ),
                      _PlatformIcon(
                        Icons.camera_alt,
                        Color(0xFFE4405F),
                        'Instagram',
                      ),
                      _PlatformIcon(Icons.music_note, Colors.white, 'TikTok'),
                      _PlatformIcon(
                        Icons.facebook,
                        Color(0xFF1877F2),
                        'Facebook',
                      ),
                      _PlatformIcon(
                        Icons.alternate_email,
                        Color(0xFF1DA1F2),
                        'X',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (s.myDownloads.isNotEmpty) _RecentDownloads(),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final DownloadEntry entry;
  final VoidCallback onOpen;

  const _ResultCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'تم جلب الرابط بنجاح!',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            entry.title.isEmpty ? 'فيديو ${entry.platform}' : entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 10, children: [
            _Tag(Icons.video_file, entry.platform, AppColors.primary),
            _Tag(Icons.diamond, entry.quality, AppColors.success),
            _Tag(Icons.route, entry.strategy, AppColors.textMuted),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.download, size: 16, color: Colors.black),
                label: const Text(
                  'تنزيل الملف',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.downloadLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الرابط'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('نسخ', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Tag(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 3),
      Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final badgeColor = s.currentUser?.isAdmin == true
        ? AppColors.admin
        : s.isGuest
            ? AppColors.guest
            : AppColors.primary;
    final badgeIcon = s.currentUser?.isAdmin == true
        ? Icons.shield
        : s.isGuest
            ? Icons.person_outline
            : Icons.person;
    final label = s.currentUser?.isAdmin == true
        ? '${s.currentUser!.username} (Admin)'
        : s.isGuest
            ? 'زائر'
            : (s.currentUser?.username ?? '');

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            border: Border.all(color: badgeColor.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(badgeIcon, size: 12, color: badgeColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66F97316),
                blurRadius: 40,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'DV',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, AppColors.primary],
          ).createShader(b),
          child: const Text(
            'DOViD',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'YOSSEF VID',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [color, color.withOpacity(0.6)],
          ).createShader(b),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;

  const _PlatformIcon(this.icon, this.color, this.name);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 4),
      Text(
        name,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

class _RecentDownloads extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final recent = s.myDownloads.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.history, color: AppColors.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'آخر التحميلات',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ]),
              Text(
                '${s.myDownloads.length} عنصر',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recent.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: platformColor(e.platform).withOpacity(0.1),
                    border: Border.all(
                      color: platformColor(e.platform).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    platformIcon(e.platform),
                    color: platformColor(e.platform),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title.isEmpty ? 'فيديو ${e.platform}' : e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        timeAgo(e.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: e.status == 'success'
                        ? AppColors.success
                        : e.status == 'failed'
                            ? AppColors.error
                            : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HISTORY SCREEN
// ============================================================================
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final list = s.myDownloads;
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(children: [
              const Icon(Icons.history, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'سجل التنزيلات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Spacer(),
              if (list.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surfaceLight,
                        title: const Text(
                          'مسح السجل',
                          style: TextStyle(color: AppColors.text),
                        ),
                        content: const Text(
                          'هل تريد مسح كل السجل؟',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'مسح',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) s.clearMyHistory();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'مسح',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 60,
                          color: AppColors.textDim.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'لا يوجد سجل تحميلات بعد',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: platformColor(e.platform).withOpacity(0.1),
                              border: Border.all(
                                color:
                                    platformColor(e.platform).withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              platformIcon(e.platform),
                              color: platformColor(e.platform),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title.isEmpty
                                      ? 'فيديو ${e.platform}'
                                      : e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  e.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textDim,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(spacing: 6, children: [
                                  _MiniTag(e.platform, AppColors.primary),
                                  _MiniTag(e.quality, AppColors.success),
                                  _MiniTag(
                                    timeAgo(e.createdAt),
                                    AppColors.textMuted,
                                  ),
                                ]),
                                if (e.status == 'success' &&
                                    e.downloadLink.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _SmallBtn(
                                      label: 'تنزيل',
                                      icon: Icons.download,
                                      color: AppColors.primary,
                                      onTap: () async {
                                        final uri =
                                            Uri.tryParse(e.downloadLink);
                                        if (uri != null) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _SmallBtn(
                                      label: 'نسخ',
                                      icon: Icons.copy,
                                      color: AppColors.textMuted,
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: e.downloadLink,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('تم النسخ'),
                                            backgroundColor:
                                                AppColors.success,
                                          ),
                                        );
                                      },
                                    ),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: e.status == 'success'
                                  ? AppColors.success
                                  : e.status == 'failed'
                                      ? AppColors.error
                                      : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================================
// SETTINGS SCREEN
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final codeCtrl = TextEditingController();
  String? codeError;
  String? codeSuccess;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final key = s.myApiKey;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.surfaceLight],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55F97316),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'YJ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  kDevName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'المطور الرئيسي',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(
                    Icons.chat,
                    color: Color(0xFF25D366),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    kDevWhatsapp,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _SocialBtn(
                    Icons.chat,
                    () => launchUrl(
                      Uri.parse('https://wa.me/2$kDevWhatsapp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SocialBtn(Icons.alternate_email, () {}),
                  const SizedBox(width: 8),
                  _SocialBtn(Icons.telegram, () {}),
                  const SizedBox(width: 8),
                  _SocialBtn(Icons.code, () {}),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            if (!s.isGuest) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.api.withOpacity(0.08),
                    AppColors.api.withOpacity(0.02),
                  ]),
                  border: Border.all(color: AppColors.api.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.key, color: AppColors.api, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'الاشتراك و API',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (key != null && key.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'API Key',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              Expanded(
                                child: Text(
                                  key.apiKey,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppColors.api,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 14),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: key.apiKey),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ API Key'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TimerBox(
                            value: '${key.daysLeft}',
                            label: 'يوم',
                          ),
                          _TimerBox(
                            value: '${key.hoursLeft}',
                            label: 'ساعة',
                          ),
                          _TimerBox(
                            value: '${key.totalRequests}',
                            label: 'طلب',
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.25),
                          ),
                        ),
                        child: const Row(children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا يوجد اشتراك نشط. فعّل كود للبدء.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'DOViD-XXXX-XXXX',
                        hintStyle: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.api,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (codeCtrl.text.trim().isEmpty) return;
                          final err = s.activateCode(
                            codeCtrl.text.trim().toUpperCase(),
                          );
                          setState(() {
                            codeError = err;
                            codeSuccess =
                                err == null ? 'تم تفعيل الاشتراك بنجاح!' : null;
                          });
                          if (err == null) codeCtrl.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.api,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'تفعيل الكود',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (codeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          codeError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (codeSuccess != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          codeSuccess!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'سعر الاشتراك الشهري: $kApiPrice جنيه',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'معلومات التطبيق',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const _InfoRow('التطبيق', kAppName),
                  const _InfoRow('المطور', kDevName),
                  const _InfoRow('واتساب', kDevWhatsapp),
                  const _InfoRow('الإصدار', 'v4.1.0'),
                  _InfoRow('المستخدم', s.currentUser?.username ?? 'زائر'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surfaceLight,
                      title: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: AppColors.text),
                      ),
                      content: const Text(
                        'هل تريد تسجيل الخروج؟',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'خروج',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) s.logout();
                },
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 16,
                ),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _TimerBox extends StatelessWidget {
  final String value;
  final String label;

  const _TimerBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.api,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textMuted,
        ),
      ),
    ]);
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

// ============================================================================
// ADMIN SCREEN
// ============================================================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  final codeCountCtrl = TextEditingController(text: '1');
  final codeDaysCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    codeCountCtrl.dispose();
    codeDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: const Row(children: [
              Icon(
                Icons.admin_panel_settings,
                color: AppColors.admin,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.admin,
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _AdminTab(
                  label: 'نظرة عامة',
                  icon: Icons.dashboard,
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _AdminTab(
                  label: 'المستخدمون',
                  icon: Icons.people,
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                const SizedBox(width: 8),
                _AdminTab(
                  label: 'الأكواد',
                  icon: Icons.key,
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
                const SizedBox(width: 8),
                _AdminTab(
                  label: 'التحميلات',
                  icon: Icons.download,
                  active: _tab == 3,
                  onTap: () => setState(() => _tab = 3),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? _OverviewTab()
                : _tab == 1
                    ? _UsersTab()
                    : _tab == 2
                        ? _CodesTab(
                            codeCountCtrl: codeCountCtrl,
                            codeDaysCtrl: codeDaysCtrl,
                          )
                        : _DownloadsTab(),
          ),
        ]);
      },
    );
  }
}

class _AdminTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AdminTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.admin, Color(0xFF7C3AED)],
                )
              : null,
          color: active ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.border,
          ),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x558B5CF6), blurRadius: 15)]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 13,
            color: active ? Colors.white : AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ]),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          Expanded(
            child: _AdminStat('المستخدمون', s.users.length, AppColors.admin),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AdminStat(
              'التحميلات',
              s.downloads.length,
              AppColors.primary,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: _AdminStat('الأكواد', s.codes.length, AppColors.api),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AdminStat(
              'API Keys',
              s.apiKeys.length,
              AppColors.success,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إحصائيات الأكواد',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow('إجمالي الأكواد', '${s.codes.length}'),
              _InfoRow(
                'مستخدمة',
                '${s.codes.where((c) => c.status == 'used').length}',
              ),
              _InfoRow(
                'متاحة',
                '${s.codes.where((c) => c.status == 'active').length}',
              ),
              _InfoRow(
                'اشتراكات نشطة',
                '${s.apiKeys.where((k) => k.isActive).length}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AdminStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: s.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = s.users[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (u.isAdmin ? AppColors.admin : AppColors.primary)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                u.isAdmin ? Icons.shield : Icons.person,
                color: u.isAdmin ? AppColors.admin : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    u.isAdmin ? 'مدير' : 'مستخدم',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'انضم ${DateFormat('yyyy-MM-dd').format(u.createdAt)}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (!u.isAdmin)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surfaceLight,
                      title: const Text(
                        'حذف المستخدم',
                        style: TextStyle(color: AppColors.text),
                      ),
                      content: Text(
                        'حذف ${u.username}?',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'حذف',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) s.deleteUser(u.id);
                },
              ),
          ]),
        );
      },
    );
  }
}

class _CodesTab extends StatelessWidget {
  final TextEditingController codeCountCtrl;
  final TextEditingController codeDaysCtrl;

  const _CodesTab({
    required this.codeCountCtrl,
    required this.codeDaysCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'توليد أكواد اشتراك',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: codeCountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                    decoration: _inputDec('العدد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: codeDaysCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                    decoration: _inputDec('الأيام'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final c = int.tryParse(codeCountCtrl.text) ?? 1;
                    final d = int.tryParse(codeDaysCtrl.text) ?? 30;
                    s.generateCodes(c.clamp(1, 50), d.clamp(1, 365));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم توليد $c كود'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.black),
                  label: const Text(
                    'توليد',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.api,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'الأكواد المتاحة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ...s.codes.reversed.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.api,
                      ),
                    ),
                    Row(children: [
                      Text(
                        '${c.durationDays} يوم',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniTag(
                        c.status == 'active' ? 'متاح' : 'مستخدم',
                        c.status == 'active'
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: c.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم النسخ'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                onPressed: () => s.deleteCode(c.id),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textDim,
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );
}

class _DownloadsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final list = s.allDownloads;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد تحميلات',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = list[i];
        final owner = s.users.where((u) => u.id == e.userId).firstOrNull;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: platformColor(e.platform).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                platformIcon(e.platform),
                color: platformColor(e.platform),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title.isEmpty ? 'فيديو ${e.platform}' : e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${owner?.username ?? 'زائر'} • ${timeAgo(e.createdAt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _MiniTag(
              e.status == 'success'
                  ? 'ناجح'
                  : e.status == 'failed'
                      ? 'فاشل'
                      : 'معالجة',
              e.status == 'success'
                  ? AppColors.success
                  : e.status == 'failed'
                      ? AppColors.error
                      : AppColors.warning,
            ),
          ]),
        );
      },
    );
  }
}