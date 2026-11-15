import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:collection/collection.dart';

// ============================================================================
// CONSTANTS (Fixed - Not editable)
// ============================================================================
const String kDevName = 'YOSSEF JOO';
const String kDevWhatsapp = '01029892573';
const String kAppName = 'DOViD';
const String kAppVersion = 'v5.0 Pro';
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
  static const border = Color(0x14FFFFFF);
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
        lastLogin:
            j['lastLogin'] != null ? DateTime.tryParse(j['lastLogin']) : null,
      );
}

class DownloadEntry {
  final String id;
  final String userId;
  final String url;
  String title;
  String platform;
  String downloadLink;
  String localPath;
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
    this.localPath = '',
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
        'localPath': localPath,
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
        localPath: j['localPath'] ?? '',
        quality: j['quality'] ?? 'auto',
        status: j['status'] ?? 'pending',
        strategy: j['strategy'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'])
            : null,
      );
}

class BypassLogEntry {
  final String id;
  final String userId;
  final String url;
  final String strategy;
  final String status;
  final int responseTimeMs;
  final DateTime createdAt;

  BypassLogEntry({
    required this.id,
    required this.userId,
    required this.url,
    required this.strategy,
    required this.status,
    required this.responseTimeMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'url': url,
        'strategy': strategy,
        'status': status,
        'responseTimeMs': responseTimeMs,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BypassLogEntry.fromJson(Map<String, dynamic> j) => BypassLogEntry(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        url: j['url'] ?? '',
        strategy: j['strategy'] ?? '',
        status: j['status'] ?? 'failed',
        responseTimeMs: j['responseTimeMs'] ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class LoginAttemptEntry {
  final String id;
  final String ip;
  final String username;
  final bool success;
  final DateTime createdAt;

  LoginAttemptEntry({
    required this.id,
    required this.ip,
    required this.username,
    required this.success,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ip': ip,
        'username': username,
        'success': success,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LoginAttemptEntry.fromJson(Map<String, dynamic> j) =>
      LoginAttemptEntry(
        id: j['id'] ?? '',
        ip: j['ip'] ?? '127.0.0.1',
        username: j['username'] ?? '',
        success: j['success'] ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class BlockedIpEntry {
  final String id;
  final String ip;
  final String reason;
  final DateTime blockedAt;

  BlockedIpEntry({
    required this.id,
    required this.ip,
    required this.reason,
    required this.blockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ip': ip,
        'reason': reason,
        'blockedAt': blockedAt.toIso8601String(),
      };

  factory BlockedIpEntry.fromJson(Map<String, dynamic> j) => BlockedIpEntry(
        id: j['id'] ?? '',
        ip: j['ip'] ?? '',
        reason: j['reason'] ?? 'Blocked by security shield',
        blockedAt: DateTime.tryParse(j['blockedAt'] ?? '') ?? DateTime.now(),
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
  int monthlyRequests;
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
    this.monthlyRequests = 0,
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

  int get minutesLeft {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? (diff % 3600) ~/ 60 : 0;
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
        'monthlyRequests': monthlyRequests,
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
        monthlyRequests: j['monthlyRequests'] ?? 0,
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
// APP STATE (Full System Singleton with Security, Rate Limiting & Settings)
// ============================================================================
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  SharedPreferences? _prefs;

  AppUser? currentUser;
  bool isGuest = false;
  bool initialized = false;

  // Settings
  Color accentColor = AppColors.primary;
  String defaultQuality = 'auto';
  bool adsEnabled = false;
  String adsensePublisherId = '';
  String adsenseDisplaySlot = '';
  String adsenseInArticleSlot = '';
  String adsenseAnchorSlot = '';

  // Data Collections
  List<AppUser> users = [];
  List<DownloadEntry> downloads = [];
  List<BypassLogEntry> bypassLogs = [];
  List<LoginAttemptEntry> loginAttempts = [];
  List<BlockedIpEntry> blockedIps = [];
  List<ApiKey> apiKeys = [];
  List<SubscriptionCode> codes = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();

    // Ensure fixed Admin exists
    final adminHash = _hash(kAdminPassword);
    final existingAdmin =
        users.where((u) => u.username == kAdminUsername).firstOrNull;
    if (existingAdmin == null) {
      users.add(AppUser(
        id: _genId(),
        username: kAdminUsername,
        passwordHash: adminHash,
        email: kAdminEmail,
        isAdmin: true,
        createdAt: DateTime.now(),
      ));
      await _saveUsers();
    }

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
    final bp = _prefs!.getString('bypass_logs');
    if (bp != null) {
      bypassLogs = (jsonDecode(bp) as List)
          .map((e) => BypassLogEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final la = _prefs!.getString('login_attempts');
    if (la != null) {
      loginAttempts = (jsonDecode(la) as List)
          .map((e) => LoginAttemptEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final bi = _prefs!.getString('blocked_ips');
    if (bi != null) {
      blockedIps = (jsonDecode(bi) as List)
          .map((e) => BlockedIpEntry.fromJson(Map<String, dynamic>.from(e)))
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

    // Load Settings
    final colorVal = _prefs!.getInt('theme_color_int');
    if (colorVal != null) accentColor = Color(colorVal);
    defaultQuality = _prefs!.getString('default_quality') ?? 'auto';
    adsEnabled = _prefs!.getBool('ads_enabled') ?? false;
    adsensePublisherId = _prefs!.getString('adsense_publisher_id') ?? '';
    adsenseDisplaySlot = _prefs!.getString('adsense_display_slot') ?? '';
    adsenseInArticleSlot = _prefs!.getString('adsense_inarticle_slot') ?? '';
    adsenseAnchorSlot = _prefs!.getString('adsense_anchor_slot') ?? '';
  }

  Future<void> saveSettings({
    Color? newColor,
    String? newQuality,
    bool? newAdsEnabled,
    String? pubId,
    String? dispSlot,
    String? inArtSlot,
    String? anchSlot,
  }) async {
    if (newColor != null) {
      accentColor = newColor;
      await _prefs?.setInt('theme_color_int', newColor.value);
    }
    if (newQuality != null) {
      defaultQuality = newQuality;
      await _prefs?.setString('default_quality', newQuality);
    }
    if (newAdsEnabled != null) {
      adsEnabled = newAdsEnabled;
      await _prefs?.setBool('ads_enabled', newAdsEnabled);
    }
    if (pubId != null) {
      adsensePublisherId = pubId;
      await _prefs?.setString('adsense_publisher_id', pubId);
    }
    if (dispSlot != null) {
      adsenseDisplaySlot = dispSlot;
      await _prefs?.setString('adsense_display_slot', dispSlot);
    }
    if (inArtSlot != null) {
      adsenseInArticleSlot = inArtSlot;
      await _prefs?.setString('adsense_inarticle_slot', inArtSlot);
    }
    if (anchSlot != null) {
      adsenseAnchorSlot = anchSlot;
      await _prefs?.setString('adsense_anchor_slot', anchSlot);
    }
    notifyListeners();
  }

  Future<void> _saveUsers() async {
    await _prefs?.setString(
        'users', jsonEncode(users.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveDownloads() async {
    await _prefs?.setString(
        'downloads', jsonEncode(downloads.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveBypassLogs() async {
    if (bypassLogs.length > 200) {
      bypassLogs = bypassLogs.sublist(0, 200);
    }
    await _prefs?.setString(
        'bypass_logs', jsonEncode(bypassLogs.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveLoginAttempts() async {
    if (loginAttempts.length > 200) {
      loginAttempts = loginAttempts.sublist(0, 200);
    }
    await _prefs?.setString('login_attempts',
        jsonEncode(loginAttempts.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveBlockedIps() async {
    await _prefs?.setString(
        'blocked_ips', jsonEncode(blockedIps.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveApiKeys() async {
    await _prefs?.setString(
        'api_keys', jsonEncode(apiKeys.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveCodes() async {
    await _prefs?.setString(
        'codes', jsonEncode(codes.map((e) => e.toJson()).toList()));
  }

  // ============ SECURITY & AUTH ============
  String _hash(String password) =>
      base64Url.encode(utf8.encode('dovid_salt_${password}_v4'));

  String _genId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  bool isDeviceBlocked() {
    return blockedIps.any((b) => b.ip == 'local_device');
  }

  int recentFailedAttempts() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    return loginAttempts
        .where((a) => !a.success && a.createdAt.isAfter(cutoff))
        .length;
  }

  String? login(String username, String password) {
    if (isDeviceBlocked()) {
      return 'تم حظر الوصول مؤقتاً بسبب تجاوز عدد المحاولات المسموح بها';
    }
    if (recentFailedAttempts() >= 10) {
      blockedIps.insert(
        0,
        BlockedIpEntry(
          id: _genId(),
          ip: 'local_device',
          reason: '10 محاولات دخول فاشلة خلال 15 دقيقة',
          blockedAt: DateTime.now(),
        ),
      );
      _saveBlockedIps();
      notifyListeners();
      return 'تم حظر الجهاز تلقائياً لتكرار المحاولات الفاشلة (10 محاولات)';
    }

    final user = users.where((u) => u.username == username).firstOrNull;
    final validPass = user != null && user.passwordHash == _hash(password);

    loginAttempts.insert(
      0,
      LoginAttemptEntry(
        id: _genId(),
        ip: '127.0.0.1',
        username: username,
        success: validPass,
        createdAt: DateTime.now(),
      ),
    );
    _saveLoginAttempts();

    if (user == null) return 'اسم المستخدم غير موجود';
    if (!validPass) return 'كلمة المرور غير صحيحة';

    user.lastLogin = DateTime.now();
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    notifyListeners();
    return null;
  }

  String? register(String username, String password, {String email = ''}) {
    if (username.length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    if (password.length < 4) return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
    if (users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'اسم المستخدم مستخدم بالفعل';
    }

    final user = AppUser(
      id: _genId(),
      username: username,
      passwordHash: _hash(password),
      email: email,
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

  // ============ DOWNLOADS & BYPASS LOGS ============
  List<DownloadEntry> get myDownloads {
    final uid = currentUser?.id ?? (isGuest ? 'guest' : '');
    if (uid.isEmpty) return [];
    final list = downloads.where((d) => d.userId == uid).toList();
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

  Future<void> recordBypassAttempt({
    required String url,
    required String strategy,
    required bool success,
    required int responseTimeMs,
  }) async {
    bypassLogs.insert(
      0,
      BypassLogEntry(
        id: _genId(),
        userId: currentUser?.id ?? 'guest',
        url: url,
        strategy: strategy,
        status: success ? 'success' : 'failed',
        responseTimeMs: responseTimeMs,
        createdAt: DateTime.now(),
      ),
    );
    await _saveBypassLogs();
    notifyListeners();
  }

  Future<void> updateDownload(
    DownloadEntry entry, {
    String? title,
    String? link,
    String? localPath,
    String? status,
    String? strategy,
  }) async {
    if (title != null) entry.title = title;
    if (link != null) entry.downloadLink = link;
    if (localPath != null) entry.localPath = localPath;
    if (status != null) entry.status = status;
    if (strategy != null) entry.strategy = strategy;
    if (status == 'success' || status == 'failed') {
      entry.completedAt = DateTime.now();
    }
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> clearMyHistory() async {
    final uid = currentUser?.id ?? (isGuest ? 'guest' : '');
    if (uid.isEmpty) return;
    downloads.removeWhere((d) => d.userId == uid);
    bypassLogs.removeWhere((b) => b.userId == uid);
    await _saveDownloads();
    await _saveBypassLogs();
    notifyListeners();
  }

  // ============ API KEYS / SUBSCRIPTION ============
  ApiKey? get myApiKey {
    if (currentUser == null) return null;
    final mine = apiKeys.where((k) => k.userId == currentUser!.id).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine.first;
  }

  String? activateCode(String code) {
    if (currentUser == null) return 'يجب تسجيل الدخول بحساب رسمي أولاً';
    final cleanCode = code.trim().toUpperCase();
    final c = codes
        .where((x) => x.code.toUpperCase() == cleanCode && x.status == 'active')
        .firstOrNull;
    if (c == null) return 'كود الاشتراك غير صالح أو مستخدم بالفعل';

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

  // ============ ADMIN ACTIONS ============
  List<DownloadEntry> get allDownloads {
    final list = List<DownloadEntry>.from(downloads);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<String> generateCodes(int count, int days) {
    final generated = <String>[];
    for (int i = 0; i < count; i++) {
      final newCode = 'DOViD-${_randomHex(6).toUpperCase()}';
      codes.add(SubscriptionCode(
        id: _genId(),
        code: newCode,
        durationDays: days,
        createdAt: DateTime.now(),
      ));
      generated.add(newCode);
    }
    _saveCodes();
    notifyListeners();
    return generated;
  }

  void deleteCode(String id) {
    codes.removeWhere((c) => c.id == id);
    _saveCodes();
    notifyListeners();
  }

  void deactivateApiKey(String id) {
    final key = apiKeys.where((k) => k.id == id).firstOrNull;
    if (key != null) {
      key.status = 'inactive';
      _saveApiKeys();
      notifyListeners();
    }
  }

  void blockIp(String ip, {String reason = 'حظر بواسطة المدير'}) {
    if (!blockedIps.any((b) => b.ip == ip)) {
      blockedIps.insert(
        0,
        BlockedIpEntry(
          id: _genId(),
          ip: ip,
          reason: reason,
          blockedAt: DateTime.now(),
        ),
      );
      _saveBlockedIps();
      notifyListeners();
    }
  }

  void unblockIp(String id) {
    blockedIps.removeWhere((b) => b.id == id);
    _saveBlockedIps();
    notifyListeners();
  }

  void deleteUser(String id) {
    if (currentUser?.id == id) return;
    users.removeWhere((u) => u.id == id && !u.isAdmin);
    downloads.removeWhere((d) => d.userId == id);
    bypassLogs.removeWhere((b) => b.userId == id);
    apiKeys.removeWhere((k) => k.userId == id);
    _saveUsers();
    _saveDownloads();
    _saveBypassLogs();
    _saveApiKeys();
    notifyListeners();
  }

  String _randomHex(int length) {
    final r = Random.secure();
    return List.generate(
            length, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

// ============================================================================
// UTILS (Const-safe IconData for Flutter release tree-shaking)
// ============================================================================
String detectPlatform(String url) {
  final u = url.toLowerCase();
  if (u.contains('youtube.com') || u.contains('youtu.be')) return 'youtube';
  if (u.contains('instagram.com')) return 'instagram';
  if (u.contains('tiktok.com')) return 'tiktok';
  if (u.contains('facebook.com') || u.contains('fb.watch')) return 'facebook';
  if (u.contains('twitter.com') || u.contains('x.com')) return 'twitter';
  if (u.contains('snapchat.com')) return 'snapchat';
  if (u.contains('pinterest.com') || u.contains('pin.it')) return 'pinterest';
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
    case 'snapchat':
      return Icons.bolt;
    case 'pinterest':
      return Icons.push_pin;
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
      return const Color(0xFF00F2FE);
    case 'facebook':
      return const Color(0xFF1877F2);
    case 'twitter':
      return const Color(0xFF1DA1F2);
    case 'snapchat':
      return const Color(0xFFFFFC00);
    case 'pinterest':
      return const Color(0xFFE60023);
    case 'vimeo':
      return const Color(0xFF1AB7EA);
    case 'dailymotion':
      return const Color(0xFF00AAFF);
    default:
      return AppState().accentColor;
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
// SMART MULTI-STRATEGY DOWNLOAD & FILE STREAMING SERVICE
// ============================================================================
class DownloadService {
  static Future<String> _resolveShortUrl(String url) async {
    final lowerUrl = url.toLowerCase();
    if (!lowerUrl.contains('vt.tiktok.com') &&
        !lowerUrl.contains('vm.tiktok.com') &&
        !lowerUrl.contains('fb.watch') &&
        !lowerUrl.contains('pin.it')) {
      return url;
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      client.badCertificateCallback = (_, __, ___) => true;
      final request = await client.headUrl(Uri.parse(url));
      request.followRedirects = true;
      final response = await request.close();
      String finalUrl = url;
      if (response.redirects.isNotEmpty) {
        finalUrl = response.redirects.last.location.toString();
      }
      client.close();
      return finalUrl;
    } catch (_) {
      return url;
    }
  }

  static Future<Map<String, dynamic>> download(
    String originalUrl, {
    String quality = 'auto',
    void Function(String strategyName)? onStrategyTrying,
  }) async {
    final url = await _resolveShortUrl(originalUrl);

    const desktopUserAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    final headers = {
      'User-Agent': desktopUserAgent,
      'Referer': url,
      'Accept': 'application/json, text/plain, */*',
    };

    final strategies =
        <String, Future<Map<String, dynamic>?> Function(String)>{
      'direct_post_json': (u) => _directPostJson(u, headers, quality),
      'direct_post_form': (u) => _directPostForm(u, headers, quality),
      'tikwm_engine': (u) => _tikwmFallback(u, quality),
      'allorigins_post': (u) => _alloriginsPost(u, headers),
      'allorigins_get': (u) => _alloriginsGet(u, headers),
      'corsproxy_post': (u) => _corsproxy(u, headers),
    };

    for (final entry in strategies.entries) {
      onStrategyTrying?.call(entry.key);
      final sw = Stopwatch()..start();
      try {
        final result = await entry.value(url);
        sw.stop();
        final ok = result != null &&
            result['status'] == 'success' &&
            (result['answer'] ?? '').toString().isNotEmpty;

        await AppState().recordBypassAttempt(
          url: url,
          strategy: entry.key,
          success: ok,
          responseTimeMs: sw.elapsedMilliseconds,
        );

        if (ok) {
          result['strategy'] = entry.key;
          return result;
        }
      } catch (_) {
        sw.stop();
        await AppState().recordBypassAttempt(
          url: url,
          strategy: entry.key,
          success: false,
          responseTimeMs: sw.elapsedMilliseconds,
        );
      }
    }
    return {
      'status': 'error',
      'message':
          'فشلت جميع استراتيجيات التخطي الـ 6. تأكد من صحة الرابط وأن الفيديو عام.',
    };
  }

  static Future<Map<String, dynamic>?> _directPostJson(
      String url, Map<String, String> headers, String quality) async {
    try {
      final res = await http
          .post(
            Uri.parse(kApiEndpoint),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 22));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _directPostForm(
      String url, Map<String, String> headers, String quality) async {
    try {
      final res = await http
          .post(
            Uri.parse(kApiEndpoint),
            headers: {
              ...headers,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: {'text': url, 'quality': quality},
          )
          .timeout(const Duration(seconds: 22));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _tikwmFallback(
      String url, String quality) async {
    if (!url.toLowerCase().contains('tiktok.com')) return null;
    try {
      final res = await http.post(
        Uri.parse('https://www.tikwm.com/api/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'url': url, 'hd': '1'},
      ).timeout(const Duration(seconds: 18));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['code'] == 0 && j['data'] != null) {
          final d = j['data'];
          final link = (quality == 'audio' && d['music'] != null)
              ? d['music'].toString()
              : (d['hdplay'] ?? d['play'] ?? d['wmplay'] ?? '').toString();
          if (link.isNotEmpty) {
            return {
              'status': 'success',
              'answer': link,
              'title': (d['title'] ?? 'فيديو TikTok بدون علامة مائية').toString(),
              'quality': quality == 'audio' ? 'MP3 Audio' : 'HD No-Watermark',
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsPost(
      String url, Map<String, String> headers) async {
    try {
      final proxy =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http
          .post(
            Uri.parse(proxy),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url}),
          )
          .timeout(const Duration(seconds: 22));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsGet(
      String url, Map<String, String> headers) async {
    try {
      final target = '$kApiEndpoint?text=${Uri.encodeComponent(url)}';
      final proxy =
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(target)}&timestamp=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http
          .get(Uri.parse(proxy), headers: headers)
          .timeout(const Duration(seconds: 22));
      if (res.statusCode == 200) {
        final wrapper = jsonDecode(res.body);
        if (wrapper['contents'] != null) {
          return Map<String, dynamic>.from(jsonDecode(wrapper['contents']));
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _corsproxy(
      String url, Map<String, String> headers) async {
    try {
      final proxy =
          'https://corsproxy.io/?${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http
          .post(
            Uri.parse(proxy),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url}),
          )
          .timeout(const Duration(seconds: 22));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  /// تنزيل مباشر للملف داخل ذاكرة الهاتف مع شريط تقدم وترويسات تخطي الحجب
  static Future<String?> downloadFileToDevice({
    required String url,
    required String filename,
    required String platform,
    required bool isAudio,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final referers = {
        'youtube': 'https://www.youtube.com/',
        'instagram': 'https://www.instagram.com/',
        'tiktok': 'https://www.tiktok.com/',
        'facebook': 'https://www.facebook.com/',
        'twitter': 'https://x.com/',
      };

      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0.0.0 Safari/537.36');
      if (referers.containsKey(platform)) {
        req.headers.set('Referer', referers[platform]!);
      }

      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 206) {
        client.close();
        return null;
      }

      final cleanName = filename
          .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s\-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final safeBase = cleanName.isEmpty
          ? 'DOViD_${DateTime.now().millisecondsSinceEpoch}'
          : (cleanName.length > 55 ? cleanName.substring(0, 55) : cleanName);
      final ext = isAudio ? 'mp3' : 'mp4';

      Directory targetDir = Directory('/storage/emulated/0/Download');
      if (!await targetDir.exists()) {
        targetDir = Directory.systemTemp;
      }

      final filePath = '${targetDir.path}/$safeBase.$ext';
      final file = File(filePath);
      final sink = file.openWrite();

      final totalBytes = res.contentLength;
      int received = 0;

      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          onProgress((received / totalBytes).clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();
      client.close();
      return filePath;
    } catch (_) {
      return null;
    }
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
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final accent = AppState().accentColor;
        return MaterialApp(
          title: 'DOViD - $kDevName',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: ColorScheme.dark(
              primary: accent,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
            ),
            fontFamily: 'Tajawal',
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const RootScreen(),
        );
      },
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
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
                child: CircularProgressIndicator(color: s.accentColor)),
          );
        }
        if (s.currentUser == null && !s.isGuest) return const AuthScreen();
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
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? error;
  bool loading = false;

  @override
  void dispose() {
    userCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      error = null;
      loading = true;
    });
    await Future.delayed(const Duration(milliseconds: 280));
    final s = AppState();
    final err = isRegister
        ? s.register(userCtrl.text.trim(), passCtrl.text,
            email: emailCtrl.text.trim())
        : s.login(userCtrl.text.trim(), passCtrl.text);
    if (!mounted) return;
    setState(() {
      error = err;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppState().accentColor;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _AnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 40,
                        offset: Offset(0, 16))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondary, accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 36,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'DV',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (b) =>
                          LinearGradient(colors: [Colors.white, accent])
                              .createShader(b),
                      child: Text(
                        isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                        style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'DOViD v5.0 Pro - نظام التحميل الذكي المتكامل',
                      style:
                          TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 22),
                    if (error != null) _ErrorBanner(message: error!),
                    _AuthField(
                        controller: userCtrl,
                        icon: Icons.person,
                        hint: 'اسم المستخدم'),
                    if (isRegister) ...[
                      const SizedBox(height: 12),
                      _AuthField(
                          controller: emailCtrl,
                          icon: Icons.email_outlined,
                          hint: 'البريد الإلكتروني (اختياري)'),
                    ],
                    const SizedBox(height: 12),
                    _AuthField(
                        controller: passCtrl,
                        icon: Icons.lock,
                        hint: 'كلمة المرور',
                        obscure: true),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isRegister ? 'إنشاء الحساب' : 'تسجيل الدخول',
                      icon: isRegister ? Icons.person_add : Icons.login,
                      loading: loading,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('أو',
                            style: TextStyle(
                                color: AppColors.textDim, fontSize: 11)),
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
                          'متابعة كزائر بدون حساب',
                          style: TextStyle(
                              color: AppColors.guest,
                              fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.guest),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() {
                        isRegister = !isRegister;
                        error = null;
                      }),
                      child: Text(
                        isRegister
                            ? 'لديك حساب بالفعل؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ أنشئ حساباً الآن',
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 10),
                    const Text('Powered by $kDevName',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textDim)),
                    const Text('WhatsApp: $kDevWhatsapp',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.textDim)),
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
    final accent = AppState().accentColor;
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.5)),
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
            child: Text(message,
                style:
                    const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
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
    final accent = AppState().accentColor;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.secondary, accent]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
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
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ]),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN (with Floating Glassmorphic Bottom Nav)
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
            _NavItem(Icons.shield_rounded, 'المدير', admin: true),
        ];

        if (_tab >= pages.length) _tab = 0;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              const _AnimatedBackground(),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_tab),
                    child: pages[_tab],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.94),
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
                    final color = it.admin ? AppColors.admin : s.accentColor;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tab = i),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? color.withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(it.icon,
                                  size: 22,
                                  color: active ? color : AppColors.textMuted),
                              const SizedBox(height: 3),
                              Text(
                                it.label,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        active ? color : AppColors.textMuted),
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
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppState().accentColor;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * pi;
        return Stack(children: [
          Container(color: AppColors.bg),
          Positioned(
            top: -190 + sin(t) * 45,
            right: -140 + cos(t) * 45,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150 + cos(t) * 35,
            left: -150 + sin(t) * 35,
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x168B5CF6), Colors.transparent],
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
  late String quality;
  bool loading = false;
  bool savingToDevice = false;
  double saveProgress = 0.0;
  String? error;
  DownloadEntry? result;
  String loadingText = 'جاري الاتصال بالسيرفر الذكي...';
  String currentStrategy = 'direct_post_json';

  final qualities = const [
    {'key': 'auto', 'label': 'تلقائي', 'icon': Icons.auto_awesome},
    {'key': '4k', 'label': '4K Ultra', 'icon': Icons.star},
    {'key': '1080', 'label': 'FHD 1080p', 'icon': Icons.tv},
    {'key': '720', 'label': 'HD 720p', 'icon': Icons.phone_android},
    {'key': 'audio', 'label': 'صوت MP3', 'icon': Icons.music_note},
  ];

  @override
  void initState() {
    super.initState();
    quality = AppState().defaultQuality;
  }

  @override
  void dispose() {
    urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = data?.text?.trim() ?? '';
    if (txt.isNotEmpty) {
      setState(() {
        urlCtrl.text = txt;
        error = null;
      });
    }
  }

  Future<void> _download() async {
    final url = urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => error = 'يرجى إدخال رابط الفيديو أولاً');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => error = 'الرابط غير صالح، يجب أن يبدأ بـ http أو https');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      result = null;
      loadingText = 'جاري فحص الرابط وتخطي الحماية...';
    });

    final s = AppState();
    final entry = await s.addDownload(url, quality);

    final response = await DownloadService.download(
      url,
      quality: quality,
      onStrategyTrying: (st) {
        if (!mounted) return;
        setState(() {
          currentStrategy = st;
          loadingText = 'محاولة الاستخراج عبر: $st';
        });
      },
    );

    if (!mounted) return;

    if (response['status'] == 'success') {
      final link = (response['answer'] ?? response['url'] ?? '').toString();
      final title = (response['title'] ?? 'فيديو ${entry.platform}').toString();
      final strategy = (response['strategy'] ?? 'direct').toString();
      await s.updateDownload(entry,
          title: title, link: link, status: 'success', strategy: strategy);
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

  Future<void> _saveVideoFile(DownloadEntry e) async {
    if (savingToDevice) return;
    setState(() {
      savingToDevice = true;
      saveProgress = 0.02;
    });

    final savedPath = await DownloadService.downloadFileToDevice(
      url: e.downloadLink,
      filename: e.title.isEmpty ? 'DOViD_${e.platform}' : e.title,
      platform: e.platform,
      isAudio: e.quality == 'audio',
      onProgress: (p) {
        if (!mounted) return;
        setState(() => saveProgress = p);
      },
    );

    if (!mounted) return;
    setState(() => savingToDevice = false);

    if (savedPath != null) {
      await AppState().updateDownload(e, localPath: savedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الملف بنجاح في: $savedPath'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final uri = Uri.tryParse(e.downloadLink);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final accent = s.accentColor;
    final activePlatform = detectPlatform(urlCtrl.text);

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
                      color: accent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(
                      label: 'ناجح',
                      value: s.successDownloads,
                      color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(
                      label: 'فاشل',
                      value: s.failedDownloads,
                      color: AppColors.error)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          border:
                              Border.all(color: accent.withOpacity(0.25)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt, color: accent, size: 13),
                          const SizedBox(width: 4),
                          Text('DOViD Pro v5.0',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const Row(children: [
                        Icon(Icons.verified_user,
                            color: AppColors.success, size: 13),
                        SizedBox(width: 4),
                        Text('6 محركات تخطي',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlCtrl,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 13),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText:
                                'الصق رابط الفيديو (YouTube, TikTok, Instagram...)',
                            hintStyle: const TextStyle(
                                color: AppColors.textDim, fontSize: 11.5),
                            prefixIcon:
                                Icon(Icons.link, color: accent, size: 18),
                            suffixIcon: urlCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 16, color: AppColors.textMuted),
                                    onPressed: () => setState(() {
                                      urlCtrl.clear();
                                      result = null;
                                      error = null;
                                    }),
                                  ),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 15),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: accent, width: 1.5)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _pasteFromClipboard,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: accent.withOpacity(0.35)),
                          ),
                          child: Row(children: [
                            Icon(Icons.content_paste_rounded,
                                size: 16, color: accent),
                            const SizedBox(width: 4),
                            Text('لصق',
                                style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    ],
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
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: active
                                  ? LinearGradient(
                                      colors: [AppColors.secondary, accent])
                                  : null,
                              color: active ? null : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: active
                                      ? Colors.transparent
                                      : AppColors.border),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(q['icon'] as IconData,
                                  size: 13,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMuted),
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
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'تحميل الفيديو الآن',
                    icon: Icons.download_rounded,
                    loading: loading,
                    onTap: _download,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(children: [
                        CircularProgressIndicator(
                            strokeWidth: 3, color: accent),
                        const SizedBox(height: 10),
                        Text(loadingText,
                            style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('الاستراتيجية: $currentStrategy',
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 10)),
                      ]),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: error!),
                  ],
                  if (result != null && result!.downloadLink.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ResultCard(
                      entry: result!,
                      saving: savingToDevice,
                      progress: saveProgress,
                      onSaveToDevice: () => _saveVideoFile(result!),
                    ),
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
                  const Text('المنصات المدعومة بالكامل',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PlatformIcon(
                          Icons.play_circle_fill,
                          const Color(0xFFFF0000),
                          'YouTube',
                          activePlatform == 'youtube'),
                      _PlatformIcon(Icons.music_note, const Color(0xFF00F2FE),
                          'TikTok', activePlatform == 'tiktok'),
                      _PlatformIcon(Icons.camera_alt, const Color(0xFFE4405F),
                          'Instagram', activePlatform == 'instagram'),
                      _PlatformIcon(Icons.facebook, const Color(0xFF1877F2),
                          'Facebook', activePlatform == 'facebook'),
                      _PlatformIcon(
                          Icons.alternate_email,
                          const Color(0xFF1DA1F2),
                          'X / Twitter',
                          activePlatform == 'twitter'),
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
  final bool saving;
  final double progress;
  final VoidCallback onSaveToDevice;
  const _ResultCard({
    required this.entry,
    required this.saving,
    required this.progress,
    required this.onSaveToDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
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
                      blurRadius: 14)
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('تم استخراج الرابط المباشر بنجاح!',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Text(
            entry.title.isEmpty ? 'فيديو ${entry.platform}' : entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 10, children: [
            _Tag(Icons.video_file, entry.platform, AppState().accentColor),
            _Tag(Icons.diamond, entry.quality, AppColors.success),
            _Tag(Icons.route, entry.strategy, AppColors.textMuted),
          ]),
          if (saving) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.success,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 4),
            Text(
              'جاري التنزيل إلى الهاتف... ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: AppColors.success),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSaveToDevice,
                icon: const Icon(Icons.download_rounded,
                    size: 16, color: Colors.black),
                label: Text(
                  saving ? 'جاري الحفظ...' : 'تنزيل وحفظ بالهاتف',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.downloadLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم نسخ الرابط المباشر'),
                        backgroundColor: AppColors.success),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label:
                    const Text('نسخ الرابط', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(text,
          style: TextStyle(
              fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final accent = s.accentColor;
    final badgeColor = s.currentUser?.isAdmin == true
        ? AppColors.admin
        : s.isGuest
            ? AppColors.guest
            : accent;
    final badgeIcon = s.currentUser?.isAdmin == true
        ? Icons.shield
        : s.isGuest
            ? Icons.person_outline
            : Icons.person;
    final label = s.currentUser?.isAdmin == true
        ? '${s.currentUser!.username} (Admin)'
        : s.isGuest
            ? 'زائر (Guest)'
            : (s.currentUser?.username ?? '');

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            border: Border.all(color: badgeColor.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(badgeIcon, size: 13, color: badgeColor),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.secondary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 34,
                  offset: const Offset(0, 10))
            ],
          ),
          child: const Center(
            child: Text('DV',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2)),
          ),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (b) =>
              LinearGradient(colors: [Colors.white, accent]).createShader(b),
          child: const Text('DOViD',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1)),
        ),
        const Text('YOSSEF VID v5.0',
            style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) =>
              LinearGradient(colors: [color, color.withOpacity(0.65)])
                  .createShader(b),
          child: Text('$value',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final bool active;
  const _PlatformIcon(this.icon, this.color, this.name, this.active);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: Column(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(active ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: color.withOpacity(active ? 0.7 : 0.25),
                width: active ? 1.5 : 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(name,
            style: TextStyle(
                fontSize: 9.5,
                color: active ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _RecentDownloads extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final recent = s.myDownloads.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.history, color: s.accentColor, size: 16),
              const SizedBox(width: 6),
              const Text('آخر التحميلات',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            Text('${s.myDownloads.length} عنصر',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 12),
          ...recent.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: platformColor(e.platform).withOpacity(0.1),
                      border: Border.all(
                          color: platformColor(e.platform).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(platformIcon(e.platform),
                        color: platformColor(e.platform), size: 16),
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
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(timeAgo(e.createdAt),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
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
              )),
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
              Icon(Icons.history, color: s.accentColor),
              const SizedBox(width: 8),
              const Text('سجل التنزيلات الخاص بك',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              if (list.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surfaceLight,
                        title: const Text('مسح السجل',
                            style: TextStyle(color: AppColors.text)),
                        content: const Text('هل أنت متأكد من مسح سجلك بالكامل؟',
                            style: TextStyle(color: AppColors.textMuted)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('مسح',
                                  style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );
                    if (ok == true) s.clearMyHistory();
                  },
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: const Text('مسح السجل',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.inbox_outlined,
                            size: 60,
                            color: AppColors.textDim.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('لا توجد تحميلات في سجلك حتى الآن',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600)),
                      ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  platformColor(e.platform).withOpacity(0.1),
                              border: Border.all(
                                  color: platformColor(e.platform)
                                      .withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(platformIcon(e.platform),
                                color: platformColor(e.platform), size: 20),
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
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(e.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textDim)),
                                const SizedBox(height: 5),
                                Wrap(spacing: 6, children: [
                                  _MiniTag(e.platform, s.accentColor),
                                  _MiniTag(e.quality, AppColors.success),
                                  if (e.strategy.isNotEmpty)
                                    _MiniTag(e.strategy, AppColors.api),
                                  _MiniTag(timeAgo(e.createdAt),
                                      AppColors.textMuted),
                                ]),
                                if (e.status == 'success' &&
                                    e.downloadLink.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _SmallBtn(
                                      label: 'تنزيل',
                                      icon: Icons.download,
                                      color: s.accentColor,
                                      onTap: () async {
                                        final uri =
                                            Uri.tryParse(e.downloadLink);
                                        if (uri != null) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _SmallBtn(
                                      label: 'نسخ الرابط',
                                      icon: Icons.copy,
                                      color: AppColors.textMuted,
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: e.downloadLink));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('تم نسخ الرابط'),
                                              backgroundColor:
                                                  AppColors.success),
                                        );
                                      },
                                    ),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 9,
                            height: 9,
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
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w700)),
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
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ============================================================================
// SETTINGS SCREEN (Theme Customizer, Quality, AdSense & API Portal)
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final codeCtrl = TextEditingController();
  late final TextEditingController pubIdCtrl;
  late final TextEditingController dispSlotCtrl;
  late final TextEditingController inArtSlotCtrl;
  late final TextEditingController anchSlotCtrl;
  String? codeError;
  String? codeSuccess;

  final themeSwatches = const [
    Color(0xFFF97316), // Orange Pro
    Color(0xFFEF4444), // Crimson Red
    Color(0xFF8B5CF6), // Royal Violet
    Color(0xFF06B6D4), // Cyber Cyan
    Color(0xFF22C55E), // Emerald Green
    Color(0xFFF59E0B), // Gold Amber
  ];

  @override
  void initState() {
    super.initState();
    final s = AppState();
    pubIdCtrl = TextEditingController(text: s.adsensePublisherId);
    dispSlotCtrl = TextEditingController(text: s.adsenseDisplaySlot);
    inArtSlotCtrl = TextEditingController(text: s.adsenseInArticleSlot);
    anchSlotCtrl = TextEditingController(text: s.adsenseAnchorSlot);
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    pubIdCtrl.dispose();
    dispSlotCtrl.dispose();
    inArtSlotCtrl.dispose();
    anchSlotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final key = s.myApiKey;
        final isAdmin = s.currentUser?.isAdmin ?? false;

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Developer Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.surfaceLight]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.secondary, s.accentColor]),
                    boxShadow: [
                      BoxShadow(
                          color: s.accentColor.withOpacity(0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Center(
                    child: Text('YJ',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(kDevName,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('المطور الرئيسي للنظام',
                    style: TextStyle(
                        fontSize: 11,
                        color: s.accentColor,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, color: Color(0xFF25D366), size: 16),
                      SizedBox(width: 6),
                      Text(kDevWhatsapp,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700)),
                    ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _SocialBtn(Icons.chat,
                      () => launchUrl(Uri.parse('https://wa.me/2$kDevWhatsapp'))),
                  const SizedBox(width: 8),
                  _SocialBtn(Icons.email_outlined,
                      () => launchUrl(Uri.parse('mailto:$kAdminEmail'))),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Theme & Default Quality Customizer
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
                  Row(children: [
                    Icon(Icons.palette_outlined,
                        color: s.accentColor, size: 18),
                    const SizedBox(width: 8),
                    const Text('تخصيص المظهر والجودة الافتراضية',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ]),
                  const SizedBox(height: 14),
                  const Text('لون الثيم النشط:',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: themeSwatches.map((c) {
                      final selected = s.accentColor.value == c.value;
                      return GestureDetector(
                        onTap: () => s.saveSettings(newColor: c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: c.withOpacity(0.5),
                                        blurRadius: 12)
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('الجودة الافتراضية للتحميل:',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: s.defaultQuality,
                    dropdownColor: AppColors.surfaceLight,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'auto', child: Text('تلقائي (Auto)')),
                      DropdownMenuItem(value: '4k', child: Text('4K Ultra HD')),
                      DropdownMenuItem(
                          value: '1080', child: Text('FHD 1080p')),
                      DropdownMenuItem(value: '720', child: Text('HD 720p')),
                      DropdownMenuItem(
                          value: 'audio', child: Text('صوت فقط (MP3)')),
                    ],
                    onChanged: (v) {
                      if (v != null) s.saveSettings(newQuality: v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Admin AdSense Config
            if (isAdmin) ...[
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [
                          Icon(Icons.ads_click,
                              color: Color(0xFF4285F4), size: 18),
                          SizedBox(width: 8),
                          Text('إعدادات Google AdSense',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                        ]),
                        Switch(
                          value: s.adsEnabled,
                          activeColor: AppColors.success,
                          onChanged: (v) => s.saveSettings(newAdsEnabled: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AuthField(
                        controller: pubIdCtrl,
                        icon: Icons.fingerprint,
                        hint: 'Publisher ID (pub-xxxxxxxx)'),
                    const SizedBox(height: 8),
                    _AuthField(
                        controller: dispSlotCtrl,
                        icon: Icons.view_headline,
                        hint: 'Display Ad Slot'),
                    const SizedBox(height: 8),
                    _AuthField(
                        controller: inArtSlotCtrl,
                        icon: Icons.article_outlined,
                        hint: 'In-Article Ad Slot'),
                    const SizedBox(height: 8),
                    _AuthField(
                        controller: anchSlotCtrl,
                        icon: Icons.anchor,
                        hint: 'Anchor Ad Slot'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          s.saveSettings(
                            pubId: pubIdCtrl.text.trim(),
                            dispSlot: dispSlotCtrl.text.trim(),
                            inArtSlot: inArtSlotCtrl.text.trim(),
                            anchSlot: anchSlotCtrl.text.trim(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم حفظ إعدادات الإعلانات بنجاح'),
                                backgroundColor: AppColors.success),
                          );
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('حفظ إعدادات AdSense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.accentColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // API Subscription Portal
            if (!s.isGuest) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.api.withOpacity(0.08),
                    AppColors.api.withOpacity(0.02)
                  ]),
                  border: Border.all(color: AppColors.api.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.key, color: AppColors.api, size: 18),
                      SizedBox(width: 8),
                      Text('بوابة المطورين واشتراك API',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14)),
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
                            const Text('مفتاح API الخاص بك:',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Expanded(
                                child: Text(
                                  key.apiKey,
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      color: AppColors.api),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 15),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: key.apiKey));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم نسخ مفتاح API'),
                                        backgroundColor: AppColors.success),
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
                          _TimerBox(value: '${key.daysLeft}', label: 'يوم'),
                          _TimerBox(value: '${key.hoursLeft}', label: 'ساعة'),
                          _TimerBox(
                              value: '${key.minutesLeft}', label: 'دقيقة'),
                          _TimerBox(
                              value: '${key.totalRequests}', label: 'طلب'),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.25)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سعر الاشتراك الشهري: $kApiPrice جنيه عبر فودافون كاش ($kDevWhatsapp). أدخل الكود بالأسفل للتفعيل الفوري.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
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
                          fontSize: 14,
                          color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'DOViD-XXXXXXXXXXXX',
                        hintStyle: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (codeCtrl.text.trim().isEmpty) return;
                          final err = s.activateCode(codeCtrl.text);
                          setState(() {
                            codeError = err;
                            codeSuccess = err == null
                                ? 'تم تفعيل الاشتراك وتوليد مفتاح API بنجاح!'
                                : null;
                          });
                          if (err == null) codeCtrl.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.api,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('تفعيل كود الاشتراك',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    if (codeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(codeError!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 11)),
                      ),
                    if (codeSuccess != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(codeSuccess!,
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // App Info
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
                  Row(children: [
                    Icon(Icons.info_outline, color: s.accentColor, size: 16),
                    const SizedBox(width: 8),
                    const Text('معلومات النظام',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  const _InfoRow('اسم النظام', kAppName),
                  const _InfoRow('المطور', kDevName),
                  const _InfoRow('واتساب المطور', kDevWhatsapp),
                  const _InfoRow('الإصدار', kAppVersion),
                  _InfoRow('الحساب الحالي', s.currentUser?.username ?? 'زائر'),
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
                      title: const Text('تسجيل الخروج',
                          style: TextStyle(color: AppColors.text)),
                      content: const Text('هل تريد تسجيل الخروج من الحساب؟',
                          style: TextStyle(color: AppColors.textMuted)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('خروج',
                                style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  );
                  if (ok == true) s.logout();
                },
                icon:
                    const Icon(Icons.logout, color: AppColors.error, size: 16),
                label: const Text('تسجيل الخروج',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
      Text(value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.api)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.text,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ============================================================================
// ADMIN SCREEN (7 Full Tabs matching PHP Backend 100%)
// ============================================================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  final codeCountCtrl = TextEditingController(text: '5');
  final codeDaysCtrl = TextEditingController(text: '30');
  final ipBlockCtrl = TextEditingController();

  @override
  void dispose() {
    codeCountCtrl.dispose();
    codeDaysCtrl.dispose();
    ipBlockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: const Row(children: [
              Icon(Icons.shield_rounded, color: AppColors.admin, size: 24),
              SizedBox(width: 8),
              Text('لوحة تحكم المدير الشاملة',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.admin)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _AdminTab(
                    label: 'لوحة المعلومات',
                    icon: Icons.dashboard,
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'المستخدمين',
                    icon: Icons.people,
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'التحميلات',
                    icon: Icons.download,
                    active: _tab == 2,
                    onTap: () => setState(() => _tab = 2)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'سجل التخطي',
                    icon: Icons.route,
                    active: _tab == 3,
                    onTap: () => setState(() => _tab = 3)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'محاولات الدخول',
                    icon: Icons.login,
                    active: _tab == 4,
                    onTap: () => setState(() => _tab = 4)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'الأمان والحظر',
                    icon: Icons.security,
                    active: _tab == 5,
                    onTap: () => setState(() => _tab = 5)),
                const SizedBox(width: 8),
                _AdminTab(
                    label: 'أكواد و API',
                    icon: Icons.key,
                    active: _tab == 6,
                    onTap: () => setState(() => _tab = 6)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _OverviewTab(),
                _UsersTab(),
                _DownloadsTab(),
                _BypassLogsTab(),
                _LoginAttemptsTab(),
                _SecurityTab(ipCtrl: ipBlockCtrl),
                _CodesTab(
                    codeCountCtrl: codeCountCtrl, codeDaysCtrl: codeDaysCtrl),
              ],
            ),
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
                  colors: [AppColors.admin, Color(0xFF7C3AED)])
              : null,
          color: active ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? Colors.transparent : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: active ? Colors.white : AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted)),
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
              child: _AdminStat('المستخدمين', s.users.length, AppColors.admin)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'التحميلات', s.downloads.length, AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _AdminStat(
                  'سجل التخطي', s.bypassLogs.length, AppColors.guest)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'IP محظور', s.blockedIps.length, AppColors.error)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _AdminStat('الأكواد', s.codes.length, AppColors.api)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'مفاتيح API', s.apiKeys.length, AppColors.success)),
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
              const Text('ملخص النظام والأمان',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 12),
              const _InfoRow('بريد المدير', kAdminEmail),
              _InfoRow('محاولات تسجيل الدخول', '${s.loginAttempts.length}'),
              _InfoRow('الأكواد المتاحة للتفعيل',
                  '${s.codes.where((c) => c.status == 'active').length}'),
              _InfoRow('الأكواد المستخدمة',
                  '${s.codes.where((c) => c.status == 'used').length}'),
              _InfoRow('مفاتيح API النشطة',
                  '${s.apiKeys.where((k) => k.isActive).length}'),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text('$value',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
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
              child: Icon(u.isAdmin ? Icons.shield : Icons.person,
                  color: u.isAdmin ? AppColors.admin : AppColors.primary,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(u.isAdmin ? '👑 مدير النظام' : 'مستخدم مسجل',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted)),
                  Text(
                      'تاريخ الانضمام: ${DateFormat('yyyy-MM-dd').format(u.createdAt)}',
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textDim)),
                ],
              ),
            ),
            if (!u.isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 18),
                onPressed: () => s.deleteUser(u.id),
              ),
          ]),
        );
      },
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final list = s.allDownloads;
    if (list.isEmpty) {
      return const Center(
          child: Text('لا توجد تحميلات مسجلة',
              style: TextStyle(color: AppColors.textMuted)));
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
              child: Icon(platformIcon(e.platform),
                  color: platformColor(e.platform), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title.isEmpty ? 'فيديو ${e.platform}' : e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(
                      '${owner?.username ?? 'زائر'} • ${e.strategy.isEmpty ? 'direct' : e.strategy} • ${timeAgo(e.createdAt)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
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

class _BypassLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    if (s.bypassLogs.isEmpty) {
      return const Center(
          child: Text('لا يوجد سجل محاولات تخطي حتى الآن',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: s.bypassLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = s.bypassLogs[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(
              b.status == 'success' ? Icons.check_circle : Icons.cancel,
              color: b.status == 'success' ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.strategy,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                  Text(b.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textDim)),
                ],
              ),
            ),
            _MiniTag('${b.responseTimeMs}ms', AppColors.guest),
          ]),
        );
      },
    );
  }
}

class _LoginAttemptsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    if (s.loginAttempts.isEmpty) {
      return const Center(
          child: Text('لا توجد محاولات دخول مسجلة',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: s.loginAttempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final log = s.loginAttempts[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(
              log.success ? Icons.verified_user : Icons.warning_amber_rounded,
              color: log.success ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.username.isEmpty ? 'مجهول' : log.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                  Text('IP: ${log.ip} • ${timeAgo(log.createdAt)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  s.blockIp(log.ip, reason: 'حظر من سجل الدخول'),
              child: const Text('حظر IP',
                  style: TextStyle(color: AppColors.error, fontSize: 11)),
            ),
          ]),
        );
      },
    );
  }
}

class _SecurityTab extends StatelessWidget {
  final TextEditingController ipCtrl;
  const _SecurityTab({required this.ipCtrl});

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
              const Text('حظر عنوان IP يدوياً',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _AuthField(
                      controller: ipCtrl,
                      icon: Icons.security,
                      hint: 'مثال: 192.168.1.50'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (ipCtrl.text.trim().isEmpty) return;
                    s.blockIp(ipCtrl.text.trim());
                    ipCtrl.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  child: const Text('حظر'),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('عناوين IP المحظورة حالياً',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        if (s.blockedIps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('لا توجد عناوين IP محظورة',
                    style: TextStyle(color: AppColors.textMuted))),
          )
        else
          ...s.blockedIps.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.block, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.ip,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800)),
                        Text(b.reason,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => s.unblockIp(b.id),
                    child: const Text('فك الحظر',
                        style:
                            TextStyle(color: AppColors.success, fontSize: 11)),
                  ),
                ]),
              )),
      ],
    );
  }
}

class _CodesTab extends StatelessWidget {
  final TextEditingController codeCountCtrl;
  final TextEditingController codeDaysCtrl;
  const _CodesTab(
      {required this.codeCountCtrl, required this.codeDaysCtrl});

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
              const Text('توليد أكواد اشتراك API جديدة',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: codeCountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                    decoration: _inputDec('عدد الأكواد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: codeDaysCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                    decoration: _inputDec('المدة (أيام)'),
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
                    s.generateCodes(c.clamp(1, 100), d.clamp(1, 365));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('تم توليد $c كود بنجاح'),
                          backgroundColor: AppColors.success),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome,
                      size: 16, color: Colors.black),
                  label: const Text('توليد الأكواد الآن',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.api,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('قائمة الأكواد (${s.codes.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            if (s.codes.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final all = s.codes
                      .where((c) => c.status == 'active')
                      .map((c) => c.code)
                      .join('\n');
                  Clipboard.setData(ClipboardData(text: all));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم نسخ جميع الأكواد المتاحة'),
                        backgroundColor: AppColors.success),
                  );
                },
                icon: const Icon(Icons.copy_all, size: 15),
                label:
                    const Text('نسخ المتاح', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...s.codes.reversed.map((c) => Container(
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
                      Text(c.code,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.api)),
                      Row(children: [
                        Text('${c.durationDays} يوم',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
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
                  icon: const Icon(Icons.copy,
                      size: 16, color: AppColors.textMuted),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: c.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم نسخ الكود'),
                          backgroundColor: AppColors.success),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  onPressed: () => s.deleteCode(c.id),
                ),
              ]),
            )),
      ],
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
      );
}