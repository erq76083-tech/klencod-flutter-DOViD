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
const String kAppVersion = 'v6.0 Ultra Pro';
const String kApiEndpoint = 'https://zecora0.serv00.net/download/download.php';
const String kApiPrice = '100';
const String kAdminEmail = 'guhfyuggu7@gmail.com';
const String kAdminUsername = 'admin';
const String kAdminPassword = 'guhfyuggu7@855A';

// ============================================================================
// THEME COLORS (Matte Dark & Comfortable Palette)
// ============================================================================
class AppColors {
  static const primary = Color(0xFFF97316);
  static const primaryDark = Color(0xFFEA580C);
  static const secondary = Color(0xFFEF4444);
  static const bg = Color(0xFF07080D);
  static const surface = Color(0xFF11131F);
  static const surfaceLight = Color(0xFF1A1D2E);
  static const surfaceLighter = Color(0xFF24283E);
  static const border = Color(0x18FFFFFF);
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
  String author;
  String thumbnailUrl;
  String durationText;
  String fileSizeText;
  String platform;
  String downloadLink;
  String hdLink;
  String audioLink;
  String localPath;
  String quality;
  String status;
  String strategy;
  bool isFavorite;
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadEntry({
    required this.id,
    required this.userId,
    required this.url,
    this.title = '',
    this.author = '',
    this.thumbnailUrl = '',
    this.durationText = '',
    this.fileSizeText = '',
    this.platform = 'unknown',
    this.downloadLink = '',
    this.hdLink = '',
    this.audioLink = '',
    this.localPath = '',
    this.quality = 'auto',
    this.status = 'pending',
    this.strategy = '',
    this.isFavorite = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'url': url,
        'title': title,
        'author': author,
        'thumbnailUrl': thumbnailUrl,
        'durationText': durationText,
        'fileSizeText': fileSizeText,
        'platform': platform,
        'downloadLink': downloadLink,
        'hdLink': hdLink,
        'audioLink': audioLink,
        'localPath': localPath,
        'quality': quality,
        'status': status,
        'strategy': strategy,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> j) => DownloadEntry(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        url: j['url'] ?? '',
        title: j['title'] ?? '',
        author: j['author'] ?? '',
        thumbnailUrl: j['thumbnailUrl'] ?? '',
        durationText: j['durationText'] ?? '',
        fileSizeText: j['fileSizeText'] ?? '',
        platform: j['platform'] ?? 'unknown',
        downloadLink: j['downloadLink'] ?? '',
        hdLink: j['hdLink'] ?? '',
        audioLink: j['audioLink'] ?? '',
        localPath: j['localPath'] ?? '',
        quality: j['quality'] ?? 'auto',
        status: j['status'] ?? 'pending',
        strategy: j['strategy'] ?? '',
        isFavorite: j['isFavorite'] ?? false,
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

class ActiveDownloadTask {
  final String entryId;
  final String title;
  double progress;
  int receivedBytes;
  int totalBytes;
  double speedKBps;
  String status; // 'downloading', 'completed', 'failed', 'canceled'
  bool isCanceled;

  ActiveDownloadTask({
    required this.entryId,
    required this.title,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedKBps = 0.0,
    this.status = 'downloading',
    this.isCanceled = false,
  });
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
  bool autoSaveAfterExtract = false;
  bool autoDetectClipboard = true;
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

  // Active Download Tasks
  final Map<String, ActiveDownloadTask> activeTasks = {};

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
    try {
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
            .map((e) =>
                LoginAttemptEntry.fromJson(Map<String, dynamic>.from(e)))
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
            .map((e) =>
                SubscriptionCode.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    // Load Settings
    final colorVal = _prefs!.getInt('theme_color_int');
    if (colorVal != null) accentColor = Color(colorVal);
    defaultQuality = _prefs!.getString('default_quality') ?? 'auto';
    autoSaveAfterExtract = _prefs!.getBool('auto_save_extract') ?? false;
    autoDetectClipboard = _prefs!.getBool('auto_detect_clipboard') ?? true;
    adsEnabled = _prefs!.getBool('ads_enabled') ?? false;
    adsensePublisherId = _prefs!.getString('adsense_publisher_id') ?? '';
    adsenseDisplaySlot = _prefs!.getString('adsense_display_slot') ?? '';
    adsenseInArticleSlot = _prefs!.getString('adsense_inarticle_slot') ?? '';
    adsenseAnchorSlot = _prefs!.getString('adsense_anchor_slot') ?? '';
  }

  Future<void> saveSettings({
    Color? newColor,
    String? newQuality,
    bool? newAutoSave,
    bool? newAutoDetectClipboard,
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
    if (newAutoSave != null) {
      autoSaveAfterExtract = newAutoSave;
      await _prefs?.setBool('auto_save_extract', newAutoSave);
    }
    if (newAutoDetectClipboard != null) {
      autoDetectClipboard = newAutoDetectClipboard;
      await _prefs?.setBool('auto_detect_clipboard', newAutoDetectClipboard);
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
    if (bypassLogs.length > 250) {
      bypassLogs = bypassLogs.sublist(0, 250);
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

    final user = users
        .where((u) => u.username.toLowerCase() == username.toLowerCase())
        .firstOrNull;
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

  List<DownloadEntry> get savedDeviceFiles {
    return myDownloads.where((d) => d.localPath.isNotEmpty).toList();
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
    String? author,
    String? thumbnailUrl,
    String? durationText,
    String? fileSizeText,
    String? link,
    String? hdLink,
    String? audioLink,
    String? localPath,
    String? status,
    String? strategy,
    bool? isFavorite,
  }) async {
    if (title != null && title.isNotEmpty) entry.title = title;
    if (author != null && author.isNotEmpty) entry.author = author;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      entry.thumbnailUrl = thumbnailUrl;
    }
    if (durationText != null && durationText.isNotEmpty) {
      entry.durationText = durationText;
    }
    if (fileSizeText != null && fileSizeText.isNotEmpty) {
      entry.fileSizeText = fileSizeText;
    }
    if (link != null) entry.downloadLink = link;
    if (hdLink != null) entry.hdLink = hdLink;
    if (audioLink != null) entry.audioLink = audioLink;
    if (localPath != null) entry.localPath = localPath;
    if (status != null) entry.status = status;
    if (strategy != null) entry.strategy = strategy;
    if (isFavorite != null) entry.isFavorite = isFavorite;
    if (status == 'success' || status == 'failed') {
      entry.completedAt = DateTime.now();
    }
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> toggleFavorite(DownloadEntry entry) async {
    entry.isFavorite = !entry.isFavorite;
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> deleteDownloadItem(String id, {bool deleteLocalFile = false}) async {
    final target = downloads.where((d) => d.id == id).firstOrNull;
    if (target != null && deleteLocalFile && target.localPath.isNotEmpty) {
      try {
        final f = File(target.localPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    downloads.removeWhere((d) => d.id == id);
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

  void updateActiveTask(ActiveDownloadTask task) {
    activeTasks[task.entryId] = task;
    notifyListeners();
  }

  void cancelTask(String entryId) {
    final t = activeTasks[entryId];
    if (t != null) {
      t.isCanceled = true;
      t.status = 'canceled';
      notifyListeners();
    }
  }

  void removeActiveTask(String entryId) {
    activeTasks.remove(entryId);
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
  if (u.contains('facebook.com') || u.contains('fb.watch') || u.contains('fb.gg')) {
    return 'facebook';
  }
  if (u.contains('twitter.com') || u.contains('x.com') || u.contains('t.co')) {
    return 'twitter';
  }
  if (u.contains('snapchat.com')) return 'snapchat';
  if (u.contains('pinterest.com') || u.contains('pin.it')) return 'pinterest';
  if (u.contains('vimeo.com')) return 'vimeo';
  if (u.contains('dailymotion.com') || u.contains('dai.ly')) return 'dailymotion';
  if (u.contains('reddit.com') || u.contains('redd.it')) return 'reddit';
  return 'unknown';
}

String? extractYoutubeId(String url) {
  final regExp = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
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
    case 'reddit':
      return Icons.forum;
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
    case 'reddit':
      return const Color(0xFFFF4500);
    default:
      return AppState().accentColor;
  }
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return DateFormat('yyyy-MM-dd').format(dt);
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  var i = (log(bytes) / log(1024)).floor();
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
}

String formatDurationSeconds(int seconds) {
  if (seconds <= 0) return '';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m >= 60) {
    final h = m ~/ 60;
    final remM = m % 60;
    return '$h:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ============================================================================
// SMART MULTI-STRATEGY DOWNLOAD, PREVIEW & FILE STREAMING SERVICE
// ============================================================================
class DownloadService {
  static Future<String> _resolveShortUrl(String url) async {
    final lowerUrl = url.toLowerCase();
    if (!lowerUrl.contains('vt.tiktok.com') &&
        !lowerUrl.contains('vm.tiktok.com') &&
        !lowerUrl.contains('fb.watch') &&
        !lowerUrl.contains('pin.it') &&
        !lowerUrl.contains('t.co')) {
      return url;
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      client.badCertificateCallback = (_, __, ___) => true;
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 6;
      final response = await request.close();
      String finalUrl = url;
      if (response.redirects.isNotEmpty) {
        final loc = response.redirects.last.location;
        finalUrl = loc.isAbsolute ? loc.toString() : Uri.parse(url).resolveUri(loc).toString();
      }
      await response.drain();
      client.close();
      return finalUrl;
    } catch (_) {
      return url;
    }
  }

  /// استخراج بيانات المعاينة السريعة (الصورة المصغرة، العنوان، القناة) من الرابط مباشرة
  static Future<Map<String, String>> fetchQuickPreviewMetadata(String rawUrl) async {
    final result = <String, String>{
      'title': '',
      'author': '',
      'thumbnail': '',
      'platform': detectPlatform(rawUrl),
    };

    final ytId = extractYoutubeId(rawUrl);
    if (ytId != null) {
      result['thumbnail'] = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
      try {
        final oembedUrl =
            'https://noembed.com/embed?url=${Uri.encodeComponent('https://www.youtube.com/watch?v=$ytId')}';
        final res = await http
            .get(Uri.parse(oembedUrl))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          result['title'] = (data['title'] ?? '').toString();
          result['author'] = (data['author_name'] ?? '').toString();
          if ((data['thumbnail_url'] ?? '').toString().isNotEmpty) {
            result['thumbnail'] = data['thumbnail_url'].toString();
          }
        }
      } catch (_) {}
      return result;
    }

    try {
      final noembed =
          'https://noembed.com/embed?url=${Uri.encodeComponent(rawUrl)}';
      final res = await http
          .get(Uri.parse(noembed))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['title'] != null) result['title'] = data['title'].toString();
        if (data['author_name'] != null) {
          result['author'] = data['author_name'].toString();
        }
        if (data['thumbnail_url'] != null) {
          result['thumbnail'] = data['thumbnail_url'].toString();
        }
      }
    } catch (_) {}

    return result;
  }

  /// تطبيع البيانات القادمة من أي سيرفر لاستخراج الرابط، الصورة، العنوان، الحجم، والمدة
  static Map<String, dynamic>? _normalizeServerPayload(
    dynamic rawJson,
    String originalUrl,
    String quality,
  ) {
    if (rawJson is! Map) return null;
    final map = Map<String, dynamic>.from(rawJson);

    String link = '';
    String hdLink = '';
    String audioLink = '';
    String title = (map['title'] ?? map['desc'] ?? map['text'] ?? '').toString();
    String author = (map['author'] is Map
            ? (map['author']['nickname'] ?? map['author']['unique_id'] ?? '')
            : (map['author'] ?? map['uploader'] ?? map['owner'] ?? ''))
        .toString();
    String thumb = (map['thumbnail'] ??
            map['cover'] ??
            map['origin_cover'] ??
            map['picture'] ??
            map['image'] ??
            '')
        .toString();
    String durationText = '';
    String fileSizeText = '';

    // فحص حقل المدة
    if (map['duration'] != null) {
      final d = int.tryParse(map['duration'].toString());
      if (d != null && d > 0) {
        durationText = formatDurationSeconds(d);
      } else {
        durationText = map['duration'].toString();
      }
    }

    // فحص الحجم
    if (map['size'] != null || map['hd_size'] != null) {
      final s = int.tryParse((map['hd_size'] ?? map['size']).toString());
      if (s != null && s > 0) {
        fileSizeText = formatBytes(s);
      }
    }

    // استخراج الروابط المباشرة المحتملة
    final candidates = [
      map['answer'],
      map['url'],
      map['download_url'],
      map['video_url'],
      map['hdplay'],
      map['play'],
      map['nwm_video_url'],
      map['wmplay'],
    ];
    for (final c in candidates) {
      if (c is String && c.startsWith('http')) {
        link = c;
        break;
      }
    }

    if (map['hdplay'] is String && map['hdplay'].toString().startsWith('http')) {
      hdLink = map['hdplay'].toString();
    }
    if (map['music'] is String && map['music'].toString().startsWith('http')) {
      audioLink = map['music'].toString();
    } else if (map['audio'] is String &&
        map['audio'].toString().startsWith('http')) {
      audioLink = map['audio'].toString();
    }

    // فحص لو كانت البيانات بداخل كائن data أو result فرعي
    if (link.isEmpty && map['data'] is Map) {
      final sub = _normalizeServerPayload(map['data'], originalUrl, quality);
      if (sub != null) return sub;
    }
    if (link.isEmpty && map['result'] is Map) {
      final sub = _normalizeServerPayload(map['result'], originalUrl, quality);
      if (sub != null) return sub;
    }

    // فحص مصفوفة medias أو formats أو links
    final mediaLists = [map['medias'], map['formats'], map['links'], map['urls']];
    for (final listCandidate in mediaLists) {
      if (listCandidate is List && listCandidate.isNotEmpty) {
        for (final item in listCandidate) {
          if (item is Map) {
            final u = (item['url'] ?? item['link'] ?? item['download'] ?? '')
                .toString();
            final q = (item['quality'] ?? item['ext'] ?? item['type'] ?? '')
                .toString()
                .toLowerCase();
            if (u.startsWith('http')) {
              if (link.isEmpty) link = u;
              if (q.contains('hd') || q.contains('1080') || q.contains('720')) {
                hdLink = u;
              }
              if (q.contains('mp3') || q.contains('audio') || q.contains('m4a')) {
                audioLink = u;
              }
            }
          } else if (item is String && item.startsWith('http') && link.isEmpty) {
            link = item;
          }
        }
      }
    }

    if (quality == 'audio' && audioLink.isNotEmpty) {
      link = audioLink;
    } else if ((quality == '4k' || quality == '1080') && hdLink.isNotEmpty) {
      link = hdLink;
    }

    if (link.isEmpty) return null;

    final ytId = extractYoutubeId(originalUrl);
    if (thumb.isEmpty && ytId != null) {
      thumb = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }

    return {
      'status': 'success',
      'answer': link,
      'hdLink': hdLink.isNotEmpty ? hdLink : link,
      'audioLink': audioLink,
      'title': title,
      'author': author,
      'thumbnail': thumb,
      'duration': durationText,
      'fileSize': fileSizeText,
    };
  }

  static Future<Map<String, dynamic>> download(
    String originalUrl, {
    String quality = 'auto',
    void Function(String strategyName)? onStrategyTrying,
  }) async {
    final url = await _resolveShortUrl(originalUrl);
    final platform = detectPlatform(url);

    // جلب بيانات المعاينة الأولية بالتوازي لتعزيز النتيجة
    final quickMetaFuture = fetchQuickPreviewMetadata(url);

    const desktopUserAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    final headers = {
      'User-Agent': desktopUserAgent,
      'Referer': url,
      'Accept': 'application/json, text/plain, */*',
    };

    // ترتيب المحركات بذكاء: إذا كان الرابط TikTok يبدأ بمحرك TikWM فائق السرعة
    final strategies =
        <String, Future<Map<String, dynamic>?> Function(String)>{
      if (platform == 'tiktok')
        'tikwm_ultra_hd': (u) => _tikwmFallback(u, quality),
      'direct_post_json': (u) => _directPostJson(u, headers, quality),
      'direct_post_form': (u) => _directPostForm(u, headers, quality),
      'direct_get_query': (u) => _directGetQuery(u, headers, quality),
      if (platform != 'tiktok')
        'tikwm_engine': (u) => _tikwmFallback(u, quality),
      'cobalt_multi_engine': (u) => _cobaltEngine(u, quality),
      'allorigins_post': (u) => _alloriginsPost(u, headers, quality),
      'allorigins_get': (u) => _alloriginsGet(u, headers, quality),
      'corsproxy_post': (u) => _corsproxy(u, headers, quality),
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
          final quickMeta = await quickMetaFuture;
          if ((result['title'] ?? '').toString().trim().isEmpty &&
              (quickMeta['title'] ?? '').isNotEmpty) {
            result['title'] = quickMeta['title'];
          }
          if ((result['author'] ?? '').toString().trim().isEmpty &&
              (quickMeta['author'] ?? '').isNotEmpty) {
            result['author'] = quickMeta['author'];
          }
          if ((result['thumbnail'] ?? '').toString().trim().isEmpty &&
              (quickMeta['thumbnail'] ?? '').isNotEmpty) {
            result['thumbnail'] = quickMeta['thumbnail'];
          }
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
          'تعذر استخراج الفيديو عبر جميع محركات التخطي الذكية. تأكد من أن الفيديو عام وليس خاصاً.',
    };
  }

  static Future<Map<String, dynamic>?> _directPostJson(
      String url, Map<String, String> headers, String quality) async {
    try {
      final res = await http
          .post(
            Uri.parse(kApiEndpoint),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url, 'url': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
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
            body: {'text': url, 'url': url, 'quality': quality},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _directGetQuery(
      String url, Map<String, String> headers, String quality) async {
    try {
      final target =
          '$kApiEndpoint?text=${Uri.encodeComponent(url)}&url=${Uri.encodeComponent(url)}&quality=$quality';
      final res = await http
          .get(Uri.parse(target), headers: headers)
          .timeout(const Duration(seconds: 18));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
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
      ).timeout(const Duration(seconds: 16));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['code'] == 0 && j['data'] != null) {
          final d = j['data'];
          String fixUrl(dynamic raw) {
            final s = (raw ?? '').toString();
            if (s.isEmpty) return '';
            if (s.startsWith('http')) return s;
            return 'https://www.tikwm.com$s';
          }

          final hd = fixUrl(d['hdplay']);
          final play = fixUrl(d['play']);
          final wm = fixUrl(d['wmplay']);
          final music = fixUrl(d['music']);
          final cover = fixUrl(d['origin_cover'] ?? d['cover']);

          final chosenLink = (quality == 'audio' && music.isNotEmpty)
              ? music
              : (hd.isNotEmpty ? hd : (play.isNotEmpty ? play : wm));

          if (chosenLink.isNotEmpty) {
            final durSec = int.tryParse((d['duration'] ?? '0').toString()) ?? 0;
            final sizeBytes =
                int.tryParse((d['hd_size'] ?? d['size'] ?? '0').toString()) ??
                    0;
            return {
              'status': 'success',
              'answer': chosenLink,
              'hdLink': hd.isNotEmpty ? hd : play,
              'audioLink': music,
              'title': (d['title'] ?? 'فيديو TikTok بدون علامة مائية').toString(),
              'author': (d['author'] is Map
                      ? (d['author']['nickname'] ?? d['author']['unique_id'] ?? '')
                      : '')
                  .toString(),
              'thumbnail': cover,
              'duration': formatDurationSeconds(durSec),
              'fileSize': sizeBytes > 0 ? formatBytes(sizeBytes) : '',
              'quality': quality == 'audio' ? 'MP3 Audio' : 'HD No-Watermark',
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _cobaltEngine(
      String url, String quality) async {
    try {
      final res = await http
          .post(
            Uri.parse('https://api.cobalt.tools/api/json'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'url': url,
              'vQuality': quality == '4k'
                  ? 'max'
                  : (quality == '720' ? '720' : '1080'),
              'isAudioOnly': quality == 'audio',
            }),
          )
          .timeout(const Duration(seconds: 16));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final link = (j['url'] ?? '').toString();
        if (link.startsWith('http')) {
          return {
            'status': 'success',
            'answer': link,
            'hdLink': link,
            'audioLink': quality == 'audio' ? link : '',
            'title': (j['filename'] ?? '').toString(),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsPost(
      String url, Map<String, String> headers, String quality) async {
    try {
      final proxy =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http
          .post(
            Uri.parse(proxy),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsGet(
      String url, Map<String, String> headers, String quality) async {
    try {
      final target = '$kApiEndpoint?text=${Uri.encodeComponent(url)}';
      final proxy =
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(target)}&timestamp=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http
          .get(Uri.parse(proxy), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final wrapper = jsonDecode(res.body);
        if (wrapper['contents'] != null) {
          return _normalizeServerPayload(
              jsonDecode(wrapper['contents']), url, quality);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _corsproxy(
      String url, Map<String, String> headers, String quality) async {
    try {
      final proxy =
          'https://corsproxy.io/?${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http
          .post(
            Uri.parse(proxy),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  /// إيجاد أفضل مجلد متاح وقابل للكتابة على الهاتف بدون أخطاء صلاحيات
  static Future<Directory> _resolveWritableDirectory() async {
    final candidates = [
      '/storage/emulated/0/Download/DOViD',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies/DOViD',
      '/storage/emulated/0/DCIM/DOViD',
      '/sdcard/Download',
    ];

    for (final path in candidates) {
      try {
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        // اختبار الكتابة الفعلية داخل المجلد
        final probeFile =
            File('${dir.path}/.dovid_probe_${DateTime.now().microsecondsSinceEpoch}');
        await probeFile.writeAsString('ok');
        await probeFile.delete();
        return dir;
      } catch (_) {
        continue;
      }
    }
    return Directory.systemTemp;
  }

  /// تنزيل مباشر للملف داخل ذاكرة الهاتف مع حساب السرعة اللحظية والحجم ودعم الإلغاء
  static Future<String?> downloadFileToDevice({
    required DownloadEntry entry,
    required bool isAudio,
    String? overrideUrl,
    void Function(ActiveDownloadTask task)? onTaskUpdate,
  }) async {
    final targetUrl = (overrideUrl != null && overrideUrl.isNotEmpty)
        ? overrideUrl
        : (isAudio && entry.audioLink.isNotEmpty
            ? entry.audioLink
            : entry.downloadLink);

    if (targetUrl.isEmpty) return null;

    final task = ActiveDownloadTask(
      entryId: entry.id,
      title: entry.title.isEmpty ? 'فيديو ${entry.platform}' : entry.title,
    );
    AppState().updateActiveTask(task);
    onTaskUpdate?.call(task);

    HttpClient? client;
    IOSink? sink;
    try {
      final referers = {
        'youtube': 'https://www.youtube.com/',
        'instagram': 'https://www.instagram.com/',
        'tiktok': 'https://www.tiktok.com/',
        'facebook': 'https://www.facebook.com/',
        'twitter': 'https://x.com/',
      };

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      client.badCertificateCallback = (_, __, ___) => true;

      final req = await client.getUrl(Uri.parse(targetUrl));
      req.followRedirects = true;
      req.maxRedirects = 8;
      req.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36');
      req.headers.set('Accept', '*/*');
      req.headers.set('Connection', 'keep-alive');
      if (referers.containsKey(entry.platform)) {
        req.headers.set('Referer', referers[entry.platform]!);
      }

      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 206) {
        task.status = 'failed';
        AppState().removeActiveTask(entry.id);
        client.close();
        return null;
      }

      final cleanName = entry.title
          .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s\-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final stamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      final safeBase = cleanName.isEmpty
          ? 'DOViD_${entry.platform}_$stamp'
          : '${cleanName.length > 42 ? cleanName.substring(0, 42) : cleanName}_$stamp';
      final ext = isAudio ? 'mp3' : 'mp4';

      final targetDir = await _resolveWritableDirectory();
      final filePath = '${targetDir.path}/$safeBase.$ext';
      final file = File(filePath);
      sink = file.openWrite();

      final totalBytes = res.contentLength;
      task.totalBytes = totalBytes > 0 ? totalBytes : 0;
      int received = 0;
      final sw = Stopwatch()..start();
      int lastTickMs = 0;

      await for (final chunk in res) {
        if (task.isCanceled) {
          await sink.close();
          if (await file.exists()) await file.delete();
          client.close();
          AppState().removeActiveTask(entry.id);
          return null;
        }

        sink.add(chunk);
        received += chunk.length;
        task.receivedBytes = received;

        if (totalBytes > 0) {
          task.progress = (received / totalBytes).clamp(0.0, 1.0);
        } else {
          // تقدم تقديري سلس إذا لم يرسل السيرفر Content-Length
          task.progress = (1.0 - (1.0 / (1.0 + received / (1024 * 1024 * 4))))
              .clamp(0.05, 0.95);
        }

        final nowMs = sw.elapsedMilliseconds;
        if (nowMs - lastTickMs >= 180) {
          lastTickMs = nowMs;
          final elapsedSec = nowMs / 1000.0;
          if (elapsedSec > 0) {
            task.speedKBps = (received / 1024.0) / elapsedSec;
          }
          AppState().updateActiveTask(task);
          onTaskUpdate?.call(task);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      task.progress = 1.0;
      task.status = 'completed';
      final finalSize = formatBytes(received);
      await AppState().updateDownload(
        entry,
        localPath: filePath,
        fileSizeText: finalSize,
      );
      AppState().removeActiveTask(entry.id);
      onTaskUpdate?.call(task);
      return filePath;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
      task.status = 'failed';
      AppState().removeActiveTask(entry.id);
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
    await Future.delayed(const Duration(milliseconds: 240));
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
                  color: AppColors.surface.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
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
                              color: accent.withOpacity(0.35),
                              blurRadius: 28,
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
                      '$kAppName $kAppVersion - استوديو التحميل والمعاينة الذكي',
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
        color: AppColors.error.withOpacity(0.12),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
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
                  color: accent.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
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
// MAIN SCREEN (with Studio, History, Settings & Admin)
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
          const StudioScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
          if (isAdmin) const AdminScreen(),
        ];
        final items = <_NavItem>[
          _NavItem(Icons.home_rounded, 'الرئيسية'),
          _NavItem(Icons.video_library_rounded, 'الاستوديو',
              badgeCount: s.savedDeviceFiles.length),
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
                child: Column(
                  children: [
                    if (s.activeTasks.isNotEmpty) _ActiveDownloadsBanner(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: KeyedSubtree(
                          key: ValueKey<int>(_tab),
                          child: pages[_tab],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.96),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? color.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(it.icon,
                                      size: 22,
                                      color:
                                          active ? color : AppColors.textMuted),
                                  if (it.badgeCount > 0)
                                    Positioned(
                                      top: -4,
                                      left: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: s.accentColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${it.badgeCount}',
                                          style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                it.label,
                                style: TextStyle(
                                    fontSize: 10,
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
  final int badgeCount;
  _NavItem(this.icon, this.label, {this.admin = false, this.badgeCount = 0});
}

class _ActiveDownloadsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final tasks = s.activeTasks.values.toList();
    if (tasks.isEmpty) return const SizedBox.shrink();
    final t = tasks.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.accentColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: s.accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جاري التنزيل: ${t.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${t.speedKBps.toStringAsFixed(0)} KB/s',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => s.cancelTask(t.entryId),
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: t.progress,
            backgroundColor: AppColors.bg,
            color: s.accentColor,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
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
            top: -190 + sin(t) * 40,
            right: -140 + cos(t) * 40,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.11), Colors.transparent],
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
                  colors: [Color(0x148B5CF6), Colors.transparent],
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
// HOME SCREEN (Smart Preview, Batch Mode, Auto Clipboard & Instant Download)
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
  bool previewLoading = false;
  bool batchMode = false;
  String? error;
  DownloadEntry? result;
  Map<String, String>? quickPreview;
  String loadingText = 'جاري الاتصال بالسيرفر الذكي...';
  String currentStrategy = 'direct_post_json';
  String? detectedClipboardLink;
  Timer? _debounce;

  final qualities = const [
    {'key': 'auto', 'label': 'تلقائي ذكي', 'icon': Icons.auto_awesome},
    {'key': '4k', 'label': '4K Ultra HD', 'icon': Icons.hd},
    {'key': '1080', 'label': 'FHD 1080p', 'icon': Icons.tv},
    {'key': '720', 'label': 'HD 720p', 'icon': Icons.phone_android},
    {'key': 'audio', 'label': 'صوت MP3 نقي', 'icon': Icons.music_note},
  ];

  @override
  void initState() {
    super.initState();
    quality = AppState().defaultQuality;
    if (AppState().autoDetectClipboard) {
      _checkClipboardForLink();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardForLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final txt = data?.text?.trim() ?? '';
      if (txt.startsWith('http') &&
          detectPlatform(txt) != 'unknown' &&
          txt != urlCtrl.text.trim()) {
        if (!mounted) return;
        setState(() => detectedClipboardLink = txt);
      }
    } catch (_) {}
  }

  void _onUrlChanged(String val) {
    setState(() {});
    _debounce?.cancel();
    final clean = val.trim();
    if (!batchMode && clean.startsWith('http') && clean.length > 12) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _triggerQuickPreview(clean);
      });
    } else {
      setState(() => quickPreview = null);
    }
  }

  Future<void> _triggerQuickPreview(String url) async {
    if (!mounted) return;
    setState(() => previewLoading = true);
    final meta = await DownloadService.fetchQuickPreviewMetadata(url);
    if (!mounted) return;
    setState(() {
      previewLoading = false;
      if ((meta['title'] ?? '').isNotEmpty ||
          (meta['thumbnail'] ?? '').isNotEmpty) {
        quickPreview = meta;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = data?.text?.trim() ?? '';
    if (txt.isNotEmpty) {
      setState(() {
        urlCtrl.text = txt;
        detectedClipboardLink = null;
        error = null;
      });
      _onUrlChanged(txt);
    }
  }

  Future<void> _download() async {
    final rawText = urlCtrl.text.trim();
    if (rawText.isEmpty) {
      setState(() => error = 'يرجى لصق رابط الفيديو أولاً');
      return;
    }

    final urls = batchMode
        ? rawText
            .split(RegExp(r'[\r\n]+'))
            .map((s) => s.trim())
            .where((s) => s.startsWith('http'))
            .toList()
        : [rawText];

    if (urls.isEmpty || !urls.first.startsWith('http')) {
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
    DownloadEntry? lastSuccess;

    for (int idx = 0; idx < urls.length; idx++) {
      final currentUrl = urls[idx];
      final entry = await s.addDownload(currentUrl, quality);

      final response = await DownloadService.download(
        currentUrl,
        quality: quality,
        onStrategyTrying: (st) {
          if (!mounted) return;
          setState(() {
            currentStrategy = st;
            loadingText = urls.length > 1
                ? 'جاري استخراج (${idx + 1}/${urls.length}) عبر: $st'
                : 'محاولة الاستخراج عبر المحرك: $st';
          });
        },
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        final link = (response['answer'] ?? response['url'] ?? '').toString();
        final hdLink = (response['hdLink'] ?? link).toString();
        final audioLink = (response['audioLink'] ?? '').toString();
        final title =
            (response['title'] ?? quickPreview?['title'] ?? 'فيديو ${entry.platform}')
                .toString();
        final author =
            (response['author'] ?? quickPreview?['author'] ?? '').toString();
        final thumb =
            (response['thumbnail'] ?? quickPreview?['thumbnail'] ?? '')
                .toString();
        final duration = (response['duration'] ?? '').toString();
        final fileSize = (response['fileSize'] ?? '').toString();
        final strategy = (response['strategy'] ?? 'direct').toString();

        await s.updateDownload(
          entry,
          title: title,
          author: author,
          thumbnailUrl: thumb,
          durationText: duration,
          fileSizeText: fileSize,
          link: link,
          hdLink: hdLink,
          audioLink: audioLink,
          status: 'success',
          strategy: strategy,
        );
        lastSuccess = entry;

        if (s.autoSaveAfterExtract) {
          _saveVideoFile(entry, isAudio: quality == 'audio');
        }
      } else {
        await s.updateDownload(entry, status: 'failed');
        if (urls.length == 1) {
          setState(() {
            loading = false;
            error = (response['message'] ?? 'فشل جلب الرابط، حاول مرة أخرى')
                .toString();
          });
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      result = lastSuccess;
      loading = false;
    });
  }

  Future<void> _saveVideoFile(
    DownloadEntry e, {
    bool isAudio = false,
    String? customUrl,
  }) async {
    if (AppState().activeTasks.containsKey(e.id)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'بدأ تنزيل ${isAudio ? "الملف الصوتي MP3" : "الفيديو MP4"} إلى ذاكرة الهاتف...'),
        backgroundColor: AppState().accentColor,
        duration: const Duration(seconds: 2),
      ),
    );

    final savedPath = await DownloadService.downloadFileToDevice(
      entry: e,
      isAudio: isAudio,
      overrideUrl: customUrl,
    );

    if (!mounted) return;

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ الملف في جهازك بنجاح:\n$savedPath'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      final fallbackUrl = customUrl ?? e.downloadLink;
      final uri = Uri.tryParse(fallbackUrl);
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
            // Clipboard Smart Radar
            if (detectedClipboardLink != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_motion,
                        color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم اكتشاف رابط ${detectPlatform(detectedClipboardLink!).toUpperCase()} في الحافظة!',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: accent),
                          ),
                          Text(
                            detectedClipboardLink!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final link = detectedClipboardLink!;
                        setState(() {
                          urlCtrl.text = link;
                          detectedClipboardLink = null;
                        });
                        _onUrlChanged(link);
                        _download();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('لصق وتحميل',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),

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
                      label: 'محفوظ بالهاتف',
                      value: s.savedDeviceFiles.length,
                      color: AppColors.guest)),
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
                          Text('$kAppName $kAppVersion',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      InkWell(
                        onTap: () => setState(() => batchMode = !batchMode),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: batchMode
                                ? AppColors.admin.withOpacity(0.18)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: batchMode
                                  ? AppColors.admin
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.dynamic_feed,
                                  size: 13,
                                  color: batchMode
                                      ? AppColors.admin
                                      : AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                batchMode ? 'تحميل متعدد (نشط)' : 'تحميل متعدد',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: batchMode
                                      ? AppColors.admin
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlCtrl,
                          maxLines: batchMode ? 4 : 1,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 13),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: batchMode
                                ? 'ضع كل رابط فيديو في سطر مستقل لتحميلها دفعة واحدة...'
                                : 'الصق رابط الفيديو (YouTube, TikTok, Instagram...)',
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
                                      quickPreview = null;
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
                          onChanged: _onUrlChanged,
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

                  // Instant Live Preview Card before clicking download
                  if (previewLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (quickPreview != null && result == null) ...[
                    const SizedBox(height: 12),
                    _InstantLinkPreviewBanner(
                      meta: quickPreview!,
                      onQuickInspect: () => _showVideoPreviewModal(
                        context,
                        title: quickPreview!['title'] ?? 'معاينة الفيديو',
                        author: quickPreview!['author'] ?? '',
                        thumbnailUrl: quickPreview!['thumbnail'] ?? '',
                        sourceUrl: urlCtrl.text.trim(),
                        streamUrl: '',
                        platform: quickPreview!['platform'] ?? 'unknown',
                      ),
                    ),
                  ],

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
                    label: batchMode
                        ? 'بدء استخراج وتحميل القائمة'
                        : 'استخراج ومعاينة الفيديو الآن',
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
                        Text('المحرك النشط: $currentStrategy',
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
                    const SizedBox(height: 16),
                    _RichResultPreviewCard(
                      entry: result!,
                      onDownloadVideo: () =>
                          _saveVideoFile(result!, isAudio: false),
                      onDownloadHd: () => _saveVideoFile(
                        result!,
                        isAudio: false,
                        customUrl: result!.hdLink.isNotEmpty
                            ? result!.hdLink
                            : result!.downloadLink,
                      ),
                      onDownloadAudio: () =>
                          _saveVideoFile(result!, isAudio: true),
                      onOpenPreviewModal: () => _showVideoPreviewModal(
                        context,
                        title: result!.title,
                        author: result!.author,
                        thumbnailUrl: result!.thumbnailUrl,
                        sourceUrl: result!.url,
                        streamUrl: result!.downloadLink,
                        platform: result!.platform,
                        duration: result!.durationText,
                        fileSize: result!.fileSizeText,
                      ),
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
                  const Text('المنصات المدعومة بالمعاينة والتحميل المباشر',
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
            if (s.myDownloads.isNotEmpty)
              _RecentDownloads(
                onDownloadTap: (e) =>
                    _saveVideoFile(e, isAudio: e.quality == 'audio'),
                onPreviewTap: (e) => _showVideoPreviewModal(
                  context,
                  title: e.title,
                  author: e.author,
                  thumbnailUrl: e.thumbnailUrl,
                  sourceUrl: e.url,
                  streamUrl: e.downloadLink,
                  platform: e.platform,
                  duration: e.durationText,
                  fileSize: e.fileSizeText,
                ),
              ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _InstantLinkPreviewBanner extends StatelessWidget {
  final Map<String, String> meta;
  final VoidCallback onQuickInspect;
  const _InstantLinkPreviewBanner({
    required this.meta,
    required this.onQuickInspect,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = meta['thumbnail'] ?? '';
    final title = meta['title'] ?? '';
    final author = meta['author'] ?? '';
    final platform = meta['platform'] ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumb.isNotEmpty
                ? Image.network(
                    thumb,
                    width: 72,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 52,
                      color: AppColors.surfaceLighter,
                      child: Icon(platformIcon(platform),
                          color: platformColor(platform)),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 52,
                    color: AppColors.surfaceLighter,
                    child: Icon(platformIcon(platform),
                        color: platformColor(platform)),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: platformColor(platform).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'معاينة فورية • ${platform.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: platformColor(platform),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'الرابط جاهز للاستخراج والتحميل' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
                if (author.isNotEmpty)
                  Text(
                    'القناة / الحساب: $author',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQuickInspect,
            icon: const Icon(Icons.visibility_outlined,
                size: 18, color: AppColors.textMuted),
            tooltip: 'معاينة التفاصيل',
          ),
        ],
      ),
    );
  }
}

class _RichResultPreviewCard extends StatelessWidget {
  final DownloadEntry entry;
  final VoidCallback onDownloadVideo;
  final VoidCallback onDownloadHd;
  final VoidCallback onDownloadAudio;
  final VoidCallback onOpenPreviewModal;

  const _RichResultPreviewCard({
    required this.entry,
    required this.onDownloadVideo,
    required this.onDownloadHd,
    required this.onDownloadAudio,
    required this.onOpenPreviewModal,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final activeTask = s.activeTasks[entry.id];
    final isDownloading = activeTask != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.success.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interactive Thumbnail Banner with Play Preview Overlay
          GestureDetector(
            onTap: onOpenPreviewModal,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (entry.thumbnailUrl.isNotEmpty)
                  Image.network(
                    entry.thumbnailUrl,
                    width: double.infinity,
                    height: 185,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FallbackThumbBanner(
                        platform: entry.platform),
                  )
                else
                  _FallbackThumbBanner(platform: entry.platform),
                Container(
                  width: double.infinity,
                  height: 185,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x99000000), Color(0x22000000), Color(0xCC000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Play Preview Button
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: s.accentColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: s.accentColor.withOpacity(0.5),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 34),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text('جاهز للمعاينة والتنزيل',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                if (entry.durationText.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.durationText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('اضغط لمعاينة وتشغيل الفيديو',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title.isEmpty
                            ? 'فيديو ${entry.platform}'
                            : entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                    IconButton(
                      onPressed: () => s.toggleFavorite(entry),
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: entry.isFavorite
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                      tooltip: 'حفظ في المفضلة',
                    ),
                  ],
                ),
                if (entry.author.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الناشر: ${entry.author}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _MiniTag(entry.platform.toUpperCase(),
                      platformColor(entry.platform)),
                  _MiniTag(entry.quality.toUpperCase(), AppColors.success),
                  if (entry.fileSizeText.isNotEmpty)
                    _MiniTag(entry.fileSizeText, AppColors.guest),
                  _MiniTag(entry.strategy, AppColors.textMuted),
                ]),

                if (isDownloading) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: activeTask.progress,
                    backgroundColor: AppColors.bg,
                    color: AppColors.success,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'جاري الحفظ بالهاتف... ${(activeTask.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${formatBytes(activeTask.receivedBytes)} • ${activeTask.speedKBps.toStringAsFixed(0)} KB/s',
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],

                if (entry.localPath.isNotEmpty && !isDownloading) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_special,
                            size: 15, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'محفوظ على الهاتف: ${entry.localPath}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // Primary Download Buttons Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isDownloading ? null : onDownloadHd,
                        icon: const Icon(Icons.download_rounded,
                            size: 17, color: Colors.black),
                        label: Text(
                          isDownloading
                              ? 'جاري التنزيل...'
                              : 'تنزيل الفيديو MP4 HD',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isDownloading ? null : onDownloadAudio,
                        icon: const Icon(Icons.music_note,
                            size: 15, color: Colors.white),
                        label: const Text(
                          'صوت MP3',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Secondary Preview & Copy Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenPreviewModal,
                        icon: const Icon(Icons.play_circle_outline, size: 15),
                        label: const Text('معاينة وتشغيل مباشر',
                            style: TextStyle(fontSize: 11.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: entry.downloadLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم نسخ الرابط المباشر للفيديو'),
                                backgroundColor: AppColors.success),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('نسخ الرابط المباشر',
                            style: TextStyle(fontSize: 11.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
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

class _FallbackThumbBanner extends StatelessWidget {
  final String platform;
  const _FallbackThumbBanner({required this.platform});

  @override
  Widget build(BuildContext context) {
    final c = platformColor(platform);
    return Container(
      width: double.infinity,
      height: 185,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.withOpacity(0.28),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(platformIcon(platform),
            size: 56, color: c.withOpacity(0.45)),
      ),
    );
  }
}

/// نافذة المعاينة المتكاملة للفيديو (تشمل الصورة عالية الدقة، بيانات البث، وتشغيل الفيديو في المشغل المدمج أو الخارجي)
void _showVideoPreviewModal(
  BuildContext context, {
  required String title,
  required String author,
  required String thumbnailUrl,
  required String sourceUrl,
  required String streamUrl,
  required String platform,
  String duration = '',
  String fileSize = '',
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final accent = AppState().accentColor;
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.smart_display_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'استوديو معاينة الفيديو المباشر',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _FallbackThumbBanner(platform: platform),
                    )
                  else
                    _FallbackThumbBanner(platform: platform),
                  Container(
                    width: double.infinity,
                    height: 210,
                    color: Colors.black38,
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final target =
                          streamUrl.isNotEmpty ? streamUrl : sourceUrl;
                      final uri = Uri.tryParse(target);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.inAppWebView);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'تشغيل الفيديو الآن داخل التطبيق',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title.isEmpty ? 'فيديو $platform' : title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('القناة / الناشر: $author',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniTag('المنصة: ${platform.toUpperCase()}',
                    platformColor(platform)),
                if (duration.isNotEmpty)
                  _MiniTag('المدة: $duration', AppColors.api),
                if (fileSize.isNotEmpty)
                  _MiniTag('الحجم: $fileSize', AppColors.guest),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final target =
                          streamUrl.isNotEmpty ? streamUrl : sourceUrl;
                      final uri = Uri.tryParse(target);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('فتح في مشغل الهاتف الخارجي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLighter,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.secondary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Center(
            child: Text('DV',
                style: TextStyle(
                    fontSize: 27,
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
        const Text('YOSSEF VID $kAppVersion',
            style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.2)),
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
  final void Function(DownloadEntry entry) onDownloadTap;
  final void Function(DownloadEntry entry) onPreviewTap;

  const _RecentDownloads({
    required this.onDownloadTap,
    required this.onPreviewTap,
  });

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
              const Text('آخر التحميلات والمعاينات',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            Text('${s.myDownloads.length} عنصر',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 12),
          ...recent.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => onPreviewTap(e),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: e.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              e.thumbnailUrl,
                              width: 48,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _SmallPlatformBox(
                                  platform: e.platform),
                            )
                          : _SmallPlatformBox(platform: e.platform),
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
                          Text(
                              '${timeAgo(e.createdAt)}${e.fileSizeText.isNotEmpty ? " • ${e.fileSizeText}" : ""}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (e.downloadLink.isNotEmpty)
                      IconButton(
                        onPressed: () => onDownloadTap(e),
                        icon: Icon(
                          e.localPath.isNotEmpty
                              ? Icons.check_circle
                              : Icons.download_for_offline_outlined,
                          color: e.localPath.isNotEmpty
                              ? AppColors.success
                              : s.accentColor,
                          size: 20,
                        ),
                      ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

class _SmallPlatformBox extends StatelessWidget {
  final String platform;
  const _SmallPlatformBox({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 40,
      decoration: BoxDecoration(
        color: platformColor(platform).withOpacity(0.12),
        border:
            Border.all(color: platformColor(platform).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(platformIcon(platform),
          color: platformColor(platform), size: 18),
    );
  }
}

// ============================================================================
// STUDIO SCREEN (Saved Device Files & Active Downloads Manager)
// ============================================================================
class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final saved = s.savedDeviceFiles;
        final favorites = s.myDownloads.where((d) => d.isFavorite).toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Icon(Icons.video_library_rounded, color: s.accentColor),
                const SizedBox(width: 8),
                const Text('استوديو الملفات المحفوظة بالهاتف',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 12),
            if (saved.isEmpty && favorites.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 64,
                        color: AppColors.textDim.withOpacity(0.35)),
                    const SizedBox(height: 12),
                    const Text('لا توجد فيديوهات محفوظة على الهاتف بعد',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                        'اضغط على "تنزيل الفيديو MP4 HD" بعد استخراج أي رابط لحفظه هنا',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textDim)),
                  ],
                ),
              ),
            if (saved.isNotEmpty) ...[
              Text('تم تنزيلها على جهازك (${saved.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.success)),
              const SizedBox(height: 10),
              ...saved.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: e.thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      e.thumbnailUrl,
                                      width: 70,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _SmallPlatformBox(
                                              platform: e.platform),
                                    )
                                  : _SmallPlatformBox(platform: e.platform),
                            ),
                            const SizedBox(width: 10),
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
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    e.localPath,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.success),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (e.fileSizeText.isNotEmpty)
                                        _MiniTag(
                                            e.fileSizeText, AppColors.guest),
                                      _MiniTag(e.quality, AppColors.api),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showVideoPreviewModal(
                                context,
                                title: e.title,
                                author: e.author,
                                thumbnailUrl: e.thumbnailUrl,
                                sourceUrl: e.url,
                                streamUrl: e.downloadLink,
                                platform: e.platform,
                                duration: e.durationText,
                                fileSize: e.fileSizeText,
                              ),
                              icon: Icon(Icons.play_circle_fill,
                                  color: s.accentColor, size: 28),
                            ),
                            IconButton(
                              onPressed: () => s.deleteDownloadItem(e.id,
                                  deleteLocalFile: true),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('الفيديوهات المفضلة (${favorites.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.warning)),
              const SizedBox(height: 10),
              ...favorites.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _SmallPlatformBox(platform: e.platform),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.title.isEmpty ? e.url : e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: () => s.toggleFavorite(e),
                          icon: const Icon(Icons.bookmark_remove,
                              color: AppColors.warning, size: 18),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ============================================================================
// HISTORY SCREEN (With Search, Platform Filter & Direct File Save)
// ============================================================================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String searchQuery = '';
  String selectedPlatform = 'all';

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final rawList = s.myDownloads;
        final list = rawList.where((e) {
          final matchesPlatform =
              selectedPlatform == 'all' || e.platform == selectedPlatform;
          final matchesSearch = searchQuery.isEmpty ||
              e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.url.toLowerCase().contains(searchQuery.toLowerCase());
          return matchesPlatform && matchesSearch;
        }).toList();

        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(Icons.history, color: s.accentColor),
              const SizedBox(width: 8),
              const Text('سجل التنزيلات والمعاينات',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              if (rawList.isNotEmpty)
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
                  label: const Text('مسح الكل',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
            ]),
          ),
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'ابحث في سجل الفيديوهات بالاسم أو الرابط...',
                hintStyle:
                    const TextStyle(fontSize: 11.5, color: AppColors.textDim),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                        const Text('لا توجد عناصر مطابقة في السجل',
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
                      final isSaving = s.activeTasks.containsKey(e.id);
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          GestureDetector(
                            onTap: () => _showVideoPreviewModal(
                              context,
                              title: e.title,
                              author: e.author,
                              thumbnailUrl: e.thumbnailUrl,
                              sourceUrl: e.url,
                              streamUrl: e.downloadLink,
                              platform: e.platform,
                              duration: e.durationText,
                              fileSize: e.fileSizeText,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: e.thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      e.thumbnailUrl,
                                      width: 56,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _SmallPlatformBox(
                                              platform: e.platform),
                                    )
                                  : _SmallPlatformBox(platform: e.platform),
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
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(e.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textDim)),
                                const SizedBox(height: 5),
                                Wrap(spacing: 6, runSpacing: 4, children: [
                                  _MiniTag(e.platform, s.accentColor),
                                  _MiniTag(e.quality, AppColors.success),
                                  if (e.fileSizeText.isNotEmpty)
                                    _MiniTag(e.fileSizeText, AppColors.guest),
                                  _MiniTag(timeAgo(e.createdAt),
                                      AppColors.textMuted),
                                ]),
                                if (e.status == 'success' &&
                                    e.downloadLink.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 6, runSpacing: 6, children: [
                                    _SmallBtn(
                                      label: isSaving
                                          ? 'جاري الحفظ...'
                                          : (e.localPath.isNotEmpty
                                              ? 'تم الحفظ بالهاتف'
                                              : 'حفظ بالهاتف'),
                                      icon: e.localPath.isNotEmpty
                                          ? Icons.check_circle
                                          : Icons.download_rounded,
                                      color: e.localPath.isNotEmpty
                                          ? AppColors.success
                                          : s.accentColor,
                                      onTap: () async {
                                        if (isSaving) return;
                                        final saved = await DownloadService
                                            .downloadFileToDevice(
                                          entry: e,
                                          isAudio: e.quality == 'audio',
                                        );
                                        if (!context.mounted) return;
                                        if (saved != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'تم الحفظ في: $saved'),
                                                backgroundColor:
                                                    AppColors.success),
                                          );
                                        }
                                      },
                                    ),
                                    _SmallBtn(
                                      label: 'معاينة',
                                      icon: Icons.play_circle_outline,
                                      color: AppColors.guest,
                                      onTap: () => _showVideoPreviewModal(
                                        context,
                                        title: e.title,
                                        author: e.author,
                                        thumbnailUrl: e.thumbnailUrl,
                                        sourceUrl: e.url,
                                        streamUrl: e.downloadLink,
                                        platform: e.platform,
                                        duration: e.durationText,
                                        fileSize: e.fileSizeText,
                                      ),
                                    ),
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
                          IconButton(
                            onPressed: () => s.deleteDownloadItem(e.id),
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.textDim),
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
// SETTINGS SCREEN (Theme Customizer, Smart Automation, AdSense & API Portal)
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
                          color: s.accentColor.withOpacity(0.35),
                          blurRadius: 24,
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

            // Theme & Smart Download Preferences
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
                    const Text('تخصيص المظهر والتحميل الذكي',
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
                      final selected =
                          s.accentColor.value == c.value;
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.autoSaveAfterExtract,
                    activeColor: s.accentColor,
                    title: const Text('حفظ تلقائي بالهاتف فور الاستخراج',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'بدء تنزيل ملف الفيديو مباشرة بمجرد نجاح استخراج الرابط',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted)),
                    onChanged: (v) => s.saveSettings(newAutoSave: v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.autoDetectClipboard,
                    activeColor: s.accentColor,
                    title: const Text('رادار الحافظة الذكي',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'التعرف تلقائياً على روابط الفيديوهات المنسوخة',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted)),
                    onChanged: (v) =>
                        s.saveSettings(newAutoDetectClipboard: v),
                  ),
                  const SizedBox(height: 8),
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
                  border:
                      Border.all(color: AppColors.api.withOpacity(0.25)),
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
                  side:
                      BorderSide(color: AppColors.error.withOpacity(0.3)),
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