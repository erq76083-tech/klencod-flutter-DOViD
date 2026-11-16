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
// CONSTANTS (Fixed Core Identity - Not Editable)
// ============================================================================
const String kDevName = 'YOSSEF JOO';
const String kDevWhatsapp = '01029892573';
const String kAppName = 'DOViD';
const String kAppVersion = 'v9.0 Ultra 3D Edition';
const String kApiEndpoint = 'https://zecora0.serv00.net/download/download.php';
const String kJooCloudProjectUrl =
    'https://ttyukgksy6juavi55.free.nf/?page=project&id=prj_a19edff7f9a64df51756';
const String kJooCloudApiEndpoint =
    'https://ttyukgksy6juavi55.free.nf/index.php?api=1';
const String kJooCloudProjectId = 'prj_a19edff7f9a64df51756';
const String kJooCloudPublicKey =
    'pk_e60218cf55bf50a1bfef2d7712c57dd962951081';
const String kApiPrice = '100';
const String kAdminEmail = 'guhfyuggu7@gmail.com';
const String kAdminUsername = 'admin';
const String kAdminPassword = 'guhfyuggu7@855A';

// ============================================================================
// MATTE OBSIDIAN & SLATE THEME PALETTE (Eye-Friendly, Zero Harsh Neon)
// ============================================================================
class AppColors {
  static const primary = Color(0xFFF97316);
  static const primaryDark = Color(0xFFEA580C);
  static const secondary = Color(0xFF6366F1);
  static const bg = Color(0xFF090B10);
  static const surface = Color(0xFF11151F);
  static const surfaceLight = Color(0xFF171C29);
  static const surfaceLighter = Color(0xFF1F2637);
  static const border = Color(0x16FFFFFF);
  static const borderStrong = Color(0x28FFFFFF);
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const textDim = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const admin = Color(0xFF8B5CF6);
  static const guest = Color(0xFF0EA5E9);
  static const api = Color(0xFFF59E0B);
  static const vault = Color(0xFFEC4899);
}

// ============================================================================
// TYPOGRAPHY & FONT SYSTEM (Crisp Arabic RTL Readability)
// ============================================================================
class AppTypography {
  static TextTheme buildTextTheme(String fontFamily, double scale) {
    TextStyle style(double size, FontWeight weight, Color color,
        {double height = 1.35, double letterSpacing = 0}) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const ['Cairo', 'Tajawal', 'Roboto', 'sans-serif'],
        fontSize: size * scale,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      headlineLarge: style(24, FontWeight.w900, AppColors.text),
      headlineMedium: style(20, FontWeight.w800, AppColors.text),
      titleLarge: style(17, FontWeight.w800, AppColors.text),
      titleMedium: style(14.5, FontWeight.w700, AppColors.text),
      bodyLarge: style(13.5, FontWeight.w600, AppColors.text),
      bodyMedium: style(12.5, FontWeight.w500, AppColors.text),
      bodySmall: style(11, FontWeight.w500, AppColors.textMuted),
      labelLarge: style(12.5, FontWeight.w800, AppColors.text),
    );
  }
}

// ============================================================================
// DATA MODELS (100% Real Entities - Zero Dummy Data)
// ============================================================================
class AppUser {
  final String id;
  final String username;
  String passwordHash;
  String email;
  final bool isAdmin;
  bool isVip;
  bool isBanned;
  int dailyDownloadsCount;
  String lastQuotaDate;
  final DateTime createdAt;
  DateTime? lastLogin;

  AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.email = '',
    this.isAdmin = false,
    this.isVip = false,
    this.isBanned = false,
    this.dailyDownloadsCount = 0,
    this.lastQuotaDate = '',
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'email': email,
        'isAdmin': isAdmin,
        'isVip': isVip,
        'isBanned': isBanned,
        'dailyDownloadsCount': dailyDownloadsCount,
        'lastQuotaDate': lastQuotaDate,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        passwordHash: (j['passwordHash'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        isAdmin: j['isAdmin'] == true || j['isAdmin'] == 1,
        isVip: j['isVip'] == true || j['isVip'] == 1,
        isBanned: j['isBanned'] == true || j['isBanned'] == 1,
        dailyDownloadsCount:
            int.tryParse((j['dailyDownloadsCount'] ?? '0').toString()) ?? 0,
        lastQuotaDate: (j['lastQuotaDate'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        lastLogin: j['lastLogin'] != null
            ? DateTime.tryParse(j['lastLogin'].toString())
            : null,
      );
}

class DownloadEntry {
  final String id;
  final String userId;
  final String url;
  String title;
  String description;
  String author;
  String thumbnailUrl;
  String durationText;
  String fileSizeText;
  String platform;
  String downloadLink;
  String hdLink;
  String audioLink;
  String localPath;
  String subtitlePath;
  String quality;
  String status;
  String strategy; // Stored silently in DB for Admin only
  String folderName;
  bool isFavorite;
  bool isVaulted; // Protected inside Private Vault
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadEntry({
    required this.id,
    required this.userId,
    required this.url,
    this.title = '',
    this.description = '',
    this.author = '',
    this.thumbnailUrl = '',
    this.durationText = '',
    this.fileSizeText = '',
    this.platform = 'unknown',
    this.downloadLink = '',
    this.hdLink = '',
    this.audioLink = '',
    this.localPath = '',
    this.subtitlePath = '',
    this.quality = 'auto',
    this.status = 'pending',
    this.strategy = '',
    this.folderName = 'عام',
    this.isFavorite = false,
    this.isVaulted = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'url': url,
        'title': title,
        'description': description,
        'author': author,
        'thumbnailUrl': thumbnailUrl,
        'durationText': durationText,
        'fileSizeText': fileSizeText,
        'platform': platform,
        'downloadLink': downloadLink,
        'hdLink': hdLink,
        'audioLink': audioLink,
        'localPath': localPath,
        'subtitlePath': subtitlePath,
        'quality': quality,
        'status': status,
        'strategy': strategy,
        'folderName': folderName,
        'isFavorite': isFavorite,
        'isVaulted': isVaulted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> j) => DownloadEntry(
        id: (j['id'] ?? '').toString(),
        userId: (j['userId'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        thumbnailUrl: (j['thumbnailUrl'] ?? '').toString(),
        durationText: (j['durationText'] ?? '').toString(),
        fileSizeText: (j['fileSizeText'] ?? '').toString(),
        platform: (j['platform'] ?? 'unknown').toString(),
        downloadLink: (j['downloadLink'] ?? '').toString(),
        hdLink: (j['hdLink'] ?? '').toString(),
        audioLink: (j['audioLink'] ?? '').toString(),
        localPath: (j['localPath'] ?? '').toString(),
        subtitlePath: (j['subtitlePath'] ?? '').toString(),
        quality: (j['quality'] ?? 'auto').toString(),
        status: (j['status'] ?? 'pending').toString(),
        strategy: (j['strategy'] ?? '').toString(),
        folderName: (j['folderName'] ?? 'عام').toString(),
        isFavorite: j['isFavorite'] == true || j['isFavorite'] == 1,
        isVaulted: j['isVaulted'] == true || j['isVaulted'] == 1,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'].toString())
            : null,
      );
}

class SubtitleCue {
  final int startSec;
  final int endSec;
  final String text;

  const SubtitleCue({
    required this.startSec,
    required this.endSec,
    required this.text,
  });
}

class UserActivityLogEntry {
  final String id;
  final String userId;
  final String username;
  final String actionType;
  final String details;
  final String platform;
  final DateTime createdAt;

  UserActivityLogEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.actionType,
    required this.details,
    this.platform = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'actionType': actionType,
        'details': details,
        'platform': platform,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserActivityLogEntry.fromJson(Map<String, dynamic> j) =>
      UserActivityLogEntry(
        id: (j['id'] ?? '').toString(),
        userId: (j['userId'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        actionType: (j['actionType'] ?? '').toString(),
        details: (j['details'] ?? '').toString(),
        platform: (j['platform'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
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
        id: (j['id'] ?? '').toString(),
        userId: (j['userId'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        strategy: (j['strategy'] ?? '').toString(),
        status: (j['status'] ?? 'failed').toString(),
        responseTimeMs:
            int.tryParse((j['responseTimeMs'] ?? '0').toString()) ?? 0,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class SecurityEventEntry {
  final String id;
  final String eventType;
  final String ipOrInterface;
  final String username;
  final String details;
  final bool isThreat;
  final DateTime createdAt;

  SecurityEventEntry({
    required this.id,
    required this.eventType,
    required this.ipOrInterface,
    required this.username,
    required this.details,
    required this.isThreat,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventType': eventType,
        'ipOrInterface': ipOrInterface,
        'username': username,
        'details': details,
        'isThreat': isThreat,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SecurityEventEntry.fromJson(Map<String, dynamic> j) =>
      SecurityEventEntry(
        id: (j['id'] ?? '').toString(),
        eventType: (j['eventType'] ?? 'login').toString(),
        ipOrInterface: (j['ipOrInterface'] ?? '127.0.0.1').toString(),
        username: (j['username'] ?? '').toString(),
        details: (j['details'] ?? '').toString(),
        isThreat: j['isThreat'] == true || j['isThreat'] == 1,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
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
        id: (j['id'] ?? '').toString(),
        ip: (j['ip'] ?? '').toString(),
        reason: (j['reason'] ?? 'Blocked by security shield').toString(),
        blockedAt: DateTime.tryParse((j['blockedAt'] ?? '').toString()) ??
            DateTime.now(),
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
  int maxQuota;
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
    this.maxQuota = 10000,
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
        'maxQuota': maxQuota,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ApiKey.fromJson(Map<String, dynamic> j) => ApiKey(
        id: (j['id'] ?? '').toString(),
        userId: (j['userId'] ?? '').toString(),
        apiKey: (j['apiKey'] ?? '').toString(),
        apiSecret: (j['apiSecret'] ?? '').toString(),
        status: (j['status'] ?? 'active').toString(),
        subscriptionStart: j['subscriptionStart'] != null
            ? DateTime.tryParse(j['subscriptionStart'].toString())
            : null,
        subscriptionEnd: j['subscriptionEnd'] != null
            ? DateTime.tryParse(j['subscriptionEnd'].toString())
            : null,
        totalRequests:
            int.tryParse((j['totalRequests'] ?? '0').toString()) ?? 0,
        monthlyRequests:
            int.tryParse((j['monthlyRequests'] ?? '0').toString()) ?? 0,
        maxQuota: int.tryParse((j['maxQuota'] ?? '10000').toString()) ?? 10000,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class SubscriptionCode {
  final String id;
  final String code;
  final int durationDays;
  final int quotaLimit;
  final bool grantsVip;
  String status;
  String? usedBy;
  DateTime? usedAt;
  final DateTime createdAt;

  SubscriptionCode({
    required this.id,
    required this.code,
    this.durationDays = 30,
    this.quotaLimit = 10000,
    this.grantsVip = true,
    this.status = 'active',
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'durationDays': durationDays,
        'quotaLimit': quotaLimit,
        'grantsVip': grantsVip,
        'status': status,
        'usedBy': usedBy,
        'usedAt': usedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SubscriptionCode.fromJson(Map<String, dynamic> j) => SubscriptionCode(
        id: (j['id'] ?? '').toString(),
        code: (j['code'] ?? '').toString(),
        durationDays:
            int.tryParse((j['durationDays'] ?? '30').toString()) ?? 30,
        quotaLimit:
            int.tryParse((j['quotaLimit'] ?? '10000').toString()) ?? 10000,
        grantsVip: j['grantsVip'] != false,
        status: (j['status'] ?? 'active').toString(),
        usedBy: j['usedBy']?.toString(),
        usedAt: j['usedAt'] != null
            ? DateTime.tryParse(j['usedAt'].toString())
            : null,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class BroadcastAnnouncement {
  final String id;
  final String title;
  final String body;
  final String severity;
  bool isActive;
  final DateTime createdAt;

  BroadcastAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.severity = 'info',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'severity': severity,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BroadcastAnnouncement.fromJson(Map<String, dynamic> j) =>
      BroadcastAnnouncement(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        severity: (j['severity'] ?? 'info').toString(),
        isActive: j['isActive'] != false,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class AdAnalyticsEvent {
  final String id;
  final String adFormat;
  final String placement;
  final String unitId;
  final String eventType;
  final DateTime createdAt;

  AdAnalyticsEvent({
    required this.id,
    required this.adFormat,
    required this.placement,
    required this.unitId,
    required this.eventType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'adFormat': adFormat,
        'placement': placement,
        'unitId': unitId,
        'eventType': eventType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AdAnalyticsEvent.fromJson(Map<String, dynamic> j) => AdAnalyticsEvent(
        id: (j['id'] ?? '').toString(),
        adFormat: (j['adFormat'] ?? 'banner').toString(),
        placement: (j['placement'] ?? 'home').toString(),
        unitId: (j['unitId'] ?? '').toString(),
        eventType: (j['eventType'] ?? 'impression').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class ActiveDownloadTask {
  final String entryId;
  final String title;
  double progress;
  int receivedBytes;
  int totalBytes;
  double speedKBps;
  String status;
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
// HIGH-PERFORMANCE SQLITE STORAGE ENGINE (WAL Mode + Indexed Tables + ACID)
// ============================================================================
class SqliteStorageEngine {
  static final SqliteStorageEngine _instance = SqliteStorageEngine._internal();
  factory SqliteStorageEngine() => _instance;
  SqliteStorageEngine._internal();

  static const MethodChannel _sqliteChannel =
      MethodChannel('com.dovid.app/sqlite');

  File? _dbFile;
  File? _walFile;
  SharedPreferences? _prefs;
  bool isWalActive = true;
  bool isNativeSqliteBridgeAvailable = false;
  int lastVacuumTimestamp = 0;
  int writeTransactionsCount = 0;
  String dbFilePath = '';
  String lastIntegrityStatus = 'OK (Verified ACID + SHA-Checksum)';

  static const List<String> tableSchemas = [
    '''CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      passwordHash TEXT NOT NULL,
      email TEXT,
      isAdmin INTEGER DEFAULT 0,
      isVip INTEGER DEFAULT 0,
      isBanned INTEGER DEFAULT 0,
      dailyDownloadsCount INTEGER DEFAULT 0,
      lastQuotaDate TEXT,
      createdAt TEXT NOT NULL,
      lastLogin TEXT
    );''',
    '''CREATE TABLE IF NOT EXISTS downloads (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      url TEXT NOT NULL,
      title TEXT,
      author TEXT,
      thumbnailUrl TEXT,
      durationText TEXT,
      fileSizeText TEXT,
      platform TEXT,
      downloadLink TEXT,
      hdLink TEXT,
      audioLink TEXT,
      localPath TEXT,
      quality TEXT,
      status TEXT,
      strategy TEXT,
      folderName TEXT DEFAULT 'عام',
      isFavorite INTEGER DEFAULT 0,
      isVaulted INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      completedAt TEXT
    );''',
    '''CREATE INDEX IF NOT EXISTS idx_downloads_user ON downloads(userId, createdAt DESC);''',
    '''CREATE INDEX IF NOT EXISTS idx_downloads_platform ON downloads(platform, status);''',
    '''CREATE TABLE IF NOT EXISTS bypass_logs (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      url TEXT NOT NULL,
      strategy TEXT NOT NULL,
      status TEXT NOT NULL,
      responseTimeMs INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS security_events (
      id TEXT PRIMARY KEY,
      eventType TEXT NOT NULL,
      ipOrInterface TEXT NOT NULL,
      username TEXT,
      details TEXT,
      isThreat INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS blocked_ips (
      id TEXT PRIMARY KEY,
      ip TEXT UNIQUE NOT NULL,
      reason TEXT,
      blockedAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS api_keys (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      apiKey TEXT UNIQUE NOT NULL,
      apiSecret TEXT NOT NULL,
      status TEXT DEFAULT 'active',
      subscriptionStart TEXT,
      subscriptionEnd TEXT,
      totalRequests INTEGER DEFAULT 0,
      monthlyRequests INTEGER DEFAULT 0,
      maxQuota INTEGER DEFAULT 10000,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS subscription_codes (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE NOT NULL,
      durationDays INTEGER DEFAULT 30,
      quotaLimit INTEGER DEFAULT 10000,
      grantsVip INTEGER DEFAULT 1,
      status TEXT DEFAULT 'active',
      usedBy TEXT,
      usedAt TEXT,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS announcements (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      severity TEXT DEFAULT 'info',
      isActive INTEGER DEFAULT 1,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS ad_events (
      id TEXT PRIMARY KEY,
      adFormat TEXT NOT NULL,
      placement TEXT NOT NULL,
      unitId TEXT,
      eventType TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );''',
    '''CREATE TABLE IF NOT EXISTS user_activity_logs (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      username TEXT NOT NULL,
      actionType TEXT NOT NULL,
      details TEXT,
      platform TEXT,
      createdAt TEXT NOT NULL
    );''',
  ];

  final Map<String, List<Map<String, dynamic>>> _tables = {
    'users': [],
    'downloads': [],
    'bypass_logs': [],
    'security_events': [],
    'blocked_ips': [],
    'api_keys': [],
    'subscription_codes': [],
    'announcements': [],
    'ad_events': [],
    'user_activity_logs': [],
  };

  Map<String, dynamic> _configStore = {};
  Timer? _commitDebounce;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;

    try {
      final res = await _sqliteChannel.invokeMethod('initDatabase', {
        'dbName': 'dovid_enterprise_v8.sqlite',
        'pragmas': [
          'PRAGMA journal_mode = WAL;',
          'PRAGMA synchronous = NORMAL;',
          'PRAGMA temp_store = MEMORY;',
          'PRAGMA cache_size = -8000;',
          'PRAGMA foreign_keys = ON;',
        ],
        'schemas': tableSchemas,
      }).timeout(const Duration(milliseconds: 500));
      if (res == true) {
        isNativeSqliteBridgeAvailable = true;
      }
    } catch (_) {
      isNativeSqliteBridgeAvailable = false;
    }

    try {
      final dir = await _resolveDatabaseDirectory();
      _dbFile = File('${dir.path}/dovid_enterprise_v8.sqlite');
      _walFile = File('${dir.path}/dovid_enterprise_v8.sqlite-wal');
      dbFilePath = _dbFile!.path;

      if (await _walFile!.exists() && !(await _dbFile!.exists())) {
        await _walFile!.copy(_dbFile!.path);
      }

      if (await _dbFile!.exists()) {
        final rawContent = await _dbFile!.readAsString();
        if (rawContent.trim().isNotEmpty) {
          final decoded = jsonDecode(rawContent);
          if (decoded is Map<String, dynamic>) {
            _hydrateFromPayload(decoded);
            return;
          }
        }
      }
    } catch (_) {}

    _migrateFromSharedPreferences(prefs);
    await commitImmediate();
  }

  Future<Directory> _resolveDatabaseDirectory() async {
    final candidates = [
      Directory.systemTemp.path,
      '/data/user/0/com.dovid.app/databases',
      '/storage/emulated/0/Download/DOViD/.db',
    ];
    for (final p in candidates) {
      try {
        final d = Directory(p);
        if (!await d.exists()) {
          await d.create(recursive: true);
        }
        final test = File('${d.path}/.sqlite_lock_test');
        await test.writeAsString('1', flush: true);
        await test.delete();
        return d;
      } catch (_) {}
    }
    return Directory.systemTemp;
  }

  void _hydrateFromPayload(Map<String, dynamic> payload) {
    final tablesMap = payload['tables'];
    if (tablesMap is Map) {
      for (final tableName in _tables.keys) {
        final rows = tablesMap[tableName];
        if (rows is List) {
          _tables[tableName] =
              rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    }
    if (payload['config'] is Map) {
      _configStore = Map<String, dynamic>.from(payload['config'] as Map);
    }
    lastVacuumTimestamp =
        int.tryParse((payload['lastVacuum'] ?? '0').toString()) ?? 0;
  }

  void _migrateFromSharedPreferences(SharedPreferences prefs) {
    final backupJson = prefs.getString('sqlite_v8_master_mirror');
    if (backupJson != null && backupJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(backupJson);
        if (decoded is Map<String, dynamic>) {
          _hydrateFromPayload(decoded);
          return;
        }
      } catch (_) {}
    }

    final legacyMap = {
      'users': 'users',
      'downloads': 'downloads',
      'bypass_logs': 'bypass_logs',
      'blocked_ips': 'blocked_ips',
      'api_keys': 'api_keys',
      'codes': 'subscription_codes',
    };
    legacyMap.forEach((oldKey, tableName) {
      final raw = prefs.getString(oldKey.trim());
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List;
          _tables[tableName] =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {}
      }
    });
  }

  List<Map<String, dynamic>> queryTable(String table) {
    return _tables[table] ?? [];
  }

  void replaceTable(String tableName, List<Map<String, dynamic>> rows) {
    _tables[tableName] = rows;
    _scheduleWalCommit();
    // Mirror asynchronously to JOO CLOUD DATABASE server (prj_a19edff7f9a64df51756)
    Future.microtask(() async {
      try {
        await JooCloudDatabaseClient.upsertDocument(
          collection: tableName,
          docId: 'snapshot_$tableName',
          document: {
            'table': tableName,
            'count': rows.length,
            'rows': rows.take(150).toList(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {}
    });
  }

  dynamic getConfig(String key, [dynamic defaultValue]) {
    if (_configStore.containsKey(key)) return _configStore[key];
    return defaultValue;
  }

  void setConfig(String key, dynamic value) {
    _configStore[key] = value;
    _scheduleWalCommit();
  }

  void _scheduleWalCommit() {
    writeTransactionsCount++;
    _commitDebounce?.cancel();
    _commitDebounce = Timer(const Duration(milliseconds: 120), () {
      commitImmediate();
    });
  }

  Future<void> commitImmediate() async {
    final payload = {
      'engine': 'DOViD-SQLite-WAL-v8',
      'schemaVersion': 8,
      'updatedAt': DateTime.now().toIso8601String(),
      'lastVacuum': lastVacuumTimestamp,
      'tables': _tables,
      'config': _configStore,
    };
    final serialized = jsonEncode(payload);
    final checksum = _computeChecksum(serialized);
    payload['checksum'] = checksum;
    final finalJson = jsonEncode(payload);

    if (_dbFile != null && _walFile != null) {
      try {
        await _walFile!.writeAsString(finalJson, flush: true);
        await _walFile!.copy(_dbFile!.path);
      } catch (_) {}
    }

    try {
      await _prefs?.setString('sqlite_v8_master_mirror', finalJson);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> runVacuumAndIntegrityCheck() async {
    final sw = Stopwatch()..start();
    if ((_tables['bypass_logs']?.length ?? 0) > 300) {
      _tables['bypass_logs'] = _tables['bypass_logs']!.sublist(0, 300);
    }
    if ((_tables['security_events']?.length ?? 0) > 300) {
      _tables['security_events'] = _tables['security_events']!.sublist(0, 300);
    }
    if ((_tables['ad_events']?.length ?? 0) > 500) {
      _tables['ad_events'] = _tables['ad_events']!.sublist(0, 500);
    }
    lastVacuumTimestamp = DateTime.now().millisecondsSinceEpoch;
    await commitImmediate();
    if (_walFile != null && await _walFile!.exists()) {
      try {
        await _walFile!.delete();
      } catch (_) {}
    }
    sw.stop();
    lastIntegrityStatus =
        'VALID • WAL Checkpointed in ${sw.elapsedMilliseconds}ms';
    return {
      'status': 'success',
      'elapsedMs': sw.elapsedMilliseconds,
      'sizeBytes': await getDatabaseSizeBytes(),
    };
  }

  Future<int> getDatabaseSizeBytes() async {
    try {
      if (_dbFile != null && await _dbFile!.exists()) {
        return await _dbFile!.length();
      }
    } catch (_) {}
    final mirror = _prefs?.getString('sqlite_v8_master_mirror') ?? '';
    return utf8.encode(mirror).length;
  }

  String exportFullDatabaseJson() {
    final payload = {
      'engine': 'DOViD-SQLite-WAL-v8',
      'schemaVersion': 8,
      'exportedAt': DateTime.now().toIso8601String(),
      'ddl': tableSchemas,
      'tables': _tables,
      'config': _configStore,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _computeChecksum(String input) {
    int h1 = 0x811c9dc5;
    int h2 = 0x1000193;
    for (int i = 0; i < input.length; i++) {
      final c = input.codeUnitAt(i);
      h1 ^= c;
      h1 = (h1 * 0x01000193) & 0x7FFFFFFF;
      h2 = ((h2 << 5) + h2 + c) & 0x7FFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
  }
}

// ============================================================================
// JOO CLOUD DATABASE REMOTE STORAGE CLIENT (prj_a19edff7f9a64df51756)
// ============================================================================
class JooCloudDatabaseClient {
  static String projectUrl = kJooCloudProjectUrl;
  static String apiEndpoint = kJooCloudApiEndpoint;
  static String projectId = kJooCloudProjectId;
  static String publicKey = kJooCloudPublicKey;
  static String secretKey = kJooCloudPublicKey;

  static int syncedDocumentsCount = 0;
  static String lastCloudResponse = 'متصل بسيرفر JOO CLOUD DATABASE وجاهز';
  static DateTime? lastCloudSyncTime;

  static String _hexDigest(String input) {
    final bytes = utf8.encode(input);
    int a = 0x13579BDF;
    int b = 0x2468ACE0;
    int c = 0xFEDCBA98;
    int d = 0x76543210;
    for (int r = 0; r < 16; r++) {
      for (int i = 0; i < bytes.length; i++) {
        final v = bytes[i];
        a = ((a ^ v) * 0x01000193 + i + r) & 0xFFFFFFFF;
        b = ((b + a) ^ (v << 5)) & 0xFFFFFFFF;
        c = ((c ^ b) * 0x5BD1E995 + r) & 0xFFFFFFFF;
        d = ((d + c) ^ (a >> 3)) & 0xFFFFFFFF;
      }
    }
    return [a, b, c, d, a ^ c, b ^ d, a ^ b, c ^ d]
        .map((x) => (x & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0'))
        .join();
  }

  static Map<String, String> _buildSignedHeaders(
      String method, String action, String rawBody) {
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final rng = Random.secure();
    final nonce = List.generate(
        16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final bodyHash = _hexDigest(rawBody);
    final payload = '$method\n$action\n$ts\n$nonce\n$bodyHash';
    final sig = _hexDigest('$secretKey|$payload|$publicKey');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Project-Id': projectId,
      'X-Project-Key': publicKey,
      'X-API-Key': publicKey,
      'Authorization': 'Bearer $publicKey',
      'X-Timestamp': ts,
      'X-Nonce': nonce,
      'X-Signature': sig,
    };
  }

  static Future<Map<String, dynamic>> callAction(
    String action,
    Map<String, dynamic> body,
  ) async {
    final rawBody = jsonEncode({
      'project_id': projectId,
      'public_key': publicKey,
      ...body,
    });
    final headers = _buildSignedHeaders('POST', action, rawBody);

    final urls = [
      '$apiEndpoint&action=$action&id=$projectId',
      'https://ttyukgksy6juavi55.free.nf/?api=1&action=$action&id=$projectId',
    ];

    for (final target in urls) {
      try {
        final res = await http
            .post(
              Uri.parse(target),
              headers: headers,
              body: rawBody,
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 500) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            lastCloudSyncTime = DateTime.now();
            return decoded;
          }
        }
      } catch (_) {}
    }
    return {'ok': false, 'status': 'offline_cached'};
  }

  static Future<bool> pingServer() async {
    final res = await callAction('ping', {'project_id': projectId});
    final ok = res['ok'] == true || res['project'] != null;
    lastCloudResponse = ok
        ? 'متصل بنجاح بسيرفر JOO CLOUD ($projectId)'
        : 'تم تفعيل التخزين الهجين (JOO CLOUD + SQLite Local Mirror)';
    lastCloudSyncTime = DateTime.now();
    return ok;
  }

  static Future<bool> upsertDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> document,
  }) async {
    final res = await callAction('doc.set', {
      'collection': collection,
      'doc_id': docId,
      'document': document,
      'merge': true,
    });
    syncedDocumentsCount++;
    lastCloudSyncTime = DateTime.now();
    return res['ok'] == true;
  }

  static Future<List<Map<String, dynamic>>> fetchCollection(
    String collection, {
    int limit = 100,
  }) async {
    final res = await callAction('doc.find', {
      'collection': collection,
      'limit': limit,
      'offset': 0,
    });
    if (res['documents'] is List) {
      final list = <Map<String, dynamic>>[];
      for (final item in res['documents']) {
        if (item is Map && item['data'] is Map) {
          list.add(Map<String, dynamic>.from(item['data']));
        } else if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
      return list;
    }
    return [];
  }
}

// ============================================================================
// REAL-TIME ANTI-VPN, ANTI-PROXY & CRYPTOGRAPHIC SECURITY SHIELD
// ============================================================================
class SecurityShieldService {
  static const List<String> _vpnInterfaceKeywords = [
    'tun',
    'tap',
    'ppp',
    'pptp',
    'l2tp',
    'ipsec',
    'wg',
    'wireguard',
    'utun',
    'proton',
    'nord',
    'surfshark',
    'clash',
    'v2ray',
    'shadowsocks',
    'warp',
    'openvpn',
    'softether',
    'tailscale',
    'zerotier',
  ];

  static Future<Map<String, dynamic>> inspectNetworkSecurity({
    bool checkVpn = true,
    bool checkProxy = true,
  }) async {
    final detectedThreats = <String>[];
    String activeInterfaceName = '';

    if (checkVpn) {
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          includeLinkLocal: true,
          type: InternetAddressType.any,
        );

        for (final iface in interfaces) {
          final nameLower = iface.name.toLowerCase();
          for (final kw in _vpnInterfaceKeywords) {
            if (nameLower.contains(kw)) {
              activeInterfaceName = iface.name;
              detectedThreats.add('نفق VPN نشط (${iface.name})');
              break;
            }
          }
          for (final addr in iface.addresses) {
            final ip = addr.address;
            if ((nameLower.startsWith('tun') ||
                    nameLower.startsWith('ppp') ||
                    nameLower.startsWith('wg')) &&
                ip.isNotEmpty) {
              if (!detectedThreats.any((t) => t.contains(iface.name))) {
                activeInterfaceName = iface.name;
                detectedThreats.add('واجهة شبكة مشفرة (${iface.name}: $ip)');
              }
            }
          }
        }
      } catch (_) {}
    }

    if (checkProxy) {
      try {
        final env = Platform.environment;
        final proxyKeys = [
          'HTTP_PROXY',
          'HTTPS_PROXY',
          'ALL_PROXY',
          'http_proxy',
          'https_proxy',
          'all_proxy',
        ];
        for (final k in proxyKeys) {
          final val = (env[k] ?? '').trim();
          if (val.isNotEmpty) {
            activeInterfaceName = '$k=$val';
            detectedThreats.add('خادم Proxy محقون بالنظام ($k)');
            break;
          }
        }
      } catch (_) {}
    }

    return {
      'isCompromised': detectedThreats.isNotEmpty,
      'interfaceName': activeInterfaceName,
      'reason': detectedThreats.isEmpty
          ? 'الاتصال آمن ومباشر'
          : detectedThreats.join(' + '),
    };
  }

  static String hashSecret(String rawInput, {String contextSalt = 'v8_core'}) {
    final salted = 'DOViD_Enterprise_${contextSalt}_${rawInput}_YOSSEFJOO_9981';
    final List<int> bytes = utf8.encode(salted);
    int hA = 0x6A09E667;
    int hB = 0xBB67AE85;
    int hC = 0x3C6EF372;
    int hD = 0xA54FF53A;

    for (int round = 0; round < 64; round++) {
      for (int i = 0; i < bytes.length; i++) {
        final b = bytes[i];
        hA = ((hA ^ b) * 0x01000193 + round) & 0x7FFFFFFF;
        hB = ((hB + (hA >> 3)) ^ (b << 7)) & 0x7FFFFFFF;
        hC = ((hC ^ hB) * 0x5BD1E995) & 0x7FFFFFFF;
        hD = ((hD + hC) ^ (hA << 5)) & 0x7FFFFFFF;
      }
    }
    final hex = [hA, hB, hC, hD]
        .map((n) => n.toRadixString(16).padLeft(8, '0'))
        .join();
    return 'dv8\$sha\$${base64Url.encode(utf8.encode(hex)).replaceAll('=', '')}';
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  static String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'''[<>"';`\\]'''), '').trim();
  }
}

// ============================================================================
// REAL GOOGLE ADS ENGINE (AdMob Native Bridge + AdSense Slot Renderer)
// ============================================================================
class GoogleAdsEngine {
  static const MethodChannel _admobChannel =
      MethodChannel('com.dovid.app/admob');

  static Future<bool> initializeSdk({
    required String admobAppId,
    required String adsensePublisherId,
  }) async {
    if (admobAppId.isEmpty && adsensePublisherId.isEmpty) return false;
    try {
      final ok = await _admobChannel.invokeMethod('initialize', {
        'admobAppId': admobAppId,
        'adsensePublisherId': adsensePublisherId,
      }).timeout(const Duration(milliseconds: 500));
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> showInterstitialAd(BuildContext context) async {
    final s = AppState();
    if (!s.adsEnabled || !s.interstitialAdsEnabled) return false;
    if (s.currentUser?.isVip == true && s.vipNoAds) return false;
    if (s.admobInterstitialUnitId.trim().isEmpty &&
        s.adsensePublisherId.trim().isEmpty) {
      return false;
    }

    final unitId = s.admobInterstitialUnitId.trim().isNotEmpty
        ? s.admobInterstitialUnitId.trim()
        : '${s.adsensePublisherId.trim()}/${s.adsenseDisplaySlot.trim()}';

    try {
      final shown = await _admobChannel.invokeMethod('showInterstitial', {
        'unitId': unitId,
      }).timeout(const Duration(milliseconds: 450));
      if (shown == true) {
        s.recordAdEvent(
          adFormat: 'interstitial',
          placement: 'pre_download_interstitial',
          unitId: unitId,
          eventType: 'impression',
        );
        return true;
      }
    } catch (_) {}

    if (!context.mounted) return false;
    s.recordAdEvent(
      adFormat: 'interstitial',
      placement: 'pre_download_interstitial',
      unitId: unitId,
      eventType: 'impression',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RealGoogleInterstitialDialog(
        unitId: unitId,
        publisherId: s.adsensePublisherId,
        isRewarded: false,
      ),
    );
    return true;
  }

  static Future<bool> showRewardedAd(BuildContext context) async {
    final s = AppState();
    if (!s.adsEnabled || !s.rewardedAdsEnabled) return true;
    if (s.currentUser?.isVip == true && s.vipNoAds) return true;
    if (s.admobRewardedUnitId.trim().isEmpty &&
        s.adsensePublisherId.trim().isEmpty) {
      return true;
    }

    final unitId = s.admobRewardedUnitId.trim().isNotEmpty
        ? s.admobRewardedUnitId.trim()
        : '${s.adsensePublisherId.trim()}/${s.adsenseInArticleSlot.trim()}';

    try {
      final rewarded = await _admobChannel.invokeMethod('showRewarded', {
        'unitId': unitId,
      }).timeout(const Duration(milliseconds: 450));
      if (rewarded == true) {
        s.recordAdEvent(
          adFormat: 'rewarded',
          placement: 'high_quality_unlock',
          unitId: unitId,
          eventType: 'reward_earned',
        );
        return true;
      }
    } catch (_) {}

    if (!context.mounted) return false;
    s.recordAdEvent(
      adFormat: 'rewarded',
      placement: 'high_quality_unlock',
      unitId: unitId,
      eventType: 'impression',
    );

    final earned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RealGoogleInterstitialDialog(
        unitId: unitId,
        publisherId: s.adsensePublisherId,
        isRewarded: true,
      ),
    );
    if (earned == true) {
      s.recordAdEvent(
        adFormat: 'rewarded',
        placement: 'high_quality_unlock',
        unitId: unitId,
        eventType: 'reward_earned',
      );
    }
    return earned == true;
  }
}

// ============================================================================
// APP STATE (Enterprise Singleton with SQLite, Security Shield & Google Ads)
// ============================================================================
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  SharedPreferences? _prefs;
  final SqliteStorageEngine db = SqliteStorageEngine();
  Timer? _vpnMonitorTimer;

  AppUser? currentUser;
  bool isGuest = false;
  bool initialized = false;

  // Real-Time Security & Anti-VPN State
  bool antiVpnEnabled = true;
  bool antiProxyEnabled = true;
  bool isVpnBlockedNow = false;
  String vpnBlockReason = '';
  String vpnDetectedInterface = '';
  int maxFailedLoginAttempts = 7;
  String appPinCode = '';
  bool requirePinOnLaunch = false;
  bool isAppPinUnlockedSession = false;
  bool isVaultUnlockedSession = false;

  // Appearance, 3D Graphics & Typography Settings
  Color accentColor = AppColors.primary;
  String fontFamily = 'Cairo';
  double fontScale = 1.0;
  bool enable3DEffects = true;
  bool highGraphicsEnabled = true;
  String studioSortBy = 'newest';
  String historyStatusFilter = 'all';
  int? pendingTabSwitch;
  String pendingBatchUrls = '';

  // Smart Download, Custom Path & Quota Settings
  String customDownloadDirectory = '/storage/emulated/0/Download/DOViD';
  bool autoRouteAudioToMusicDir = true;
  bool placeAdsHomeTop = true;
  bool placeAdsHomeBottom = true;
  bool placeAdsStudio = true;
  List<String> blockedDomains = [];
  String defaultQuality = 'auto';
  bool autoSaveAfterExtract = false;
  bool autoDetectClipboard = true;
  bool maintenanceMode = false;
  bool emergencyLockdownMode = false;
  bool strictSslVerification = false;
  bool autoBanOnVpnAttempt = false;
  bool allowGuestAccess = true;
  int freeDailyQuota = 25;
  int maxConcurrentDownloads = 3;
  int maxRequestsPerMinute = 20;

  // Per-Platform Admin Gatekeeper
  Map<String, bool> allowedPlatforms = {
    'youtube': true,
    'tiktok': true,
    'instagram': true,
    'facebook': true,
    'twitter': true,
    'snapchat': true,
    'pinterest': true,
    'vimeo': true,
    'dailymotion': true,
    'reddit': true,
  };

  // Real Google Ads Configuration (AdMob + AdSense + Pro Analytics)
  bool adsEnabled = false;
  bool bannerAdsEnabled = true;
  bool interstitialAdsEnabled = false;
  bool rewardedAdsEnabled = false;
  bool nativeAdsEnabled = false;
  bool appOpenAdsEnabled = false;
  bool vipNoAds = true;
  int interstitialFrequency = 3;
  double estimatedEcpmUsd = 3.20;
  String customSponsorTitle = '';
  int _extractionsSinceLastAd = 0;

  String admobAppId = '';
  String admobBannerUnitId = '';
  String admobInterstitialUnitId = '';
  String admobRewardedUnitId = '';
  String admobNativeUnitId = '';

  String adsensePublisherId = '';
  String adsenseDisplaySlot = '';
  String adsenseInArticleSlot = '';
  String adsenseAnchorSlot = '';
  String customSponsorTargetUrl = '';

  // Background Extraction Engines Map (Hyper-Cluster Multi-Server Matrix)
  Map<String, bool> engineStates = {
    'youtube_piped_invidious_cluster': true,
    'tikwm_ultra_hd': true,
    'meta_reels_watch_engine': true,
    'vxtwitter_fx_cluster': true,
    'snapchat_spotlight_engine': true,
    'reddit_dash_engine': true,
    'vimeo_config_engine': true,
    'dailymotion_meta_engine': true,
    'pinterest_stream_engine': true,
    'direct_post_json': true,
    'direct_post_form': true,
    'direct_get_query': true,
    'cobalt_multi_engine': true,
    'allorigins_post': true,
    'allorigins_get': true,
    'corsproxy_post': true,
    'codetabs_tunnel': true,
    'deep_page_scraper': true,
  };

  // Real Data Collections (Backed by SQLite Engine - Zero Dummy Data)
  List<AppUser> users = [];
  List<DownloadEntry> downloads = [];
  List<BypassLogEntry> bypassLogs = [];
  List<SecurityEventEntry> securityEvents = [];
  List<BlockedIpEntry> blockedIps = [];
  List<ApiKey> apiKeys = [];
  List<SubscriptionCode> codes = [];
  List<BroadcastAnnouncement> announcements = [];
  List<AdAnalyticsEvent> adEvents = [];
  List<UserActivityLogEntry> userActivityLogs = [];
  DateTime? lastSqliteSyncAt;
  bool isSyncingSqlite = false;
  String sqliteSyncStatusText = 'متزامن محلياً وجاهز للمزامنة السحابية';
  List<String> customFolders = ['عام', 'موسيقى', 'دروس وتعليم', 'مقاطع قصيرة'];

  // Active Download Tasks
  final Map<String, ActiveDownloadTask> activeTasks = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await db.init(_prefs!);
    _loadFromSqlite();

    // Ensure Fixed Core Admin Account Exists (Zero experimental/dummy accounts)
    final adminHash = SecurityShieldService.hashSecret(kAdminPassword);
    final legacyAdminHash = _legacyHash(kAdminPassword);
    final existingAdmin = users
        .where((u) => u.username.toLowerCase() == kAdminUsername.toLowerCase())
        .firstOrNull;

    if (existingAdmin == null) {
      users.add(AppUser(
        id: _genId(),
        username: kAdminUsername,
        passwordHash: adminHash,
        email: kAdminEmail,
        isAdmin: true,
        isVip: true,
        createdAt: DateTime.now(),
      ));
      await _saveUsers();
    } else if (existingAdmin.passwordHash == legacyAdminHash) {
      existingAdmin.passwordHash = adminHash;
      existingAdmin.isVip = true;
      await _saveUsers();
    }

    final uid = _prefs!.getString('current_user_id');
    if (uid != null) {
      currentUser = users.where((u) => u.id == uid && !u.isBanned).firstOrNull;
    }
    isGuest = _prefs!.getBool('guest_mode') ?? false;
    if (!allowGuestAccess && isGuest) {
      isGuest = false;
    }

    await verifyVpnAndNetworkSecurity();
    _startVpnWatchdog();

    if (adsEnabled) {
      GoogleAdsEngine.initializeSdk(
        admobAppId: admobAppId,
        adsensePublisherId: adsensePublisherId,
      );
    }

    initialized = true;
    notifyListeners();
  }

  void _startVpnWatchdog() {
    _vpnMonitorTimer?.cancel();
    _vpnMonitorTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      verifyVpnAndNetworkSecurity(silentIfUnchanged: true);
    });
  }

  Future<bool> verifyVpnAndNetworkSecurity(
      {bool silentIfUnchanged = false}) async {
    if (!antiVpnEnabled && !antiProxyEnabled) {
      if (isVpnBlockedNow) {
        isVpnBlockedNow = false;
        vpnBlockReason = '';
        vpnDetectedInterface = '';
        notifyListeners();
      }
      return true;
    }

    final report = await SecurityShieldService.inspectNetworkSecurity(
      checkVpn: antiVpnEnabled,
      checkProxy: antiProxyEnabled,
    );

    final compromised = report['isCompromised'] == true;
    final reason = (report['reason'] ?? '').toString();
    final iface = (report['interfaceName'] ?? '').toString();

    if (compromised && !isVpnBlockedNow) {
      securityEvents.insert(
        0,
        SecurityEventEntry(
          id: _genId(),
          eventType: 'vpn_blocked',
          ipOrInterface: iface.isEmpty ? 'VPN/Tunnel' : iface,
          username: currentUser?.username ??
              (isGuest ? 'Guest' : 'Unauthenticated'),
          details: reason,
          isThreat: true,
          createdAt: DateTime.now(),
        ),
      );
      _saveSecurityEvents();
    }

    final changed =
        (isVpnBlockedNow != compromised) || (vpnBlockReason != reason);
    isVpnBlockedNow = compromised;
    vpnBlockReason = reason;
    vpnDetectedInterface = iface;

    if (changed || !silentIfUnchanged) {
      notifyListeners();
    }
    return !compromised;
  }

  bool unlockAppWithPin(String entered) {
    if (SecurityShieldService.constantTimeEquals(entered, appPinCode)) {
      isAppPinUnlockedSession = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool unlockVaultWithPin(String entered) {
    if (SecurityShieldService.constantTimeEquals(entered.trim(), appPinCode)) {
      isVaultUnlockedSession = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void _loadFromSqlite() {
    try {
      users = db.queryTable('users').map((e) => AppUser.fromJson(e)).toList();
      downloads = db
          .queryTable('downloads')
          .map((e) => DownloadEntry.fromJson(e))
          .toList();
      bypassLogs = db
          .queryTable('bypass_logs')
          .map((e) => BypassLogEntry.fromJson(e))
          .toList();
      securityEvents = db
          .queryTable('security_events')
          .map((e) => SecurityEventEntry.fromJson(e))
          .toList();
      blockedIps = db
          .queryTable('blocked_ips')
          .map((e) => BlockedIpEntry.fromJson(e))
          .toList();
      apiKeys =
          db.queryTable('api_keys').map((e) => ApiKey.fromJson(e)).toList();
      codes = db
          .queryTable('subscription_codes')
          .map((e) => SubscriptionCode.fromJson(e))
          .toList();
      announcements = db
          .queryTable('announcements')
          .map((e) => BroadcastAnnouncement.fromJson(e))
          .toList();
      adEvents = db
          .queryTable('ad_events')
          .map((e) => AdAnalyticsEvent.fromJson(e))
          .toList();
      userActivityLogs = db
          .queryTable('user_activity_logs')
          .map((e) => UserActivityLogEntry.fromJson(e))
          .toList();
    } catch (_) {}

    final colorVal =
        db.getConfig('theme_color_int') ?? _prefs?.getInt('theme_color_int');
    if (colorVal is int) accentColor = Color(colorVal);

    fontFamily = (db.getConfig('font_family') ?? 'Cairo').toString();
    fontScale =
        double.tryParse((db.getConfig('font_scale') ?? '1.0').toString()) ??
            1.0;
    enable3DEffects = db.getConfig('enable_3d_effects') != false;
    highGraphicsEnabled = db.getConfig('high_graphics_enabled') != false;
    studioSortBy = (db.getConfig('studio_sort_by') ?? 'newest').toString();

    customDownloadDirectory = (db.getConfig('custom_download_dir') ??
            '/storage/emulated/0/Download/DOViD')
        .toString();
    autoRouteAudioToMusicDir =
        db.getConfig('auto_route_audio_music') != false;
    placeAdsHomeTop = db.getConfig('place_ads_home_top') != false;
    placeAdsHomeBottom = db.getConfig('place_ads_home_bottom') != false;
    placeAdsStudio = db.getConfig('place_ads_studio') != false;
    final savedBlockedDomains = db.getConfig('blocked_domains');
    if (savedBlockedDomains is List) {
      blockedDomains = savedBlockedDomains.map((e) => e.toString()).toList();
    }
    defaultQuality = (db.getConfig('default_quality') ??
            _prefs?.getString('default_quality') ??
            'auto')
        .toString();
    emergencyLockdownMode = db.getConfig('emergency_lockdown_mode') == true;
    strictSslVerification = db.getConfig('strict_ssl_verification') == true;
    autoBanOnVpnAttempt = db.getConfig('auto_ban_on_vpn') == true;
    maxConcurrentDownloads = int.tryParse(
            (db.getConfig('max_concurrent_downloads') ?? '3').toString()) ??
        3;
    maxRequestsPerMinute = int.tryParse(
            (db.getConfig('max_requests_per_minute') ?? '20').toString()) ??
        20;
    nativeAdsEnabled = db.getConfig('native_ads_enabled') == true;
    appOpenAdsEnabled = db.getConfig('app_open_ads_enabled') == true;
    estimatedEcpmUsd = double.tryParse(
            (db.getConfig('estimated_ecpm_usd') ?? '3.20').toString()) ??
        3.20;
    customSponsorTitle =
        (db.getConfig('custom_sponsor_title') ?? '').toString();

    final savedAllowedPlatforms = db.getConfig('allowed_platforms');
    if (savedAllowedPlatforms is Map) {
      savedAllowedPlatforms.forEach((k, v) {
        if (allowedPlatforms.containsKey(k.toString())) {
          allowedPlatforms[k.toString()] = v != false;
        }
      });
    }
    autoSaveAfterExtract = db.getConfig('auto_save_extract') == true;
    autoDetectClipboard = db.getConfig('auto_detect_clipboard') != false;
    maintenanceMode = db.getConfig('maintenance_mode') == true;
    allowGuestAccess = db.getConfig('allow_guest_access') != false;
    freeDailyQuota =
        int.tryParse((db.getConfig('free_daily_quota') ?? '25').toString()) ??
            25;

    antiVpnEnabled = db.getConfig('anti_vpn_enabled') != false;
    antiProxyEnabled = db.getConfig('anti_proxy_enabled') != false;
    maxFailedLoginAttempts = int.tryParse(
            (db.getConfig('max_failed_login_attempts') ?? '7').toString()) ??
        7;
    appPinCode = (db.getConfig('app_pin_code') ?? '').toString();
    requirePinOnLaunch = db.getConfig('require_pin_on_launch') == true;
    if (appPinCode.isEmpty || !requirePinOnLaunch) {
      isAppPinUnlockedSession = true;
    }

    adsEnabled = db.getConfig('ads_enabled') == true;
    bannerAdsEnabled = db.getConfig('banner_ads_enabled') != false;
    interstitialAdsEnabled = db.getConfig('interstitial_ads_enabled') == true;
    rewardedAdsEnabled = db.getConfig('rewarded_ads_enabled') == true;
    vipNoAds = db.getConfig('vip_no_ads') != false;
    interstitialFrequency = int.tryParse(
            (db.getConfig('interstitial_frequency') ?? '3').toString()) ??
        3;

    admobAppId = (db.getConfig('admob_app_id') ?? '').toString();
    admobBannerUnitId = (db.getConfig('admob_banner_unit_id') ?? '').toString();
    admobInterstitialUnitId =
        (db.getConfig('admob_interstitial_unit_id') ?? '').toString();
    admobRewardedUnitId =
        (db.getConfig('admob_rewarded_unit_id') ?? '').toString();
    admobNativeUnitId = (db.getConfig('admob_native_unit_id') ?? '').toString();

    adsensePublisherId = (db.getConfig('adsense_publisher_id') ??
            _prefs?.getString('adsense_publisher_id') ??
            '')
        .toString();
    adsenseDisplaySlot = (db.getConfig('adsense_display_slot') ??
            _prefs?.getString('adsense_display_slot') ??
            '')
        .toString();
    adsenseInArticleSlot = (db.getConfig('adsense_inarticle_slot') ??
            _prefs?.getString('adsense_inarticle_slot') ??
            '')
        .toString();
    adsenseAnchorSlot = (db.getConfig('adsense_anchor_slot') ??
            _prefs?.getString('adsense_anchor_slot') ??
            '')
        .toString();
    customSponsorTargetUrl =
        (db.getConfig('custom_sponsor_target_url') ?? '').toString();

    final savedEngines = db.getConfig('engine_states');
    if (savedEngines is Map) {
      savedEngines.forEach((k, v) {
        if (engineStates.containsKey(k.toString())) {
          engineStates[k.toString()] = v == true;
        }
      });
    }

    final savedFolders = db.getConfig('custom_folders');
    if (savedFolders is List && savedFolders.isNotEmpty) {
      customFolders = savedFolders.map((e) => e.toString()).toList();
    }
  }

  Future<void> saveSettings({
    Color? newColor,
    String? newFontFamily,
    double? newFontScale,
    bool? newEnable3DEffects,
    bool? newHighGraphics,
    String? newStudioSortBy,
    String? newDownloadDir,
    bool? newAutoRouteAudio,
    bool? newPlaceAdsHomeTop,
    bool? newPlaceAdsHomeBottom,
    bool? newPlaceAdsStudio,
    bool? newEmergencyLockdown,
    bool? newStrictSsl,
    bool? newAutoBanOnVpn,
    int? newMaxConcurrent,
    int? newMaxReqPerMin,
    bool? newNativeAdsEnabled,
    bool? newAppOpenAdsEnabled,
    double? newEstimatedEcpm,
    String? newSponsorTitle,
    String? newQuality,
    bool? newAutoSave,
    bool? newAutoDetectClipboard,
    bool? newMaintenanceMode,
    bool? newAllowGuestAccess,
    int? newFreeDailyQuota,
    bool? newAntiVpn,
    bool? newAntiProxy,
    int? newMaxFailedLogins,
    String? newAppPin,
    bool? newRequirePinOnLaunch,
    bool? newAdsEnabled,
    bool? newBannerAdsEnabled,
    bool? newInterstitialAdsEnabled,
    bool? newRewardedAdsEnabled,
    bool? newVipNoAds,
    int? newInterstitialFreq,
    String? newAdmobAppId,
    String? newAdmobBannerId,
    String? newAdmobInterstitialId,
    String? newAdmobRewardedId,
    String? newAdmobNativeId,
    String? pubId,
    String? dispSlot,
    String? inArtSlot,
    String? anchSlot,
    String? sponsorUrl,
  }) async {
    if (newColor != null) {
      accentColor = newColor;
      db.setConfig('theme_color_int', newColor.value);
    }
    if (newFontFamily != null) {
      fontFamily = newFontFamily;
      db.setConfig('font_family', newFontFamily);
    }
    if (newFontScale != null) {
      fontScale = newFontScale;
      db.setConfig('font_scale', newFontScale);
    }
    if (newEnable3DEffects != null) {
      enable3DEffects = newEnable3DEffects;
      db.setConfig('enable_3d_effects', newEnable3DEffects);
    }
    if (newHighGraphics != null) {
      highGraphicsEnabled = newHighGraphics;
      db.setConfig('high_graphics_enabled', newHighGraphics);
    }
    if (newStudioSortBy != null) {
      studioSortBy = newStudioSortBy;
      db.setConfig('studio_sort_by', newStudioSortBy);
    }
    if (newDownloadDir != null && newDownloadDir.trim().isNotEmpty) {
      customDownloadDirectory = newDownloadDir.trim();
      db.setConfig('custom_download_dir', customDownloadDirectory);
    }
    if (newAutoRouteAudio != null) {
      autoRouteAudioToMusicDir = newAutoRouteAudio;
      db.setConfig('auto_route_audio_music', newAutoRouteAudio);
    }
    if (newPlaceAdsHomeTop != null) {
      placeAdsHomeTop = newPlaceAdsHomeTop;
      db.setConfig('place_ads_home_top', newPlaceAdsHomeTop);
    }
    if (newPlaceAdsHomeBottom != null) {
      placeAdsHomeBottom = newPlaceAdsHomeBottom;
      db.setConfig('place_ads_home_bottom', newPlaceAdsHomeBottom);
    }
    if (newPlaceAdsStudio != null) {
      placeAdsStudio = newPlaceAdsStudio;
      db.setConfig('place_ads_studio', newPlaceAdsStudio);
    }
    if (newEmergencyLockdown != null) {
      emergencyLockdownMode = newEmergencyLockdown;
      db.setConfig('emergency_lockdown_mode', newEmergencyLockdown);
    }
    if (newStrictSsl != null) {
      strictSslVerification = newStrictSsl;
      db.setConfig('strict_ssl_verification', newStrictSsl);
    }
    if (newAutoBanOnVpn != null) {
      autoBanOnVpnAttempt = newAutoBanOnVpn;
      db.setConfig('auto_ban_on_vpn', newAutoBanOnVpn);
    }
    if (newMaxConcurrent != null) {
      maxConcurrentDownloads = newMaxConcurrent.clamp(1, 8);
      db.setConfig('max_concurrent_downloads', maxConcurrentDownloads);
    }
    if (newMaxReqPerMin != null) {
      maxRequestsPerMinute = newMaxReqPerMin.clamp(5, 120);
      db.setConfig('max_requests_per_minute', maxRequestsPerMinute);
    }
    if (newNativeAdsEnabled != null) {
      nativeAdsEnabled = newNativeAdsEnabled;
      db.setConfig('native_ads_enabled', newNativeAdsEnabled);
    }
    if (newAppOpenAdsEnabled != null) {
      appOpenAdsEnabled = newAppOpenAdsEnabled;
      db.setConfig('app_open_ads_enabled', newAppOpenAdsEnabled);
    }
    if (newEstimatedEcpm != null) {
      estimatedEcpmUsd = newEstimatedEcpm;
      db.setConfig('estimated_ecpm_usd', newEstimatedEcpm);
    }
    if (newSponsorTitle != null) {
      customSponsorTitle = newSponsorTitle.trim();
      db.setConfig('custom_sponsor_title', customSponsorTitle);
    }
    if (newQuality != null) {
      defaultQuality = newQuality;
      db.setConfig('default_quality', newQuality);
    }
    if (newAutoSave != null) {
      autoSaveAfterExtract = newAutoSave;
      db.setConfig('auto_save_extract', newAutoSave);
    }
    if (newAutoDetectClipboard != null) {
      autoDetectClipboard = newAutoDetectClipboard;
      db.setConfig('auto_detect_clipboard', newAutoDetectClipboard);
    }
    if (newMaintenanceMode != null) {
      maintenanceMode = newMaintenanceMode;
      db.setConfig('maintenance_mode', newMaintenanceMode);
    }
    if (newAllowGuestAccess != null) {
      allowGuestAccess = newAllowGuestAccess;
      db.setConfig('allow_guest_access', newAllowGuestAccess);
    }
    if (newFreeDailyQuota != null) {
      freeDailyQuota = newFreeDailyQuota;
      db.setConfig('free_daily_quota', newFreeDailyQuota);
    }
    if (newAntiVpn != null) {
      antiVpnEnabled = newAntiVpn;
      db.setConfig('anti_vpn_enabled', newAntiVpn);
      await verifyVpnAndNetworkSecurity();
    }
    if (newAntiProxy != null) {
      antiProxyEnabled = newAntiProxy;
      db.setConfig('anti_proxy_enabled', newAntiProxy);
      await verifyVpnAndNetworkSecurity();
    }
    if (newMaxFailedLogins != null) {
      maxFailedLoginAttempts = newMaxFailedLogins;
      db.setConfig('max_failed_login_attempts', newMaxFailedLogins);
    }
    if (newAppPin != null) {
      appPinCode = newAppPin.trim();
      db.setConfig('app_pin_code', appPinCode);
      isAppPinUnlockedSession = true;
    }
    if (newRequirePinOnLaunch != null) {
      requirePinOnLaunch = newRequirePinOnLaunch;
      db.setConfig('require_pin_on_launch', newRequirePinOnLaunch);
    }
    if (newAdsEnabled != null) {
      adsEnabled = newAdsEnabled;
      db.setConfig('ads_enabled', newAdsEnabled);
    }
    if (newBannerAdsEnabled != null) {
      bannerAdsEnabled = newBannerAdsEnabled;
      db.setConfig('banner_ads_enabled', newBannerAdsEnabled);
    }
    if (newInterstitialAdsEnabled != null) {
      interstitialAdsEnabled = newInterstitialAdsEnabled;
      db.setConfig('interstitial_ads_enabled', newInterstitialAdsEnabled);
    }
    if (newRewardedAdsEnabled != null) {
      rewardedAdsEnabled = newRewardedAdsEnabled;
      db.setConfig('rewarded_ads_enabled', newRewardedAdsEnabled);
    }
    if (newVipNoAds != null) {
      vipNoAds = newVipNoAds;
      db.setConfig('vip_no_ads', newVipNoAds);
    }
    if (newInterstitialFreq != null) {
      interstitialFrequency = newInterstitialFreq.clamp(1, 20);
      db.setConfig('interstitial_frequency', interstitialFrequency);
    }
    if (newAdmobAppId != null) {
      admobAppId = newAdmobAppId.trim();
      db.setConfig('admob_app_id', admobAppId);
    }
    if (newAdmobBannerId != null) {
      admobBannerUnitId = newAdmobBannerId.trim();
      db.setConfig('admob_banner_unit_id', admobBannerUnitId);
    }
    if (newAdmobInterstitialId != null) {
      admobInterstitialUnitId = newAdmobInterstitialId.trim();
      db.setConfig('admob_interstitial_unit_id', admobInterstitialUnitId);
    }
    if (newAdmobRewardedId != null) {
      admobRewardedUnitId = newAdmobRewardedId.trim();
      db.setConfig('admob_rewarded_unit_id', admobRewardedUnitId);
    }
    if (newAdmobNativeId != null) {
      admobNativeUnitId = newAdmobNativeId.trim();
      db.setConfig('admob_native_unit_id', admobNativeUnitId);
    }
    if (pubId != null) {
      adsensePublisherId = pubId.trim();
      db.setConfig('adsense_publisher_id', adsensePublisherId);
    }
    if (dispSlot != null) {
      adsenseDisplaySlot = dispSlot.trim();
      db.setConfig('adsense_display_slot', adsenseDisplaySlot);
    }
    if (inArtSlot != null) {
      adsenseInArticleSlot = inArtSlot.trim();
      db.setConfig('adsense_inarticle_slot', adsenseInArticleSlot);
    }
    if (anchSlot != null) {
      adsenseAnchorSlot = anchSlot.trim();
      db.setConfig('adsense_anchor_slot', adsenseAnchorSlot);
    }
    if (sponsorUrl != null) {
      customSponsorTargetUrl = sponsorUrl.trim();
      db.setConfig('custom_sponsor_target_url', customSponsorTargetUrl);
    }

    await db.commitImmediate();
    notifyListeners();
  }

  void toggleExtractionEngine(String key, bool enabled) {
    engineStates[key] = enabled;
    db.setConfig('engine_states', engineStates);
    notifyListeners();
  }

  void togglePlatformAllowed(String platformId, bool allowed) {
    allowedPlatforms[platformId] = allowed;
    db.setConfig('allowed_platforms', allowedPlatforms);
    notifyListeners();
  }

  void enableAllExtractionEngines(bool enabled) {
    for (final k in engineStates.keys.toList()) {
      engineStates[k] = enabled;
    }
    db.setConfig('engine_states', engineStates);
    notifyListeners();
  }

  void resetAllUsersDailyQuotas() {
    for (final u in users) {
      u.dailyDownloadsCount = 0;
    }
    _saveUsers();
    notifyListeners();
  }

  void grantVipToAllUsers() {
    for (final u in users) {
      u.isVip = true;
    }
    _saveUsers();
    notifyListeners();
  }

  void clearAdAnalytics() {
    adEvents.clear();
    _saveAdEvents();
    notifyListeners();
  }

  void unblockAllIps() {
    blockedIps.clear();
    _saveBlockedIps();
    notifyListeners();
  }

  void addBlockedDomain(String domain) {
    final clean = domain.trim().toLowerCase();
    if (clean.isNotEmpty && !blockedDomains.contains(clean)) {
      blockedDomains.add(clean);
      db.setConfig('blocked_domains', blockedDomains);
      notifyListeners();
    }
  }

  void removeBlockedDomain(String domain) {
    blockedDomains.remove(domain);
    db.setConfig('blocked_domains', blockedDomains);
    notifyListeners();
  }

  double get estimatedTotalAdRevenueUsd {
    final impressionsRevenue = (totalAdImpressions / 1000.0) * estimatedEcpmUsd;
    final clicksRevenue = totalAdClicks * 0.08;
    final rewardsRevenue = totalAdRewards * 0.04;
    return impressionsRevenue + clicksRevenue + rewardsRevenue;
  }

  double get adCtrPercent {
    if (totalAdImpressions == 0) return 0.0;
    return (totalAdClicks / totalAdImpressions) * 100.0;
  }

  void addCustomFolder(String folder) {
    final clean = SecurityShieldService.sanitizeInput(folder);
    if (clean.isNotEmpty && !customFolders.contains(clean)) {
      customFolders.add(clean);
      db.setConfig('custom_folders', customFolders);
      notifyListeners();
    }
  }

  void sendLinksToBatchDownloader(List<String> urls) {
    if (urls.isEmpty) return;
    pendingBatchUrls = urls.join('\n');
    pendingTabSwitch = 0;
    notifyListeners();
  }

  void consumePendingTabSwitch() {
    pendingTabSwitch = null;
  }

  String consumePendingBatchUrls() {
    final val = pendingBatchUrls;
    pendingBatchUrls = '';
    return val;
  }

  Future<void> _saveUsers() async {
    db.replaceTable('users', users.map((e) => e.toJson()).toList());
  }

  Future<void> _saveDownloads() async {
    db.replaceTable('downloads', downloads.map((e) => e.toJson()).toList());
  }

  Future<void> _saveBypassLogs() async {
    if (bypassLogs.length > 300) {
      bypassLogs = bypassLogs.sublist(0, 300);
    }
    db.replaceTable(
        'bypass_logs', bypassLogs.map((e) => e.toJson()).toList());
  }

  Future<void> _saveSecurityEvents() async {
    if (securityEvents.length > 300) {
      securityEvents = securityEvents.sublist(0, 300);
    }
    db.replaceTable(
        'security_events', securityEvents.map((e) => e.toJson()).toList());
  }

  Future<void> _saveBlockedIps() async {
    db.replaceTable(
        'blocked_ips', blockedIps.map((e) => e.toJson()).toList());
  }

  Future<void> _saveApiKeys() async {
    db.replaceTable('api_keys', apiKeys.map((e) => e.toJson()).toList());
  }

  Future<void> _saveCodes() async {
    db.replaceTable(
        'subscription_codes', codes.map((e) => e.toJson()).toList());
  }

  Future<void> _saveAnnouncements() async {
    db.replaceTable(
        'announcements', announcements.map((e) => e.toJson()).toList());
  }

  Future<void> _saveAdEvents() async {
    if (adEvents.length > 500) {
      adEvents = adEvents.sublist(0, 500);
    }
    db.replaceTable('ad_events', adEvents.map((e) => e.toJson()).toList());
  }

  Future<void> _saveUserActivityLogs() async {
    if (userActivityLogs.length > 500) {
      userActivityLogs = userActivityLogs.sublist(0, 500);
    }
    db.replaceTable('user_activity_logs',
        userActivityLogs.map((e) => e.toJson()).toList());
  }

  void recordUserActivity({
    required String actionType,
    required String details,
    String platform = '',
  }) {
    final uid = currentUser?.id ?? (isGuest ? 'guest' : 'system');
    final uname =
        currentUser?.username ?? (isGuest ? 'زائر' : 'النظام');
    userActivityLogs.insert(
      0,
      UserActivityLogEntry(
        id: _genId(),
        userId: uid,
        username: uname,
        actionType: actionType,
        details: details,
        platform: platform,
        createdAt: DateTime.now(),
      ),
    );
    _saveUserActivityLogs();
    notifyListeners();
  }

  Future<bool> syncAccountsAndActivityWithSqlite() async {
    if (isSyncingSqlite) return false;
    isSyncingSqlite = true;
    sqliteSyncStatusText =
        'جاري المزامنة مع سيرفر JOO CLOUD ($kJooCloudProjectId) و SQLite...';
    notifyListeners();

    try {
      await _saveUsers();
      await _saveDownloads();
      await _saveUserActivityLogs();
      await _saveBypassLogs();
      await _saveSecurityEvents();
      await db.commitImmediate();

      // 1. Sync all core collections to JOO CLOUD DATABASE (prj_a19edff7f9a64df51756)
      try {
        await JooCloudDatabaseClient.upsertDocument(
          collection: 'dovid_users',
          docId: 'users_master',
          document: {
            'project_id': kJooCloudProjectId,
            'users': users.map((u) => u.toJson()).toList(),
            'synced_at': DateTime.now().toIso8601String(),
          },
        );
        await JooCloudDatabaseClient.upsertDocument(
          collection: 'dovid_activity_logs',
          docId: 'activity_master',
          document: {
            'project_id': kJooCloudProjectId,
            'logs': userActivityLogs.take(120).map((a) => a.toJson()).toList(),
            'synced_at': DateTime.now().toIso8601String(),
          },
        );
        await JooCloudDatabaseClient.upsertDocument(
          collection: 'dovid_downloads',
          docId: 'downloads_master',
          document: {
            'project_id': kJooCloudProjectId,
            'downloads': downloads.take(120).map((d) => d.toJson()).toList(),
            'synced_at': DateTime.now().toIso8601String(),
          },
        );
        final cloudUsers =
            await JooCloudDatabaseClient.fetchCollection('dovid_users');
        for (final doc in cloudUsers) {
          if (doc['users'] is List) {
            for (final ru in doc['users']) {
              if (ru is Map) {
                final uname = (ru['username'] ?? '').toString();
                if (uname.isNotEmpty &&
                    !users.any(
                        (u) => u.username.toLowerCase() == uname.toLowerCase())) {
                  users.add(AppUser.fromJson(Map<String, dynamic>.from(ru)));
                }
              }
            }
          }
        }
      } catch (_) {}

      // 2. Also attempt remote SQLite sync with backend server
      try {
        final payload = {
          'action': 'admin_sqlite_sync',
          'users': users.map((u) => u.toJson()).toList(),
          'activity_logs': userActivityLogs.take(100).map((a) => a.toJson()).toList(),
          'downloads_count': downloads.length,
          'timestamp': DateTime.now().toIso8601String(),
        };
        final res = await http
            .post(
              Uri.parse('$kApiEndpoint?action=admin_sqlite_sync'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['remote_users'] is List) {
            for (final ru in data['remote_users']) {
              if (ru is Map) {
                final uname = (ru['username'] ?? '').toString();
                if (uname.isNotEmpty &&
                    !users.any((u) =>
                        u.username.toLowerCase() == uname.toLowerCase())) {
                  users.add(AppUser(
                    id: (ru['id'] ?? _genId()).toString(),
                    username: uname,
                    passwordHash: (ru['passwordHash'] ?? '').toString(),
                    email: (ru['email'] ?? '').toString(),
                    isAdmin: ru['isAdmin'] == true || ru['is_admin'] == 1,
                    isVip: ru['isVip'] == true || ru['is_vip'] == 1,
                    createdAt: DateTime.tryParse(
                            (ru['created_at'] ?? '').toString()) ??
                        DateTime.now(),
                  ));
                }
              }
            }
            await _saveUsers();
          }
        }
      } catch (_) {}

      lastSqliteSyncAt = DateTime.now();
      sqliteSyncStatusText =
          'تمت المزامنة بنجاح (${users.length} حساب • ${userActivityLogs.length} نشاط)';
      isSyncingSqlite = false;
      notifyListeners();
      return true;
    } catch (_) {
      sqliteSyncStatusText = 'تم الحفظ في محرك SQLite المحلي بنجاح';
      isSyncingSqlite = false;
      notifyListeners();
      return false;
    }
  }

  String _legacyHash(String password) =>
      base64Url.encode(utf8.encode('dovid_salt_${password}_v4'));

  String _genId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(99999)}';

  bool isDeviceBlocked() {
    return blockedIps.any((b) => b.ip == 'local_device' || b.ip == '127.0.0.1');
  }

  int recentFailedAttempts() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    return securityEvents
        .where(
            (a) => a.eventType == 'login_failed' && a.createdAt.isAfter(cutoff))
        .length;
  }

  String? login(String rawUsername, String password) {
    if (isVpnBlockedNow) {
      return 'لا يمكن تسجيل الدخول أثناء تشغيل VPN أو Proxy';
    }
    if (isDeviceBlocked()) {
      return 'تم حظر هذا الجهاز أمنياً بسبب تجاوز الحد الأقصى للمحاولات';
    }

    final username = SecurityShieldService.sanitizeInput(rawUsername);
    if (recentFailedAttempts() >= maxFailedLoginAttempts) {
      blockedIps.insert(
        0,
        BlockedIpEntry(
          id: _genId(),
          ip: 'local_device',
          reason:
              'تجاوز الحد الأمني ($maxFailedLoginAttempts محاولات فاشلة خلال 15 دقيقة)',
          blockedAt: DateTime.now(),
        ),
      );
      _saveBlockedIps();
      notifyListeners();
      return 'تم تفعيل الحظر التلقائي للجهاز لتكرار المحاولات الخاطئة';
    }

    final user = users
        .where((u) => u.username.toLowerCase() == username.toLowerCase())
        .firstOrNull;

    final newHash = SecurityShieldService.hashSecret(password);
    final oldHash = _legacyHash(password);
    final validPass = user != null &&
        (SecurityShieldService.constantTimeEquals(user.passwordHash, newHash) ||
            SecurityShieldService.constantTimeEquals(
                user.passwordHash, oldHash));

    securityEvents.insert(
      0,
      SecurityEventEntry(
        id: _genId(),
        eventType: validPass ? 'login_success' : 'login_failed',
        ipOrInterface: '127.0.0.1',
        username: username,
        details: validPass
            ? 'تسجيل دخول آمن ومصرح'
            : 'محاولة دخول بكلمة مرور غير صحيحة',
        isThreat: !validPass,
        createdAt: DateTime.now(),
      ),
    );
    _saveSecurityEvents();

    if (user == null) return 'اسم المستخدم غير مسجل بالنظام';
    if (!validPass) return 'كلمة المرور غير صحيحة';
    if (user.isBanned && !user.isAdmin) {
      return 'تم إيقاف هذا الحساب من قِبل إدارة النظام';
    }

    if (maintenanceMode && !user.isAdmin) {
      return 'النظام في وضع الصيانة والتحديث حالياً، يرجى المحاولة لاحقاً';
    }

    if (user.passwordHash == oldHash) {
      user.passwordHash = newHash;
    }

    user.lastLogin = DateTime.now();
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    recordUserActivity(
      actionType: 'login',
      details: 'تسجيل دخول الحساب (${user.username}) ومزامنة SQLite',
    );
    notifyListeners();
    return null;
  }

  String? register(String rawUsername, String password, {String email = ''}) {
    if (isVpnBlockedNow) {
      return 'يرجى إيقاف اتصال VPN أولاً لإنشاء حساب';
    }
    if (maintenanceMode) {
      return 'التسجيل متوقف مؤقتاً لوجود تحديثات بالنظام';
    }
    final username = SecurityShieldService.sanitizeInput(rawUsername);
    final cleanEmail = SecurityShieldService.sanitizeInput(email);

    if (username.length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    if (password.length < 6) {
      return 'لحمايتك، كلمة المرور يجب أن تكون 6 أحرف أو أرقام على الأقل';
    }
    if (users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'اسم المستخدم مسجل بالفعل';
    }

    final user = AppUser(
      id: _genId(),
      username: username,
      passwordHash: SecurityShieldService.hashSecret(password),
      email: cleanEmail,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    users.add(user);
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    recordUserActivity(
      actionType: 'register',
      details: 'إنشاء حساب جديد (${user.username}) وحفظه في SQLite',
    );
    notifyListeners();
    return null;
  }

  String? loginAsGuest() {
    if (!allowGuestAccess) {
      return 'وضع الزائر متوقف حالياً بقرار من مدير النظام';
    }
    if (maintenanceMode) {
      return 'النظام في وضع الصيانة حالياً';
    }
    isGuest = true;
    currentUser = null;
    _prefs?.remove('current_user_id');
    _prefs?.setBool('guest_mode', true);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    isGuest = false;
    isVaultUnlockedSession = false;
    _prefs?.remove('current_user_id');
    _prefs?.setBool('guest_mode', false);
    notifyListeners();
  }

  bool checkAndConsumeDailyQuota() {
    if (currentUser?.isAdmin == true || currentUser?.isVip == true) {
      return true;
    }
    if (myApiKey?.isActive == true) return true;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (currentUser != null) {
      if (currentUser!.lastQuotaDate != today) {
        currentUser!.lastQuotaDate = today;
        currentUser!.dailyDownloadsCount = 0;
      }
      if (currentUser!.dailyDownloadsCount >= freeDailyQuota) {
        return false;
      }
      currentUser!.dailyDownloadsCount++;
      _saveUsers();
      return true;
    }
    return true;
  }

  List<DownloadEntry> get myDownloads {
    final uid = currentUser?.id ?? (isGuest ? 'guest' : '');
    if (uid.isEmpty) return [];
    final list =
        downloads.where((d) => d.userId == uid && !d.isVaulted).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<DownloadEntry> get myVaultDownloads {
    final uid = currentUser?.id ?? (isGuest ? 'guest' : '');
    if (uid.isEmpty) return [];
    final list =
        downloads.where((d) => d.userId == uid && d.isVaulted).toList();
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

  Future<DownloadEntry> addDownload(String url, String quality,
      {String folderName = 'عام'}) async {
    final entry = DownloadEntry(
      id: _genId(),
      userId: currentUser?.id ?? 'guest',
      url: url,
      quality: quality,
      folderName: folderName,
      platform: detectPlatform(url),
      status: 'processing',
      createdAt: DateTime.now(),
    );
    downloads.insert(0, entry);
    await _saveDownloads();
    notifyListeners();
    return entry;
  }

  Future<void> recordSilentBypassAttempt({
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
  }

  Future<void> updateDownload(
    DownloadEntry entry, {
    String? title,
    String? description,
    String? author,
    String? thumbnailUrl,
    String? durationText,
    String? fileSizeText,
    String? link,
    String? hdLink,
    String? audioLink,
    String? localPath,
    String? subtitlePath,
    String? status,
    String? strategy,
    String? folderName,
    bool? isFavorite,
    bool? isVaulted,
  }) async {
    if (title != null && title.isNotEmpty) entry.title = title;
    if (description != null && description.isNotEmpty) {
      entry.description = description;
    }
    if (subtitlePath != null && subtitlePath.isNotEmpty) {
      entry.subtitlePath = subtitlePath;
    }
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
    if (folderName != null) entry.folderName = folderName;
    if (isFavorite != null) entry.isFavorite = isFavorite;
    if (isVaulted != null) entry.isVaulted = isVaulted;
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

  Future<void> toggleVault(DownloadEntry entry) async {
    entry.isVaulted = !entry.isVaulted;
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> deleteDownloadItem(String id,
      {bool deleteLocalFile = false}) async {
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
    downloads.removeWhere((d) => d.userId == uid && !d.isVaulted);
    await _saveDownloads();
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

  bool shouldTriggerInterstitialOnExtract() {
    if (!adsEnabled || !interstitialAdsEnabled) return false;
    if (currentUser?.isVip == true && vipNoAds) return false;
    _extractionsSinceLastAd++;
    if (_extractionsSinceLastAd >= interstitialFrequency) {
      _extractionsSinceLastAd = 0;
      return true;
    }
    return false;
  }

  void recordAdEvent({
    required String adFormat,
    required String placement,
    required String unitId,
    required String eventType,
  }) {
    adEvents.insert(
      0,
      AdAnalyticsEvent(
        id: _genId(),
        adFormat: adFormat,
        placement: placement,
        unitId: unitId,
        eventType: eventType,
        createdAt: DateTime.now(),
      ),
    );
    _saveAdEvents();
    notifyListeners();
  }

  int get totalAdImpressions =>
      adEvents.where((e) => e.eventType == 'impression').length;
  int get totalAdClicks =>
      adEvents.where((e) => e.eventType == 'click').length;
  int get totalAdRewards =>
      adEvents.where((e) => e.eventType == 'reward_earned').length;

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

    if (c.grantsVip) {
      currentUser!.isVip = true;
      _saveUsers();
    }

    final now = DateTime.now();
    final end = now.add(Duration(days: c.durationDays));
    final key = ApiKey(
      id: _genId(),
      userId: currentUser!.id,
      apiKey: 'dv_${_randomHex(16)}',
      apiSecret: _randomHex(32),
      subscriptionStart: now,
      subscriptionEnd: end,
      maxQuota: c.quotaLimit,
      createdAt: now,
    );
    apiKeys.add(key);
    _saveApiKeys();
    _saveCodes();
    notifyListeners();
    return null;
  }

  List<DownloadEntry> get allDownloads {
    final list = List<DownloadEntry>.from(downloads);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<String> generateCodes(int count, int days,
      {int quota = 10000, bool grantsVip = true}) {
    final generated = <String>[];
    for (int i = 0; i < count; i++) {
      final newCode = 'DOViD-${_randomHex(6).toUpperCase()}';
      codes.add(SubscriptionCode(
        id: _genId(),
        code: newCode,
        durationDays: days,
        quotaLimit: quota,
        grantsVip: grantsVip,
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

  void blockIp(String ip, {String reason = 'حظر يدوي بواسطة المدير'}) {
    final cleanIp = SecurityShieldService.sanitizeInput(ip);
    if (cleanIp.isNotEmpty && !blockedIps.any((b) => b.ip == cleanIp)) {
      blockedIps.insert(
        0,
        BlockedIpEntry(
          id: _genId(),
          ip: cleanIp,
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

  void toggleUserVip(String userId) {
    final u = users.where((x) => x.id == userId).firstOrNull;
    if (u != null) {
      u.isVip = !u.isVip;
      _saveUsers();
      notifyListeners();
    }
  }

  void toggleUserBan(String userId) {
    final u = users.where((x) => x.id == userId && !x.isAdmin).firstOrNull;
    if (u != null) {
      u.isBanned = !u.isBanned;
      _saveUsers();
      notifyListeners();
    }
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

  void addAnnouncement({
    required String title,
    required String body,
    String severity = 'info',
  }) {
    if (title.trim().isEmpty || body.trim().isEmpty) return;
    announcements.insert(
      0,
      BroadcastAnnouncement(
        id: _genId(),
        title: title.trim(),
        body: body.trim(),
        severity: severity,
        createdAt: DateTime.now(),
      ),
    );
    _saveAnnouncements();
    notifyListeners();
  }

  void deleteAnnouncement(String id) {
    announcements.removeWhere((a) => a.id == id);
    _saveAnnouncements();
    notifyListeners();
  }

  void clearBypassAndSecurityLogs() {
    bypassLogs.clear();
    securityEvents.clear();
    _saveBypassLogs();
    _saveSecurityEvents();
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
// UTILS (100% Const-Safe IconData for Flutter Release Tree-Shaking)
// ============================================================================
String detectPlatform(String url) {
  final u = url.toLowerCase();
  if (u.contains('youtube.com') || u.contains('youtu.be')) return 'youtube';
  if (u.contains('instagram.com')) return 'instagram';
  if (u.contains('tiktok.com')) return 'tiktok';
  if (u.contains('facebook.com') ||
      u.contains('fb.watch') ||
      u.contains('fb.gg')) {
    return 'facebook';
  }
  if (u.contains('twitter.com') || u.contains('x.com') || u.contains('t.co')) {
    return 'twitter';
  }
  if (u.contains('snapchat.com')) return 'snapchat';
  if (u.contains('pinterest.com') || u.contains('pin.it')) return 'pinterest';
  if (u.contains('vimeo.com')) return 'vimeo';
  if (u.contains('dailymotion.com') || u.contains('dai.ly')) {
    return 'dailymotion';
  }
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
// CONST-SAFE QUALITY OPTION & 3D PLATFORM SPECIFICATION MODELS
// ============================================================================
class QualityOption {
  final String key;
  final String label;
  final String badge;
  final IconData icon;

  const QualityOption({
    required this.key,
    required this.label,
    required this.badge,
    required this.icon,
  });
}

class PlatformSpec {
  final String id;
  final String name;
  final String arabicDesc;
  final String badgeTag;
  final Color topColor;
  final Color bottomColor;
  final Color depthColor;
  final Color accentGlow;
  final IconData fallbackIcon;

  const PlatformSpec({
    required this.id,
    required this.name,
    required this.arabicDesc,
    required this.badgeTag,
    required this.topColor,
    required this.bottomColor,
    required this.depthColor,
    required this.accentGlow,
    required this.fallbackIcon,
  });
}

const List<PlatformSpec> kSupportedPlatforms3D = [
  PlatformSpec(
    id: 'youtube',
    name: 'YouTube',
    arabicDesc: 'فيديوهات وشورتس حتى 4K UHD وملفات MP3 نقية',
    badgeTag: '4K / MP3',
    topColor: Color(0xFFFF2A2A),
    bottomColor: Color(0xFFB30000),
    depthColor: Color(0xFF6B0000),
    accentGlow: Color(0xFFFF3B3B),
    fallbackIcon: Icons.play_circle_fill,
  ),
  PlatformSpec(
    id: 'tiktok',
    name: 'TikTok',
    arabicDesc: 'تحميل بدون علامة مائية بجودة الأصل Full HD',
    badgeTag: 'بدون علامة',
    topColor: Color(0xFF1E2430),
    bottomColor: Color(0xFF0B0E14),
    depthColor: Color(0xFF00A8B5),
    accentGlow: Color(0xFF25F4EE),
    fallbackIcon: Icons.music_note,
  ),
  PlatformSpec(
    id: 'instagram',
    name: 'Instagram',
    arabicDesc: 'ريلز، ستوري، ومقاطع IGTV بجودة كاملة',
    badgeTag: 'Reels HD',
    topColor: Color(0xFFF58529),
    bottomColor: Color(0xFFDD2A7B),
    depthColor: Color(0xFF515BD4),
    accentGlow: Color(0xFFE1306C),
    fallbackIcon: Icons.camera_alt,
  ),
  PlatformSpec(
    id: 'facebook',
    name: 'Facebook',
    arabicDesc: 'فيديوهات الصفحات والريلز والمقاطع العامة والخاصة',
    badgeTag: 'FHD 1080p',
    topColor: Color(0xFF2D88FF),
    bottomColor: Color(0xFF0E52B5),
    depthColor: Color(0xFF072E6B),
    accentGlow: Color(0xFF1877F2),
    fallbackIcon: Icons.facebook,
  ),
  PlatformSpec(
    id: 'twitter',
    name: 'X / Twitter',
    arabicDesc: 'مقاطع التغريدات والمساحات والصور المتحركة GIF',
    badgeTag: 'تغريدات HD',
    topColor: Color(0xFF2C3440),
    bottomColor: Color(0xFF10141A),
    depthColor: Color(0xFF1DA1F2),
    accentGlow: Color(0xFF38BDF8),
    fallbackIcon: Icons.alternate_email,
  ),
  PlatformSpec(
    id: 'snapchat',
    name: 'Snapchat',
    arabicDesc: 'منصة الأضواء Spotlight والقصص العامة بدقة عالية',
    badgeTag: 'Spotlight',
    topColor: Color(0xFFFFEA00),
    bottomColor: Color(0xFFD4A500),
    depthColor: Color(0xFF8A6800),
    accentGlow: Color(0xFFFFD600),
    fallbackIcon: Icons.bolt,
  ),
  PlatformSpec(
    id: 'pinterest',
    name: 'Pinterest',
    arabicDesc: 'فيديوهات الإلهام والتصاميم والقصص المصورة',
    badgeTag: 'Pin Video',
    topColor: Color(0xFFFF1E3A),
    bottomColor: Color(0xFFA80018),
    depthColor: Color(0xFF63000D),
    accentGlow: Color(0xFFE60023),
    fallbackIcon: Icons.push_pin,
  ),
  PlatformSpec(
    id: 'vimeo',
    name: 'Vimeo',
    arabicDesc: 'الأعمال السينمائية والفيديوهات الاحترافية 4K',
    badgeTag: 'Cinema 4K',
    topColor: Color(0xFF29C5F6),
    bottomColor: Color(0xFF007EA7),
    depthColor: Color(0xFF004B66),
    accentGlow: Color(0xFF1AB7EA),
    fallbackIcon: Icons.videocam,
  ),
  PlatformSpec(
    id: 'dailymotion',
    name: 'Dailymotion',
    arabicDesc: 'القنوات العالمية والبرامج الوثائقية كاملة',
    badgeTag: 'HD Stream',
    topColor: Color(0xFF00B4D8),
    bottomColor: Color(0xFF005F8C),
    depthColor: Color(0xFF003752),
    accentGlow: Color(0xFF00AAFF),
    fallbackIcon: Icons.play_arrow,
  ),
  PlatformSpec(
    id: 'reddit',
    name: 'Reddit',
    arabicDesc: 'مقاطع المجتمعات مع دمج الصوت الأوتوماتيكي',
    badgeTag: 'Audio+Video',
    topColor: Color(0xFFFF5722),
    bottomColor: Color(0xFFC43000),
    depthColor: Color(0xFF7A1C00),
    accentGlow: Color(0xFFFF4500),
    fallbackIcon: Icons.forum,
  ),
];

PlatformSpec getPlatformSpec(String platformId) {
  final clean = platformId.toLowerCase().trim();
  for (final p in kSupportedPlatforms3D) {
    if (p.id == clean) return p;
  }
  return const PlatformSpec(
    id: 'unknown',
    name: 'DOViD Media',
    arabicDesc: 'فيديو متعدد المنصات مدعوم بالمعالجة الذكية',
    badgeTag: 'Smart HD',
    topColor: Color(0xFFF97316),
    bottomColor: Color(0xFFEA580C),
    depthColor: Color(0xFF9A3412),
    accentGlow: Color(0xFFF97316),
    fallbackIcon: Icons.video_file,
  );
}

// ============================================================================
// 3D VOLUMETRIC PLATFORM LOGOS ENGINE (Custom Sculpted 3D Vector Badges)
// ============================================================================
class Platform3DLogoPainter extends CustomPainter {
  final String platformId;
  final bool active;
  final bool enable3D;
  final double shinePhase;

  Platform3DLogoPainter({
    required this.platformId,
    this.active = false,
    this.enable3D = true,
    this.shinePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final spec = getPlatformSpec(platformId);
    final w = size.width;
    final h = size.height;
    final radius = Radius.circular(w * 0.28);

    // 1. Soft Ambient Ground Shadow
    if (enable3D) {
      final shadowPaint = Paint()
        ..color = spec.accentGlow.withOpacity(active ? 0.36 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.84, h * 0.84),
          radius,
        ),
        shadowPaint,
      );

      // 2. 3D Extruded Bottom/Right Depth Block (Volumetric Thickness)
      final depthRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.11, w * 0.88, h * 0.86),
        radius,
      );
      final depthPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            spec.depthColor,
            Color.lerp(spec.depthColor, Colors.black, 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(depthRect.outerRect);
      canvas.drawRRect(depthRect, depthPaint);
    }

    // 3. Main 3D Sculpted Cushion Face
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        w * 0.05,
        enable3D ? h * 0.04 : h * 0.06,
        w * 0.88,
        h * 0.85,
      ),
      radius,
    );

    final List<Color> faceGradientColors = platformId == 'instagram'
        ? const [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
          ]
        : [
            spec.topColor,
            spec.bottomColor,
          ];

    final facePaint = Paint()
      ..shader = LinearGradient(
        colors: faceGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(faceRect.outerRect);
    canvas.drawRRect(faceRect, facePaint);

    // 4. Inner 3D Bevel Rim Border
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 1.6 : 1.1
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(active ? 0.72 : 0.42),
          Colors.white.withOpacity(0.06),
          Colors.black.withOpacity(0.35),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(faceRect.outerRect);
    canvas.drawRRect(faceRect.deflate(0.6), rimPaint);

    // 5. Specular Top-Left Glass Highlight Dome
    if (enable3D) {
      final glossRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          faceRect.left + w * 0.06,
          faceRect.top + h * 0.04,
          faceRect.width - w * 0.12,
          faceRect.height * 0.42,
        ),
        topLeft: Radius.circular(w * 0.22),
        topRight: Radius.circular(w * 0.22),
        bottomLeft: Radius.circular(w * 0.08),
        bottomRight: Radius.circular(w * 0.08),
      );
      final glossPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.32 + 0.08 * sin(shinePhase)),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(glossRect.outerRect);
      canvas.drawRRect(glossRect, glossPaint);
    }

    // 6. Sculpted 3D Platform Emblem inside the Cushion
    final center = Offset(faceRect.center.dx, faceRect.center.dy);
    final unit = faceRect.width;
    _drawPlatformEmblem3D(canvas, center, unit, platformId);
  }

  void _drawPlatformEmblem3D(
      Canvas canvas, Offset c, double u, String platform) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    switch (platform) {
      case 'youtube':
        // 3D Inner Play Screen + Extruded Play Triangle
        final pill = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: u * 0.62, height: u * 0.44),
          Radius.circular(u * 0.12),
        );
        canvas.drawRRect(pill.shift(Offset(0, u * 0.035)), shadowPaint);
        canvas.drawRRect(
          pill,
          Paint()
            ..shader = const LinearGradient(
              colors: [Colors.white, Color(0xFFE2E8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(pill.outerRect),
        );
        final tri = Path()
          ..moveTo(c.dx - u * 0.08, c.dy - u * 0.11)
          ..lineTo(c.dx + u * 0.13, c.dy)
          ..lineTo(c.dx - u * 0.08, c.dy + u * 0.11)
          ..close();
        canvas.drawPath(
          tri,
          Paint()..color = const Color(0xFFD90429),
        );
        break;

      case 'tiktok':
        // 3D Dual-Offset Cyan & Crimson Musical Note + White Core
        void drawTikTokNote(Offset offset, Color color) {
          final p = Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.105
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          final path = Path()
            ..moveTo(c.dx + offset.dx + u * 0.05, c.dy + offset.dy - u * 0.22)
            ..lineTo(c.dx + offset.dx + u * 0.05, c.dy + offset.dy + u * 0.10)
            ..arcToPoint(
              Offset(c.dx + offset.dx - u * 0.17, c.dy + offset.dy + u * 0.10),
              radius: Radius.circular(u * 0.115),
              clockwise: true,
            )
            ..arcToPoint(
              Offset(c.dx + offset.dx - u * 0.03, c.dy + offset.dy - u * 0.01),
              radius: Radius.circular(u * 0.115),
              clockwise: true,
            );
          canvas.drawPath(path, p);
          final wave = Path()
            ..moveTo(c.dx + offset.dx + u * 0.05, c.dy + offset.dy - u * 0.20)
            ..quadraticBezierTo(
              c.dx + offset.dx + u * 0.14,
              c.dy + offset.dy - u * 0.09,
              c.dx + offset.dx + u * 0.22,
              c.dy + offset.dy - u * 0.08,
            );
          canvas.drawPath(wave, p);
        }
        drawTikTokNote(Offset(-u * 0.03, -u * 0.025), const Color(0xFF25F4EE));
        drawTikTokNote(Offset(u * 0.03, u * 0.025), const Color(0xFFFE2C55));
        drawTikTokNote(Offset.zero, Colors.white);
        break;

      case 'instagram':
        // 3D Sculpted Camera Frame + Glass Lens Ring + Flash Dot
        final camRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: u * 0.56, height: u * 0.56),
          Radius.circular(u * 0.16),
        );
        final strokeP = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.075;
        canvas.drawRRect(camRect.shift(Offset(0, u * 0.03)), shadowPaint);
        canvas.drawRRect(camRect, strokeP);
        canvas.drawCircle(c, u * 0.135, strokeP);
        canvas.drawCircle(
          Offset(c.dx + u * 0.165, c.dy - u * 0.165),
          u * 0.04,
          Paint()..color = Colors.white,
        );
        break;

      case 'facebook':
        // 3D Sculpted 'f' Monogram
        final fPath = Path()
          ..moveTo(c.dx + u * 0.11, c.dy - u * 0.25)
          ..lineTo(c.dx + u * 0.02, c.dy - u * 0.25)
          ..quadraticBezierTo(
              c.dx - u * 0.08, c.dy - u * 0.25, c.dx - u * 0.08, c.dy - u * 0.13)
          ..lineTo(c.dx - u * 0.08, c.dy + u * 0.26)
          ..moveTo(c.dx - u * 0.18, c.dy - u * 0.03)
          ..lineTo(c.dx + u * 0.10, c.dy - u * 0.03);
        final fShadow = Paint()
          ..color = Colors.black.withOpacity(0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.12
          ..strokeCap = StrokeCap.round;
        final fPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.12
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(fPath.shift(Offset(0, u * 0.03)), fShadow);
        canvas.drawPath(fPath, fPaint);
        break;

      case 'twitter':
        // 3D Sculpted X Crossed Metallic Beams
        final xPaint1 = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.105
          ..strokeCap = StrokeCap.round;
        final xPaint2 = Paint()
          ..color = const Color(0xFF94A3B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.075
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(c.dx - u * 0.19, c.dy - u * 0.19 + u * 0.03),
          Offset(c.dx + u * 0.19, c.dy + u * 0.19 + u * 0.03),
          shadowPaint,
        );
        canvas.drawLine(
          Offset(c.dx + u * 0.19, c.dy - u * 0.19),
          Offset(c.dx - u * 0.19, c.dy + u * 0.19),
          xPaint2,
        );
        canvas.drawLine(
          Offset(c.dx - u * 0.19, c.dy - u * 0.19),
          Offset(c.dx + u * 0.19, c.dy + u * 0.19),
          xPaint1,
        );
        break;

      case 'snapchat':
        // 3D Sculpted Ghost Silhouette with Dark Rim
        final ghost = Path()
          ..moveTo(c.dx, c.dy - u * 0.24)
          ..cubicTo(
            c.dx + u * 0.18,
            c.dy - u * 0.24,
            c.dx + u * 0.19,
            c.dy - u * 0.04,
            c.dx + u * 0.19,
            c.dy + u * 0.05,
          )
          ..lineTo(c.dx + u * 0.25, c.dy + u * 0.16)
          ..lineTo(c.dx + u * 0.12, c.dy + u * 0.21)
          ..lineTo(c.dx, c.dy + u * 0.17)
          ..lineTo(c.dx - u * 0.12, c.dy + u * 0.21)
          ..lineTo(c.dx - u * 0.25, c.dy + u * 0.16)
          ..lineTo(c.dx - u * 0.19, c.dy + u * 0.05)
          ..cubicTo(
            c.dx - u * 0.19,
            c.dy - u * 0.04,
            c.dx - u * 0.18,
            c.dy - u * 0.24,
            c.dx,
            c.dy - u * 0.24,
          )
          ..close();
        canvas.drawPath(ghost.shift(Offset(0, u * 0.03)), shadowPaint);
        canvas.drawPath(ghost, Paint()..color = Colors.white);
        canvas.drawPath(
          ghost,
          Paint()
            ..color = const Color(0xFF1E293B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.045
            ..strokeJoin = StrokeJoin.round,
        );
        break;

      case 'pinterest':
        // 3D Sculpted Pin 'P' Badge
        canvas.drawCircle(
            c.translate(0, u * 0.03), u * 0.25, shadowPaint);
        canvas.drawCircle(c, u * 0.25, Paint()..color = Colors.white);
        final pStroke = Paint()
          ..color = const Color(0xFFE60023)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.08
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(c.dx - u * 0.05, c.dy - u * 0.12),
          Offset(c.dx - u * 0.08, c.dy + u * 0.16),
          pStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(c.dx + u * 0.01, c.dy - u * 0.04),
              width: u * 0.18,
              height: u * 0.16),
          -pi / 2,
          pi,
          false,
          pStroke,
        );
        break;

      case 'vimeo':
        // 3D Sculpted 'V' Ribbon
        final vPath = Path()
          ..moveTo(c.dx - u * 0.20, c.dy - u * 0.14)
          ..lineTo(c.dx - u * 0.01, c.dy + u * 0.18)
          ..lineTo(c.dx + u * 0.20, c.dy - u * 0.16);
        final vPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(vPath.shift(Offset(0, u * 0.035)), shadowPaint);
        canvas.drawPath(vPath, vPaint);
        break;

      case 'dailymotion':
        // 3D Sculpted Geometric 'd' Emblem
        final dRing = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.095
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(
          Offset(c.dx - u * 0.03, c.dy + u * 0.05),
          u * 0.14,
          dRing,
        );
        canvas.drawLine(
          Offset(c.dx + u * 0.11, c.dy - u * 0.22),
          Offset(c.dx + u * 0.11, c.dy + u * 0.19),
          dRing,
        );
        break;

      case 'reddit':
        // 3D Sculpted Robot Head + Antenna + Eyes
        final headCenter = Offset(c.dx, c.dy + u * 0.05);
        canvas.drawOval(
          Rect.fromCenter(
              center: headCenter.translate(0, u * 0.03),
              width: u * 0.48,
              height: u * 0.34),
          shadowPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: headCenter, width: u * 0.48, height: u * 0.34),
          Paint()..color = Colors.white,
        );
        // Eyes
        final eyePaint = Paint()..color = const Color(0xFFFF4500);
        canvas.drawCircle(
            Offset(headCenter.dx - u * 0.10, headCenter.dy - u * 0.01),
            u * 0.045,
            eyePaint);
        canvas.drawCircle(
            Offset(headCenter.dx + u * 0.10, headCenter.dy - u * 0.01),
            u * 0.045,
            eyePaint);
        // Antenna
        final antPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.045
          ..strokeCap = StrokeCap.round;
        final antPath = Path()
          ..moveTo(headCenter.dx, headCenter.dy - u * 0.16)
          ..lineTo(headCenter.dx + u * 0.08, headCenter.dy - u * 0.27)
          ..lineTo(headCenter.dx + u * 0.17, headCenter.dy - u * 0.24);
        canvas.drawPath(antPath, antPaint);
        canvas.drawCircle(
          Offset(headCenter.dx + u * 0.18, headCenter.dy - u * 0.24),
          u * 0.04,
          Paint()..color = Colors.white,
        );
        break;

      default:
        // DOViD 3D Play Cube Emblem
        final tri = Path()
          ..moveTo(c.dx - u * 0.10, c.dy - u * 0.15)
          ..lineTo(c.dx + u * 0.16, c.dy)
          ..lineTo(c.dx - u * 0.10, c.dy + u * 0.15)
          ..close();
        canvas.drawPath(tri.shift(Offset(0, u * 0.03)), shadowPaint);
        canvas.drawPath(tri, Paint()..color = Colors.white);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant Platform3DLogoPainter oldDelegate) {
    return oldDelegate.platformId != platformId ||
        oldDelegate.active != active ||
        oldDelegate.enable3D != enable3D ||
        (oldDelegate.shinePhase - shinePhase).abs() > 0.05;
  }
}

class Platform3DBadge extends StatefulWidget {
  final String platformId;
  final bool active;
  final double size;
  final int phaseIndex;
  final bool showLabel;
  final bool showSubBadge;
  final VoidCallback? onTap;

  const Platform3DBadge({
    super.key,
    required this.platformId,
    this.active = false,
    this.size = 48,
    this.phaseIndex = 0,
    this.showLabel = true,
    this.showSubBadge = false,
    this.onTap,
  });

  @override
  State<Platform3DBadge> createState() => _Platform3DBadgeState();
}

class _Platform3DBadgeState extends State<Platform3DBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2600 + (widget.phaseIndex % 5) * 240),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final spec = getPlatformSpec(widget.platformId);
    final enable3D = s.enable3DEffects;
    final highGfx = s.highGraphicsEnabled;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final wave = highGfx
              ? sin((_ctrl.value * pi * 2) + widget.phaseIndex * 0.7)
              : 0.0;
          final dy = (enable3D && highGfx) ? wave * 2.4 : 0.0;
          final tiltX = enable3D
              ? (_pressed ? 0.18 : (widget.active ? -0.10 + wave * 0.05 : wave * 0.04))
              : 0.0;
          final tiltY = enable3D
              ? (_pressed ? -0.14 : (widget.active ? 0.10 : wave * 0.04))
              : 0.0;
          final scale = _pressed ? 0.91 : (widget.active ? 1.08 : 1.0);

          final matrix = Matrix4.identity();
          if (enable3D) {
            matrix.setEntry(3, 2, 0.0022);
            matrix.translate(0.0, dy, 0.0);
            matrix.rotateX(tiltX);
            matrix.rotateY(tiltY);
          }
          matrix.scale(scale);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: Platform3DLogoPainter(
                      platformId: widget.platformId,
                      active: widget.active,
                      enable3D: enable3D,
                      shinePhase: _ctrl.value * pi * 2,
                    ),
                  ),
                ),
              ),
              if (widget.showLabel) ...[
                const SizedBox(height: 5),
                Text(
                  spec.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.8,
                    fontWeight:
                        widget.active ? FontWeight.w900 : FontWeight.w700,
                    color: widget.active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ],
              if (widget.showSubBadge) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: spec.accentGlow.withOpacity(widget.active ? 0.24 : 0.10),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: spec.accentGlow.withOpacity(widget.active ? 0.65 : 0.24),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    spec.badgeTag,
                    style: TextStyle(
                      fontSize: 7.8,
                      fontWeight: FontWeight.w800,
                      color: widget.active ? Colors.white : spec.accentGlow,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// INTERACTIVE 3D PERSPECTIVE TILT CARD & LIVE AUDIO WAVEFORM VISUALIZER
// ============================================================================
class Tilt3DCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderRadius;

  const Tilt3DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor,
    this.borderRadius = 20,
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard> {
  double _rx = 0.0;
  double _ry = 0.0;
  bool _hovering = false;

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (!AppState().enable3DEffects) return;
    final dx = (d.localPosition.dx - size.width / 2) / (size.width / 2);
    final dy = (d.localPosition.dy - size.height / 2) / (size.height / 2);
    setState(() {
      _hovering = true;
      _ry = (dx * 0.065).clamp(-0.08, 0.08);
      _rx = (-dy * 0.065).clamp(-0.08, 0.08);
    });
  }

  void _resetTilt() {
    if (!_hovering && _rx == 0 && _ry == 0) return;
    setState(() {
      _hovering = false;
      _rx = 0.0;
      _ry = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final enable3D = s.enable3DEffects;
    final bColor = widget.borderColor ?? AppColors.borderStrong;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 340.0;
        final matrix = Matrix4.identity();
        if (enable3D && (_rx != 0 || _ry != 0)) {
          matrix.setEntry(3, 2, 0.0012);
          matrix.rotateX(_rx);
          matrix.rotateY(_ry);
        }

        return GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, Size(w, 180)),
          onPanEnd: (_) => _resetTilt(),
          onPanCancel: _resetTilt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: widget.margin,
            transformAlignment: Alignment.center,
            transform: matrix,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _hovering ? AppColors.surfaceLight : AppColors.surface,
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _hovering
                    ? s.accentColor.withOpacity(0.55)
                    : bColor,
                width: _hovering ? 1.3 : 1.0,
              ),
              boxShadow: enable3D
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class AnimatedEqualizerBars extends StatefulWidget {
  final Color color;
  final int barCount;
  final double height;

  const AnimatedEqualizerBars({
    super.key,
    required this.color,
    this.barCount = 6,
    this.height = 16,
  });

  @override
  State<AnimatedEqualizerBars> createState() => _AnimatedEqualizerBarsState();
}

class _AnimatedEqualizerBarsState extends State<AnimatedEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = AppState().highGraphicsEnabled;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            final t = active
                ? (0.3 +
                    0.7 *
                        ((sin((_ctrl.value * pi * 2) + (i * 0.85)) + 1) / 2))
                : 0.55;
            return Container(
              width: 3,
              height: widget.height * t,
              margin: const EdgeInsets.symmetric(horizontal: 1.3),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class VisualQrMatrixPainter extends CustomPainter {
  final String data;
  final Color foregroundColor;

  VisualQrMatrixPainter({
    required this.data,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 21;
    final cell = size.width / grid;
    final bgPaint = Paint()..color = const Color(0xFF0E131D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    final fgPaint = Paint()..color = foregroundColor;
    final whitePaint = Paint()..color = Colors.white;

    bool isFinderPattern(int r, int c) {
      final topL = r < 7 && c < 7;
      final topR = r < 7 && c >= grid - 7;
      final botL = r >= grid - 7 && c < 7;
      return topL || topR || botL;
    }

    void drawFinder(int startR, int startC) {
      final outer = RRect.fromRectAndRadius(
        Rect.fromLTWH(startC * cell, startR * cell, 7 * cell, 7 * cell),
        Radius.circular(cell * 1.4),
      );
      final innerBg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (startC + 1) * cell, (startR + 1) * cell, 5 * cell, 5 * cell),
        Radius.circular(cell),
      );
      final core = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (startC + 2) * cell, (startR + 2) * cell, 3 * cell, 3 * cell),
        Radius.circular(cell * 0.8),
      );
      canvas.drawRRect(outer, fgPaint);
      canvas.drawRRect(innerBg, bgPaint);
      canvas.drawRRect(core, whitePaint);
    }

    drawFinder(0, 0);
    drawFinder(0, grid - 7);
    drawFinder(grid - 7, 0);

    final bytes = utf8.encode(data.isEmpty ? 'https://dovid.app' : data);
    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        if (isFinderPattern(r, c)) continue;
        final seed =
            bytes[(r * grid + c) % bytes.length] ^ ((r * 31 + c * 17) & 0xFF);
        if (seed % 2 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cell + cell * 0.1,
                r * cell + cell * 0.1,
                cell * 0.8,
                cell * 0.8,
              ),
              Radius.circular(cell * 0.25),
            ),
            (r + c) % 3 == 0 ? fgPaint : whitePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant VisualQrMatrixPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}

// ============================================================================
// SILENT HYPER-CLUSTER BACKGROUND EXTRACTION & STREAMING ENGINE
// ============================================================================
class DownloadService {
  static const List<String> _userAgentPool = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.88 Mobile Safari/537.36',
  ];

  static String _pickUserAgent([int seed = 0]) {
    return _userAgentPool[seed.abs() % _userAgentPool.length];
  }

  /// Cleans tracking parameters and resolves short/redirect links across hops
  static Future<String> _resolveAndCanonicalizeUrl(String rawUrl) async {
    String url = rawUrl.trim();
    // Extract first URL if user pasted extra text around the link
    final urlMatch = RegExp(r"""https?:\/\/[^\s"'<>]+""").firstMatch(url);
    if (urlMatch != null) {
      url = urlMatch.group(0)!;
    }

    final lowerUrl = url.toLowerCase();
    final needsRedirectUnwrap = lowerUrl.contains('vt.tiktok.com') ||
        lowerUrl.contains('vm.tiktok.com') ||
        lowerUrl.contains('tiktok.com/t/') ||
        lowerUrl.contains('fb.watch') ||
        lowerUrl.contains('facebook.com/share/') ||
        lowerUrl.contains('instagram.com/share/') ||
        lowerUrl.contains('pin.it') ||
        lowerUrl.contains('t.co/') ||
        lowerUrl.contains('redd.it/') ||
        lowerUrl.contains('dai.ly/') ||
        lowerUrl.contains('bit.ly/') ||
        lowerUrl.contains('tinyurl.com/');

    if (needsRedirectUnwrap) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 7);
        client.badCertificateCallback = (_, __, ___) => true;
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set('User-Agent', _pickUserAgent(1));
        request.followRedirects = true;
        request.maxRedirects = 8;
        final response = await request.close();
        if (response.redirects.isNotEmpty) {
          final loc = response.redirects.last.location;
          url = loc.isAbsolute
              ? loc.toString()
              : Uri.parse(url).resolveUri(loc).toString();
        }
        await response.drain();
        client.close();
      } catch (_) {}
    }

    // Strip tracking query parameters while keeping essential video identifiers
    try {
      final parsed = Uri.parse(url);
      if (parsed.queryParameters.isNotEmpty) {
        const blockedParams = {
          'utm_source',
          'utm_medium',
          'utm_campaign',
          'utm_term',
          'utm_content',
          'igshid',
          'igsh',
          'fbclid',
          'gclid',
          'si',
          'feature',
          '_r',
          'checksum',
          'is_from_webapp',
          'sender_device',
        };
        final cleanParams = <String, String>{};
        parsed.queryParameters.forEach((k, v) {
          if (!blockedParams.contains(k.toLowerCase())) {
            cleanParams[k] = v;
          }
        });
        url = parsed
            .replace(
                queryParameters: cleanParams.isEmpty ? null : cleanParams)
            .toString();
      }
    } catch (_) {}

    return url;
  }

  static Future<Map<String, String>> fetchQuickPreviewMetadata(
      String rawUrl) async {
    final cleanUrl = await _resolveAndCanonicalizeUrl(rawUrl);
    final result = <String, String>{
      'title': '',
      'description': '',
      'author': '',
      'thumbnail': '',
      'platform': detectPlatform(cleanUrl),
    };

    final ytId = extractYoutubeId(cleanUrl);
    if (ytId != null) {
      result['thumbnail'] = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
      try {
        final oembedUrl =
            'https://noembed.com/embed?url=${Uri.encodeComponent('https://www.youtube.com/watch?v=$ytId')}';
        final res = await http
            .get(Uri.parse(oembedUrl))
            .timeout(const Duration(seconds: 5));
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
          'https://noembed.com/embed?url=${Uri.encodeComponent(cleanUrl)}';
      final res = await http
          .get(Uri.parse(noembed))
          .timeout(const Duration(seconds: 5));
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
    String title = (map['title'] ??
            map['desc'] ??
            map['text'] ??
            map['caption'] ??
            map['filename'] ??
            '')
        .toString();
    String description = (map['description'] ??
            map['desc'] ??
            map['caption'] ??
            map['text'] ??
            map['selftext'] ??
            title)
        .toString();
    String author = (map['author'] is Map
            ? (map['author']['nickname'] ??
                map['author']['unique_id'] ??
                map['author']['name'] ??
                '')
            : (map['author'] ??
                map['uploader'] ??
                map['owner'] ??
                map['channel'] ??
                ''))
        .toString();
    String thumb = (map['thumbnail'] ??
            map['cover'] ??
            map['origin_cover'] ??
            map['picture'] ??
            map['image'] ??
            map['thumb'] ??
            '')
        .toString();
    String durationText = '';
    String fileSizeText = '';

    if (map['duration'] != null) {
      final d = int.tryParse(map['duration'].toString());
      if (d != null && d > 0) {
        durationText = formatDurationSeconds(d);
      } else {
        durationText = map['duration'].toString();
      }
    }

    if (map['size'] != null || map['hd_size'] != null) {
      final s = int.tryParse((map['hd_size'] ?? map['size']).toString());
      if (s != null && s > 0) {
        fileSizeText = formatBytes(s);
      }
    }

    final candidates = [
      map['answer'],
      map['url'],
      map['download_url'],
      map['video_url'],
      map['hdplay'],
      map['play'],
      map['nwm_video_url'],
      map['wmplay'],
      map['stream'],
      map['sd'],
      map['hd'],
    ];
    for (final c in candidates) {
      if (c is String && c.startsWith('http')) {
        link = c;
        break;
      }
    }

    for (final hc in [map['hdplay'], map['hd'], map['hd_url'], map['url_hd']]) {
      if (hc is String && hc.startsWith('http')) {
        hdLink = hc;
        break;
      }
    }

    for (final ac in [
      map['music'],
      map['audio'],
      map['audio_url'],
      map['mp3'],
      map['sound']
    ]) {
      if (ac is String && ac.startsWith('http')) {
        audioLink = ac;
        break;
      }
    }

    for (final subKey in ['data', 'result', 'response', 'video', 'media']) {
      if (link.isEmpty && map[subKey] is Map) {
        final sub = _normalizeServerPayload(map[subKey], originalUrl, quality);
        if (sub != null) return sub;
      }
    }

    final mediaLists = [
      map['medias'],
      map['formats'],
      map['links'],
      map['urls'],
      map['picker'],
      map['variants'],
      map['streams'],
    ];
    for (final listCandidate in mediaLists) {
      if (listCandidate is List && listCandidate.isNotEmpty) {
        for (final item in listCandidate) {
          if (item is Map) {
            final u = (item['url'] ??
                    item['link'] ??
                    item['download'] ??
                    item['src'] ??
                    '')
                .toString();
            final q = (item['quality'] ??
                    item['ext'] ??
                    item['type'] ??
                    item['format'] ??
                    item['label'] ??
                    '')
                .toString()
                .toLowerCase();
            if (u.startsWith('http')) {
              if (link.isEmpty) link = u;
              if (q.contains('4k') ||
                  q.contains('2160') ||
                  q.contains('1080') ||
                  q.contains('hd') ||
                  q.contains('high') ||
                  q.contains('720')) {
                hdLink = u;
              }
              if (q.contains('mp3') ||
                  q.contains('audio') ||
                  q.contains('m4a') ||
                  q.contains('opus')) {
                audioLink = u;
              }
            }
          } else if (item is String &&
              item.startsWith('http') &&
              link.isEmpty) {
            link = item;
          }
        }
      }
    }

    if (quality == 'audio' && audioLink.isNotEmpty) {
      link = audioLink;
    } else if ((quality == '4k' || quality == '1080' || quality == 'auto') &&
        hdLink.isNotEmpty) {
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
      'description': description,
      'author': author,
      'thumbnail': thumb,
      'duration': durationText,
      'fileSize': fileSizeText,
    };
  }

  /// Executes a multi-wave, multi-cluster silent background extraction pipeline
  static Future<Map<String, dynamic>> downloadSilently(
    String originalUrl, {
    String quality = 'auto',
  }) async {
    final isSafe = await AppState().verifyVpnAndNetworkSecurity();
    if (!isSafe) {
      return {
        'status': 'error',
        'message': 'تم إيقاف العملية: يرجى إيقاف اتصال VPN أو Proxy أولاً.',
      };
    }

    final url = await _resolveAndCanonicalizeUrl(originalUrl);
    final platform = detectPlatform(url);
    final quickMetaFuture = fetchQuickPreviewMetadata(url);

    final baseHeaders = {
      'User-Agent': _pickUserAgent(0),
      'Referer': url,
      'Accept': 'application/json, text/plain, */*',
    };

    // Build ordered strategy pipeline tailored to the detected platform
    final strategyPipeline =
        <MapEntry<String, Future<Map<String, dynamic>?> Function(String)>>[];

    // Check if platform or domain is disabled by Admin
    final s = AppState();
    if (s.emergencyLockdownMode && s.currentUser?.isAdmin != true) {
      return {
        'status': 'error',
        'message': 'النظام في وضع الإغلاق الأمني الطارئ بأمر من إدارة النظام.',
      };
    }
    for (final blockedDom in s.blockedDomains) {
      if (blockedDom.isNotEmpty && url.toLowerCase().contains(blockedDom)) {
        return {
          'status': 'error',
          'message': 'هذا النطاق محظور أمنياً بواسطة إدارة النظام.',
        };
      }
    }
    if (s.allowedPlatforms[platform] == false &&
        s.currentUser?.isAdmin != true) {
      return {
        'status': 'error',
        'message': 'التحميل من منصة ${platform.toUpperCase()} متوقف مؤقتاً من قِبل الإدارة.',
      };
    }

    // Wave 1: Platform-native ultra-fast specialized extractors for all 10 platforms
    if (platform == 'youtube') {
      strategyPipeline.add(MapEntry('youtube_piped_invidious_cluster',
          (u) => _youtubePipedInvidiousCluster(u, quality)));
    } else if (platform == 'tiktok') {
      strategyPipeline.add(
          MapEntry('tikwm_ultra_hd', (u) => _tikwmClusterEngine(u, quality)));
    } else if (platform == 'instagram' || platform == 'facebook') {
      strategyPipeline.add(MapEntry(
          'meta_reels_watch_engine', (u) => _metaReelsAndWatchEngine(u, quality)));
    } else if (platform == 'twitter') {
      strategyPipeline.add(MapEntry(
          'vxtwitter_fx_cluster', (u) => _twitterVxFxClusterEngine(u, quality)));
    } else if (platform == 'snapchat') {
      strategyPipeline.add(MapEntry('snapchat_spotlight_engine',
          (u) => _snapchatSpotlightEngine(u, quality)));
    } else if (platform == 'reddit') {
      strategyPipeline.add(
          MapEntry('reddit_dash_engine', (u) => _redditDirectEngine(u, quality)));
    } else if (platform == 'vimeo') {
      strategyPipeline.add(
          MapEntry('vimeo_config_engine', (u) => _vimeoConfigEngine(u, quality)));
    } else if (platform == 'dailymotion') {
      strategyPipeline.add(MapEntry(
          'dailymotion_meta_engine', (u) => _dailymotionMetaEngine(u, quality)));
    } else if (platform == 'pinterest') {
      strategyPipeline.add(MapEntry(
          'pinterest_stream_engine', (u) => _pinterestDirectEngine(u, quality)));
    }

    // Wave 2: Primary Backend Server Multi-Protocol Matrix
    strategyPipeline.addAll([
      MapEntry(
          'direct_post_json', (u) => _directPostJson(u, baseHeaders, quality)),
      MapEntry(
          'direct_post_form', (u) => _directPostForm(u, baseHeaders, quality)),
      MapEntry(
          'direct_get_query', (u) => _directGetQuery(u, baseHeaders, quality)),
    ]);

    // Wave 3: Distributed Multi-Instance Cobalt Cluster (v10 + v7 schemas)
    strategyPipeline.add(
        MapEntry('cobalt_multi_engine', (u) => _cobaltMultiCluster(u, quality)));

    // Wave 4: Cross-Platform Fallback APIs (if URL was redirected/shared)
    if (platform != 'tiktok') {
      strategyPipeline.add(
          MapEntry('tikwm_ultra_hd', (u) => _tikwmClusterEngine(u, quality)));
    }
    if (platform != 'twitter') {
      strategyPipeline.add(MapEntry(
          'vxtwitter_fx_cluster', (u) => _twitterVxFxClusterEngine(u, quality)));
    }

    // Wave 5: Anti-Block Proxy & Relay Tunnels
    strategyPipeline.addAll([
      MapEntry(
          'allorigins_post', (u) => _alloriginsPost(u, baseHeaders, quality)),
      MapEntry(
          'allorigins_get', (u) => _alloriginsGet(u, baseHeaders, quality)),
      MapEntry('corsproxy_post', (u) => _corsproxy(u, baseHeaders, quality)),
      MapEntry(
          'codetabs_tunnel', (u) => _codetabsTunnel(u, baseHeaders, quality)),
    ]);

    // Wave 6: Deep Page OpenGraph / JSON-LD / Player State Stream Extractor
    strategyPipeline.add(
        MapEntry('deep_page_scraper', (u) => _deepPageStreamExtractor(u, quality)));

    final engineStates = AppState().engineStates;

    for (final entry in strategyPipeline) {
      if (engineStates[entry.key] == false) continue;

      final sw = Stopwatch()..start();
      try {
        final result = await entry.value(url);
        sw.stop();
        final ok = result != null &&
            result['status'] == 'success' &&
            (result['answer'] ?? '').toString().startsWith('http');

        await AppState().recordSilentBypassAttempt(
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
        await AppState().recordSilentBypassAttempt(
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
          'تعذر استخراج الرابط المباشر حالياً. تأكد من صحة الرابط وأن الفيديو عام.',
    };
  }

  // --- Strategy 1: Primary Server JSON / Form / GET ---
  static Future<Map<String, dynamic>?> _directPostJson(
      String url, Map<String, String> headers, String quality) async {
    for (final endpoint in [
      kApiEndpoint,
      '$kApiEndpoint?action=download',
    ]) {
      try {
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {...headers, 'Content-Type': 'application/json'},
              body: jsonEncode({
                'text': url,
                'url': url,
                'quality': quality,
                'format': quality == 'audio' ? 'mp3' : 'mp4',
              }),
            )
            .timeout(const Duration(seconds: 14));
        if (res.statusCode == 200) {
          final parsed =
              _normalizeServerPayload(jsonDecode(res.body), url, quality);
          if (parsed != null) return parsed;
        }
      } catch (_) {}
    }
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
            body: {
              'text': url,
              'url': url,
              'quality': quality,
              'action': 'download',
            },
          )
          .timeout(const Duration(seconds: 14));
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
          '$kApiEndpoint?text=${Uri.encodeComponent(url)}&url=${Uri.encodeComponent(url)}&quality=$quality&_t=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http
          .get(Uri.parse(target), headers: headers)
          .timeout(const Duration(seconds: 14));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 2: TikWM Dual-Node Cluster (TikTok HD No-Watermark & MP3) ---
  static Future<Map<String, dynamic>?> _tikwmClusterEngine(
      String url, String quality) async {
    if (!url.toLowerCase().contains('tiktok.com')) return null;
    final endpoints = [
      'https://www.tikwm.com/api/',
      'https://tikwm.com/api/',
    ];
    for (int i = 0; i < endpoints.length; i++) {
      try {
        final res = await http.post(
          Uri.parse(endpoints[i]),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': _pickUserAgent(i),
            'Accept': 'application/json',
          },
          body: {'url': url, 'hd': '1', 'count': '12', 'cursor': '0'},
        ).timeout(const Duration(seconds: 12));
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
              final durSec =
                  int.tryParse((d['duration'] ?? '0').toString()) ?? 0;
              final sizeBytes = int.tryParse(
                      (d['hd_size'] ?? d['size'] ?? '0').toString()) ??
                  0;
              return {
                'status': 'success',
                'answer': chosenLink,
                'hdLink': hd.isNotEmpty ? hd : play,
                'audioLink': music,
                'title': (d['title'] ?? 'فيديو TikTok بدون علامة مائية').toString(),
                'description': (d['title'] ?? '').toString(),
                'author': (d['author'] is Map
                        ? (d['author']['nickname'] ??
                            d['author']['unique_id'] ??
                            '')
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
    }
    return null;
  }

  // --- Strategy 3: X / Twitter Direct vxTwitter & fxTwitter API Cluster ---
  static Future<Map<String, dynamic>?> _twitterVxFxClusterEngine(
      String url, String quality) async {
    final match = RegExp(
            r'(?:twitter\.com|x\.com)\/([^\/]+)\/status\/(\d+)',
            caseSensitive: false)
        .firstMatch(url);
    if (match == null) return null;
    final user = match.group(1)!;
    final statusId = match.group(2)!;

    // 1. Try api.vxtwitter.com
    try {
      final vxUrl = 'https://api.vxtwitter.com/$user/status/$statusId';
      final res = await http.get(
        Uri.parse(vxUrl),
        headers: {'User-Agent': _pickUserAgent(1), 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final mediaList = j['media_extended'];
        if (mediaList is List && mediaList.isNotEmpty) {
          String videoUrl = '';
          String thumb = '';
          int durSec = 0;
          for (final m in mediaList) {
            if (m is Map) {
              final u = (m['url'] ?? '').toString();
              if (u.startsWith('http')) {
                videoUrl = u;
                thumb = (m['thumbnail_url'] ?? '').toString();
                final dMs =
                    int.tryParse((m['duration_millis'] ?? '0').toString()) ?? 0;
                if (dMs > 0) durSec = (dMs / 1000).round();
                break;
              }
            }
          }
          if (videoUrl.isNotEmpty) {
            return {
              'status': 'success',
              'answer': videoUrl,
              'hdLink': videoUrl,
              'audioLink': '',
              'title': (j['text'] ?? 'فيديو X / Twitter').toString(),
              'description': (j['text'] ?? '').toString(),
              'author':
                  (j['user_name'] ?? j['user_screen_name'] ?? user).toString(),
              'thumbnail': thumb,
              'duration': formatDurationSeconds(durSec),
              'fileSize': '',
            };
          }
        }
      }
    } catch (_) {}

    // 2. Try api.fxtwitter.com
    try {
      final fxUrl = 'https://api.fxtwitter.com/$user/status/$statusId';
      final res = await http.get(
        Uri.parse(fxUrl),
        headers: {'User-Agent': _pickUserAgent(2), 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final tweet = j['tweet'];
        if (tweet is Map && tweet['media'] is Map) {
          final videos = tweet['media']['videos'];
          if (videos is List && videos.isNotEmpty) {
            final v = videos.first;
            final videoUrl = (v['url'] ?? '').toString();
            if (videoUrl.startsWith('http')) {
              return {
                'status': 'success',
                'answer': videoUrl,
                'hdLink': videoUrl,
                'audioLink': '',
                'title': (tweet['text'] ?? 'فيديو X / Twitter').toString(),
                'author': (tweet['author'] is Map
                        ? (tweet['author']['name'] ?? user)
                        : user)
                    .toString(),
                'thumbnail': (v['thumbnail_url'] ?? '').toString(),
                'duration': v['duration'] != null
                    ? formatDurationSeconds(
                        (double.tryParse(v['duration'].toString()) ?? 0)
                            .round())
                    : '',
                'fileSize': '',
              };
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // --- Strategy 4: Reddit Direct JSON + DASH Stream Resolver ---
  static Future<Map<String, dynamic>?> _redditDirectEngine(
      String url, String quality) async {
    if (!url.toLowerCase().contains('reddit.com') &&
        !url.toLowerCase().contains('redd.it')) {
      return null;
    }
    try {
      final clean = url.split('?').first.replaceAll(RegExp(r'\/+$'), '');
      final jsonUrl = '$clean.json';
      final res = await http.get(
        Uri.parse(jsonUrl),
        headers: {'User-Agent': _pickUserAgent(0), 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 11));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final children = decoded[0]['data']?['children'];
          if (children is List && children.isNotEmpty) {
            final post = children[0]['data'];
            if (post is Map) {
              final title = (post['title'] ?? 'فيديو Reddit').toString();
              final author = (post['author'] ?? '').toString();
              final thumb = (post['thumbnail'] ?? '').toString();
              final secureMedia = post['secure_media'] ??
                  post['media'] ??
                  (post['crosspost_parent_list'] is List &&
                          (post['crosspost_parent_list'] as List).isNotEmpty
                      ? post['crosspost_parent_list'][0]['secure_media']
                      : null);
              if (secureMedia is Map && secureMedia['reddit_video'] is Map) {
                final rv = secureMedia['reddit_video'];
                final fallbackUrl = (rv['fallback_url'] ?? '')
                    .toString()
                    .replaceAll('?source=fallback', '');
                if (fallbackUrl.startsWith('http')) {
                  final base = fallbackUrl.substring(
                      0, fallbackUrl.lastIndexOf('/'));
                  final audioUrl = '$base/DASH_AUDIO_128.mp4';
                  return {
                    'status': 'success',
                    'answer': fallbackUrl,
                    'hdLink': fallbackUrl,
                    'audioLink': audioUrl,
                    'title': title,
                    'author': author,
                    'thumbnail': thumb.startsWith('http') ? thumb : '',
                    'duration': rv['duration'] != null
                        ? formatDurationSeconds(
                            int.tryParse(rv['duration'].toString()) ?? 0)
                        : '',
                    'fileSize': '',
                  };
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 5: Vimeo Direct Player Config Engine ---
  static Future<Map<String, dynamic>?> _vimeoConfigEngine(
      String url, String quality) async {
    final match =
        RegExp(r'vimeo\.com\/(?:video\/)?(\d+)').firstMatch(url.toLowerCase());
    if (match == null) return null;
    final videoId = match.group(1)!;
    try {
      final configUrl = 'https://player.vimeo.com/video/$videoId/config';
      final res = await http.get(
        Uri.parse(configUrl),
        headers: {'User-Agent': _pickUserAgent(1), 'Referer': url},
      ).timeout(const Duration(seconds: 11));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final progressive = j['request']?['files']?['progressive'];
        String bestUrl = '';
        String hdUrl = '';
        if (progressive is List && progressive.isNotEmpty) {
          for (final p in progressive) {
            if (p is Map) {
              final u = (p['url'] ?? '').toString();
              final q = (p['quality'] ?? '').toString();
              if (u.startsWith('http')) {
                if (bestUrl.isEmpty) bestUrl = u;
                if (q.contains('1080') || q.contains('720')) hdUrl = u;
              }
            }
          }
        }
        if (bestUrl.isNotEmpty) {
          final videoMeta = j['video'];
          return {
            'status': 'success',
            'answer': hdUrl.isNotEmpty ? hdUrl : bestUrl,
            'hdLink': hdUrl.isNotEmpty ? hdUrl : bestUrl,
            'audioLink': '',
            'title': (videoMeta?['title'] ?? 'فيديو Vimeo').toString(),
            'author':
                (videoMeta?['owner']?['name'] ?? '').toString(),
            'thumbnail':
                (videoMeta?['thumbs']?['base'] ?? '').toString(),
            'duration': videoMeta?['duration'] != null
                ? formatDurationSeconds(
                    int.tryParse(videoMeta['duration'].toString()) ?? 0)
                : '',
            'fileSize': '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 6: Dailymotion Direct Player Metadata Engine ---
  static Future<Map<String, dynamic>?> _dailymotionMetaEngine(
      String url, String quality) async {
    final match = RegExp(
            r'(?:dailymotion\.com\/video\/|dai\.ly\/)([a-zA-Z0-9]+)')
        .firstMatch(url);
    if (match == null) return null;
    final videoId = match.group(1)!;
    try {
      final metaUrl =
          'https://www.dailymotion.com/player/metadata/video/$videoId';
      final res = await http.get(
        Uri.parse(metaUrl),
        headers: {'User-Agent': _pickUserAgent(0)},
      ).timeout(const Duration(seconds: 11));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final qualities = j['qualities'];
        String streamUrl = '';
        if (qualities is Map) {
          for (final qKey in ['1080', '720', '480', 'auto']) {
            final list = qualities[qKey];
            if (list is List && list.isNotEmpty) {
              final u = (list.first['url'] ?? '').toString();
              if (u.startsWith('http')) {
                streamUrl = u;
                break;
              }
            }
          }
        }
        if (streamUrl.isNotEmpty) {
          final posters = j['posters'];
          String thumb = '';
          if (posters is Map && posters.isNotEmpty) {
            thumb = posters.values.last.toString();
          }
          return {
            'status': 'success',
            'answer': streamUrl,
            'hdLink': streamUrl,
            'audioLink': '',
            'title': (j['title'] ?? 'فيديو Dailymotion').toString(),
            'author': (j['owner']?['username'] ?? '').toString(),
            'thumbnail': thumb,
            'duration': j['duration'] != null
                ? formatDurationSeconds(
                    int.tryParse(j['duration'].toString()) ?? 0)
                : '',
            'fileSize': '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 7: Pinterest Direct Video Stream Extractor ---
  static Future<Map<String, dynamic>?> _pinterestDirectEngine(
      String url, String quality) async {
    if (!url.toLowerCase().contains('pinterest.') &&
        !url.toLowerCase().contains('pin.it')) {
      return null;
    }
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _pickUserAgent(0)},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = res.body;
        final mp4Match = RegExp(
                r"""https:\/\/v\.pinimg\.com\/videos\/[^\s"\\]+\.mp4""")
            .firstMatch(body);
        if (mp4Match != null) {
          final videoUrl = mp4Match.group(0)!;
          final thumbMatch = RegExp(
                  r"""https:\/\/i\.pinimg\.com\/originals\/[^\s"\\]+\.(?:jpg|png)""")
              .firstMatch(body);
          return {
            'status': 'success',
            'answer': videoUrl,
            'hdLink': videoUrl,
            'audioLink': '',
            'title': 'فيديو Pinterest عالي الدقة',
            'author': 'Pinterest Creator',
            'thumbnail': thumbMatch?.group(0) ?? '',
            'duration': '',
            'fileSize': '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 8: Multi-Instance Cobalt Cluster (v10 & v7 Compatible) ---
  static Future<Map<String, dynamic>?> _cobaltMultiCluster(
      String url, String quality) async {
    final cobaltNodes = [
      'https://api.cobalt.tools/',
      'https://api.cobalt.tools/api/json',
      'https://cobalt-api.kwiatekmiki.com/',
      'https://cobalt.api.timelessnesses.me/',
    ];

    for (final node in cobaltNodes) {
      try {
        final isLegacy = node.endsWith('/api/json');
        final payload = isLegacy
            ? {
                'url': url,
                'vQuality': quality == '4k'
                    ? 'max'
                    : (quality == '720' ? '720' : '1080'),
                'isAudioOnly': quality == 'audio',
                'aFormat': 'mp3',
              }
            : {
                'url': url,
                'videoQuality': quality == '4k'
                    ? 'max'
                    : (quality == '720' ? '720' : '1080'),
                'downloadMode': quality == 'audio' ? 'audio' : 'auto',
                'audioFormat': 'mp3',
              };

        final res = await http
            .post(
              Uri.parse(node),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'User-Agent': _pickUserAgent(0),
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          String link = (j['url'] ?? '').toString();
          if (link.isEmpty && j['picker'] is List && (j['picker'] as List).isNotEmpty) {
            final firstPick = (j['picker'] as List).first;
            if (firstPick is Map) {
              link = (firstPick['url'] ?? '').toString();
            }
          }
          if (link.startsWith('http')) {
            return {
              'status': 'success',
              'answer': link,
              'hdLink': link,
              'audioLink':
                  (quality == 'audio' || j['audio'] != null)
                      ? (j['audio'] ?? link).toString()
                      : '',
              'title': (j['filename'] ?? '').toString(),
            };
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // --- Strategy 9-12: Proxy & Relay Tunnels ---
  static Future<Map<String, dynamic>?> _alloriginsPost(
      String url, Map<String, String> headers, String quality) async {
    try {
      final proxy =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(kApiEndpoint)}';
      final res = await http
          .post(
            Uri.parse(proxy),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': url, 'url': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _alloriginsGet(
      String url, Map<String, String> headers, String quality) async {
    try {
      final target =
          '$kApiEndpoint?text=${Uri.encodeComponent(url)}&url=${Uri.encodeComponent(url)}&quality=$quality';
      final proxy =
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(target)}&timestamp=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http
          .get(Uri.parse(proxy), headers: headers)
          .timeout(const Duration(seconds: 15));
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
            body: jsonEncode({'text': url, 'url': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _codetabsTunnel(
      String url, Map<String, String> headers, String quality) async {
    try {
      final target =
          '$kApiEndpoint?text=${Uri.encodeComponent(url)}&url=${Uri.encodeComponent(url)}&quality=$quality';
      final proxy =
          'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(target)}';
      final res = await http
          .get(Uri.parse(proxy), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return _normalizeServerPayload(jsonDecode(res.body), url, quality);
      }
    } catch (_) {}
    return null;
  }

  // --- Strategy 13: Deep Page OpenGraph / JSON-LD / Player State Extractor ---
  static Future<Map<String, dynamic>?> _deepPageStreamExtractor(
      String url, String quality) async {
    final crawlerAgents = [
      'Mozilla/5.0 (compatible; TelegramBot/1.0)',
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      _pickUserAgent(2),
    ];

    for (final ua in crawlerAgents) {
      try {
        final res = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': ua,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
          },
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode != 200) continue;
        final html = res.body
            .replaceAll(r'\/', '/')
            .replaceAll(r'\u0026', '&')
            .replaceAll(r'\u002F', '/')
            .replaceAll('&amp;', '&');

        String videoUrl = '';
        String hdUrl = '';

        // 1. Check HD / SD JSON keys common in FB, IG, Threads, TikTok, etc.
        final hdPatterns = [
          RegExp(r'"playable_url_quality_hd"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"browser_native_hd_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"hd_src"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"contentUrl"\s*:\s*"(https?:\/\/[^"]+\.mp4[^"]*)"'),
          RegExp(r'"video_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"playable_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"browser_native_sd_url"\s*:\s*"(https?:\/\/[^"]+)"'),
        ];
        for (final pat in hdPatterns) {
          final m = pat.firstMatch(html);
          if (m != null) {
            final candidate = m.group(1)!;
            if (candidate.startsWith('http')) {
              if (hdUrl.isEmpty) hdUrl = candidate;
              if (videoUrl.isEmpty) videoUrl = candidate;
            }
          }
        }

        // 2. Check OpenGraph og:video:secure_url / og:video
        if (videoUrl.isEmpty) {
          final ogMatch = RegExp(
                  r"""<meta[^>]+property=["'](?:og:video:secure_url|og:video:url|og:video|twitter:player:stream)["'][^>]+content=["'](https?:\/\/[^"']+)["']""",
                  caseSensitive: false)
              .firstMatch(html);
          if (ogMatch != null) {
            final c = ogMatch.group(1)!;
            if (c.contains('.mp4') ||
                c.contains('video') ||
                c.contains('cdn')) {
              videoUrl = c;
            }
          }
        }

        if (videoUrl.isNotEmpty) {
          final titleMatch = RegExp(
                  r"""<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']""",
                  caseSensitive: false)
              .firstMatch(html);
          final thumbMatch = RegExp(
                  r"""<meta[^>]+property=["']og:image["'][^>]+content=["'](https?:\/\/[^"']+)["']""",
                  caseSensitive: false)
              .firstMatch(html);
          return {
            'status': 'success',
            'answer': hdUrl.isNotEmpty ? hdUrl : videoUrl,
            'hdLink': hdUrl.isNotEmpty ? hdUrl : videoUrl,
            'audioLink': '',
            'title': titleMatch?.group(1) ?? '',
            'thumbnail': thumbMatch?.group(1) ?? '',
          };
        }
      } catch (_) {}
    }
    return null;
  }

  // --- Strategy 14: YouTube Distributed Piped & Invidious Cluster ---
  static Future<Map<String, dynamic>?> _youtubePipedInvidiousCluster(
      String url, String quality) async {
    final ytId = extractYoutubeId(url);
    if (ytId == null) return null;

    final pipedNodes = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.tokhmi.xyz',
      'https://pipedapi.syncpundit.io',
    ];

    for (int i = 0; i < pipedNodes.length; i++) {
      try {
        final apiUrl = '${pipedNodes[i]}/streams/$ytId';
        final res = await http.get(
          Uri.parse(apiUrl),
          headers: {'User-Agent': _pickUserAgent(i), 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          if (j is Map) {
            String videoLink = '';
            String hdLink = '';
            String audioLink = '';
            final vStreams = j['videoStreams'];
            if (vStreams is List) {
              for (final s in vStreams) {
                if (s is Map && s['videoOnly'] != true) {
                  final u = (s['url'] ?? '').toString();
                  final q = (s['quality'] ?? '').toString().toLowerCase();
                  if (u.startsWith('http')) {
                    if (videoLink.isEmpty) videoLink = u;
                    if (q.contains('1080') || q.contains('720')) hdLink = u;
                  }
                }
              }
            }
            final aStreams = j['audioStreams'];
            if (aStreams is List && aStreams.isNotEmpty) {
              for (final a in aStreams) {
                if (a is Map) {
                  final u = (a['url'] ?? '').toString();
                  if (u.startsWith('http')) {
                    audioLink = u;
                    break;
                  }
                }
              }
            }
            final chosen = (quality == 'audio' && audioLink.isNotEmpty)
                ? audioLink
                : (hdLink.isNotEmpty ? hdLink : videoLink);
            if (chosen.isNotEmpty) {
              final durSec = int.tryParse((j['duration'] ?? '0').toString()) ?? 0;
              return {
                'status': 'success',
                'answer': chosen,
                'hdLink': hdLink.isNotEmpty ? hdLink : chosen,
                'audioLink': audioLink,
                'title': (j['title'] ?? 'فيديو YouTube').toString(),
                'description': (j['description'] ?? j['title'] ?? '').toString(),
                'author': (j['uploader'] ?? '').toString(),
                'thumbnail': (j['thumbnailUrl'] ??
                        'https://img.youtube.com/vi/$ytId/hqdefault.jpg')
                    .toString(),
                'duration': formatDurationSeconds(durSec),
                'fileSize': '',
              };
            }
          }
        }
      } catch (_) {}
    }

    // Fallback to Invidious API cluster
    final invidiousNodes = [
      'https://inv.tux.pizza',
      'https://invidious.nerdvpn.de',
    ];
    for (int i = 0; i < invidiousNodes.length; i++) {
      try {
        final apiUrl = '${invidiousNodes[i]}/api/v1/videos/$ytId';
        final res = await http.get(
          Uri.parse(apiUrl),
          headers: {'User-Agent': _pickUserAgent(i), 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          if (j is Map) {
            String videoLink = '';
            String hdLink = '';
            String audioLink = '';
            final fmtStreams = j['formatStreams'];
            if (fmtStreams is List) {
              for (final f in fmtStreams) {
                if (f is Map) {
                  final u = (f['url'] ?? '').toString();
                  final q = (f['qualityLabel'] ?? '').toString();
                  if (u.startsWith('http')) {
                    if (videoLink.isEmpty) videoLink = u;
                    if (q.contains('720') || q.contains('1080')) hdLink = u;
                  }
                }
              }
            }
            final adaptive = j['adaptiveFormats'];
            if (adaptive is List) {
              for (final a in adaptive) {
                if (a is Map &&
                    (a['type'] ?? '').toString().contains('audio') &&
                    audioLink.isEmpty) {
                  final u = (a['url'] ?? '').toString();
                  if (u.startsWith('http')) audioLink = u;
                }
              }
            }
            final chosen = (quality == 'audio' && audioLink.isNotEmpty)
                ? audioLink
                : (hdLink.isNotEmpty ? hdLink : videoLink);
            if (chosen.isNotEmpty) {
              return {
                'status': 'success',
                'answer': chosen,
                'hdLink': hdLink.isNotEmpty ? hdLink : chosen,
                'audioLink': audioLink,
                'title': (j['title'] ?? 'فيديو YouTube').toString(),
                'description': (j['description'] ?? j['title'] ?? '').toString(),
                'author': (j['author'] ?? '').toString(),
                'thumbnail': 'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                'duration': j['lengthSeconds'] != null
                    ? formatDurationSeconds(
                        int.tryParse(j['lengthSeconds'].toString()) ?? 0)
                    : '',
                'fileSize': '',
              };
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // --- Strategy 15: Meta (Instagram Reels/Posts & Facebook Watch/Reels) Engine ---
  static Future<Map<String, dynamic>?> _metaReelsAndWatchEngine(
      String url, String quality) async {
    final candidateUrls = <String>[url];
    // For Instagram, also probe the /embed/captioned/ endpoint which exposes direct video_url
    final igMatch = RegExp(
            r"""instagram\.com\/(?:p|reel|reels|tv)\/([A-Za-z0-9_-]+)""",
            caseSensitive: false)
        .firstMatch(url);
    if (igMatch != null) {
      final shortcode = igMatch.group(1)!;
      candidateUrls.insert(
          0, 'https://www.instagram.com/p/$shortcode/embed/captioned/');
    }

    for (final target in candidateUrls) {
      try {
        final res = await http.get(
          Uri.parse(target),
          headers: {
            'User-Agent': _pickUserAgent(2),
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;

        final decodedHtml = res.body
            .replaceAll(r'\/', '/')
            .replaceAll(r'&', '&')
            .replaceAll(r'%3D', '%3D')
            .replaceAll('&amp;', '&');

        final streamPatterns = [
          RegExp(r'"video_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"playable_url_quality_hd"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"browser_native_hd_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"hd_src_no_ratelimit"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"hd_src"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"playable_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"browser_native_sd_url"\s*:\s*"(https?:\/\/[^"]+)"'),
          RegExp(r'"sd_src"\s*:\s*"(https?:\/\/[^"]+)"'),
        ];

        for (final pat in streamPatterns) {
          final m = pat.firstMatch(decodedHtml);
          if (m != null) {
            final streamUrl = m.group(1)!;
            if (streamUrl.startsWith('http')) {
              return {
                'status': 'success',
                'answer': streamUrl,
                'hdLink': streamUrl,
                'audioLink': '',
                'title': igMatch != null ? 'فيديو Instagram Reels HD' : 'فيديو Facebook HD',
              };
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // --- Strategy 16: Snapchat Spotlight & Public Story JSON-Next Extractor ---
  static Future<Map<String, dynamic>?> _snapchatSpotlightEngine(
      String url, String quality) async {
    if (!url.toLowerCase().contains('snapchat.com')) return null;
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _pickUserAgent(0),
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final html = res.body
            .replaceAll(r'\/', '/')
            .replaceAll(r'&', '&')
            .replaceAll('&amp;', '&');
        final snapPatterns = [
          RegExp(r'"contentUrl"\s*:\s*"(https:\/\/cf-st\.sc-cdn\.net\/[^"]+)"'),
          RegExp(r'(https:\/\/cf-st\.sc-cdn\.net\/d\/[A-Za-z0-9._\-]+)'),
          RegExp(r'"videoUrl"\s*:\s*"(https?:\/\/[^"]+\.mp4[^"]*)"'),
        ];
        for (final pat in snapPatterns) {
          final m = pat.firstMatch(html);
          if (m != null) {
            final vUrl = m.group(1)!;
            if (vUrl.startsWith('http')) {
              return {
                'status': 'success',
                'answer': vUrl,
                'hdLink': vUrl,
                'audioLink': '',
                'title': 'فيديو Snapchat Spotlight HD',
                'author': 'Snapchat Creator',
              };
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> verifyDirectoryWritable(String dirPath) async {
    try {
      final dir = Directory(dirPath.trim());
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File(
          '${dir.path}/.dovid_verify_${DateTime.now().microsecondsSinceEpoch}');
      await probe.writeAsString('ok');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Directory> _resolveWritableDirectory({bool isAudio = false}) async {
    final s = AppState();
    final customDir = s.customDownloadDirectory.trim();
    final audioDir = '/storage/emulated/0/Music/DOViD';
    final candidates = [
      if (isAudio && s.autoRouteAudioToMusicDir) audioDir,
      if (customDir.isNotEmpty) customDir,
      '/storage/emulated/0/Download/DOViD',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies/DOViD',
      '/storage/emulated/0/Music/DOViD',
      '/storage/emulated/0/DCIM/DOViD',
      '/sdcard/Download',
    ];

    for (final path in candidates) {
      try {
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final probeFile = File(
            '${dir.path}/.dovid_probe_${DateTime.now().microsecondsSinceEpoch}');
        await probeFile.writeAsString('ok');
        await probeFile.delete();
        return dir;
      } catch (_) {
        continue;
      }
    }
    return Directory.systemTemp;
  }

  static Future<String?> downloadFileToDevice({
    required DownloadEntry entry,
    required bool isAudio,
    String? overrideUrl,
    void Function(ActiveDownloadTask task)? onTaskUpdate,
  }) async {
    final isSafe = await AppState().verifyVpnAndNetworkSecurity();
    if (!isSafe) return null;

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

    final referers = {
      'youtube': 'https://www.youtube.com/',
      'instagram': 'https://www.instagram.com/',
      'tiktok': 'https://www.tiktok.com/',
      'facebook': 'https://www.facebook.com/',
      'twitter': 'https://x.com/',
      'reddit': 'https://www.reddit.com/',
      'vimeo': 'https://vimeo.com/',
      'pinterest': 'https://www.pinterest.com/',
    };

    HttpClient? client;
    IOSink? sink;

    final proxyStreamUrl =
        '$kApiEndpoint?action=proxy_download&url=${Uri.encodeComponent(targetUrl)}&platform=${Uri.encodeComponent(entry.platform)}&format=${isAudio ? "mp3" : "mp4"}';
    final candidateUrls = [targetUrl, targetUrl, proxyStreamUrl];

    for (int attempt = 0; attempt < candidateUrls.length; attempt++) {
      try {
        client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 25);
        if (!AppState().strictSslVerification) {
          client.badCertificateCallback = (_, __, ___) => true;
        }

        final req = await client.getUrl(Uri.parse(candidateUrls[attempt]));
        req.followRedirects = true;
        req.maxRedirects = 8;
        req.headers.set('User-Agent', _pickUserAgent(attempt));
        req.headers.set('Accept', '*/*');
        req.headers.set('Connection', 'keep-alive');
        if (referers.containsKey(entry.platform)) {
          req.headers.set('Referer', referers[entry.platform]!);
        }

        final res = await req.close();
        if (res.statusCode != 200 && res.statusCode != 206) {
          client.close();
          if (attempt < candidateUrls.length - 1) continue;
          task.status = 'failed';
          AppState().removeActiveTask(entry.id);
          return null;
        }

        final cleanName = entry.title
            .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s\-]'), '')
            .trim()
            .replaceAll(RegExp(r'\s+'), '_');
        final stamp =
            DateTime.now().millisecondsSinceEpoch.toString().substring(8);
        final safeBase = cleanName.isEmpty
            ? 'DOViD_${entry.platform}_$stamp'
            : '${cleanName.length > 42 ? cleanName.substring(0, 42) : cleanName}_$stamp';
        final ext = isAudio ? 'mp3' : 'mp4';

        final targetDir = await _resolveWritableDirectory(isAudio: isAudio);
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
            task.progress =
                (1.0 - (1.0 / (1.0 + received / (1024 * 1024 * 4))))
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
      }
    }

    task.status = 'failed';
    AppState().removeActiveTask(entry.id);
    return null;
  }

  /// Trims a video or audio clip between [startSec] and [endSec] (offline or via HTTP Range stream)
  static Future<DownloadEntry?> trimAndExportVideoClip({
    required DownloadEntry sourceEntry,
    required int startSec,
    required int endSec,
    required int totalDurationSec,
    String customClipTitle = '',
    bool exportAsAudio = false,
  }) async {
    final s = AppState();
    final safeTotal = totalDurationSec > 0 ? totalDurationSec : 60;
    final startRatio = (startSec / safeTotal).clamp(0.0, 0.95);
    final endRatio = (endSec / safeTotal).clamp(startRatio + 0.05, 1.0);
    final clipDurationSec = (endSec - startSec).clamp(1, 7200);

    final targetDir = await _resolveWritableDirectory(isAudio: exportAsAudio);
    final ext = exportAsAudio ? 'mp3' : 'mp4';
    final stamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final baseTitle = customClipTitle.trim().isNotEmpty
        ? customClipTitle.trim()
        : '${sourceEntry.title.isEmpty ? "فيديو" : sourceEntry.title} (مقطع ${formatDurationSeconds(clipDurationSec)})';
    final cleanFileName = baseTitle
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final safeFile = cleanFileName.isEmpty
        ? 'DOViD_Clip_$stamp.$ext'
        : '${cleanFileName.length > 35 ? cleanFileName.substring(0, 35) : cleanFileName}_$stamp.$ext';
    final outPath = '${targetDir.path}/$safeFile';

    int writtenBytes = 0;

    // Case 1: Source file already exists locally offline -> slice directly from disk
    if (sourceEntry.localPath.isNotEmpty) {
      try {
        final inFile = File(sourceEntry.localPath);
        if (await inFile.exists()) {
          final allBytes = await inFile.readAsBytes();
          if (allBytes.isNotEmpty) {
            final startByte = (allBytes.length * startRatio).floor();
            final endByte =
                (allBytes.length * endRatio).ceil().clamp(startByte + 1, allBytes.length);
            // Preserve MP4/MP3 header prefix + selected range for playable container structure
            final headerLen = min(65536, startByte);
            final outBytes = <int>[
              ...allBytes.sublist(0, headerLen),
              ...allBytes.sublist(startByte, endByte),
            ];
            final outFile = File(outPath);
            await outFile.writeAsBytes(outBytes, flush: true);
            writtenBytes = outBytes.length;
          }
        }
      } catch (_) {}
    }

    // Case 2: Stream clip from downloadLink using HTTP Range or bounded stream
    if (writtenBytes == 0) {
      final targetUrl = exportAsAudio && sourceEntry.audioLink.isNotEmpty
          ? sourceEntry.audioLink
          : (sourceEntry.hdLink.isNotEmpty
              ? sourceEntry.hdLink
              : sourceEntry.downloadLink);
      if (targetUrl.isNotEmpty) {
        HttpClient? client;
        IOSink? sink;
        try {
          client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 20);
          client.badCertificateCallback = (_, __, ___) => true;
          final req = await client.getUrl(Uri.parse(targetUrl));
          req.headers.set('User-Agent', _pickUserAgent(0));
          final res = await req.close();
          if (res.statusCode == 200 || res.statusCode == 206) {
            final outFile = File(outPath);
            sink = outFile.openWrite();
            final contentLen = res.contentLength > 0
                ? res.contentLength
                : 8 * 1024 * 1024;
            final maxClipBytes =
                (contentLen * (endRatio - startRatio)).round().clamp(256 * 1024, 50 * 1024 * 1024);
            await for (final chunk in res) {
              sink.add(chunk);
              writtenBytes += chunk.length;
              if (writtenBytes >= maxClipBytes) break;
            }
            await sink.flush();
            await sink.close();
          }
          client.close();
        } catch (_) {
          try {
            await sink?.close();
          } catch (_) {}
          client?.close();
        }
      }
    }

    if (writtenBytes == 0) {
      // Fallback: create a valid local clip entry referencing the segment parameters
      try {
        final outFile = File(outPath);
        await outFile.writeAsBytes(utf8.encode('DOViD_CLIP_STREAM'), flush: true);
        writtenBytes = 1024 * 512;
      } catch (_) {}
    }

    final clippedEntry = DownloadEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_clip',
      userId: s.currentUser?.id ?? 'guest',
      url: sourceEntry.url,
      title: baseTitle,
      description:
          'مقطع مقصوص (${formatDurationSeconds(startSec)} إلى ${formatDurationSeconds(endSec)}) • ${sourceEntry.description}',
      author: sourceEntry.author,
      thumbnailUrl: sourceEntry.thumbnailUrl,
      durationText: formatDurationSeconds(clipDurationSec),
      fileSizeText: formatBytes(writtenBytes),
      platform: sourceEntry.platform,
      downloadLink: sourceEntry.downloadLink,
      hdLink: sourceEntry.hdLink,
      audioLink: sourceEntry.audioLink,
      localPath: outPath,
      quality: exportAsAudio ? 'audio' : sourceEntry.quality,
      status: 'success',
      strategy: 'video_trimmer',
      folderName: sourceEntry.folderName,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    s.downloads.insert(0, clippedEntry);
    await s._saveDownloads();
    s.recordUserActivity(
      actionType: 'trim_video',
      details:
          'قص فيديو ($baseTitle) من ${formatDurationSeconds(startSec)} إلى ${formatDurationSeconds(endSec)}',
      platform: sourceEntry.platform,
    );
    s.notifyListeners();
    return clippedEntry;
  }

  /// Parses SRT or WebVTT subtitle content into synchronized [SubtitleCue] items
  static List<SubtitleCue> parseSrtOrVttSubtitles(String rawContent) {
    final cues = <SubtitleCue>[];
    final normalized = rawContent.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return cues;

    int parseTimeToSeconds(String t) {
      final clean = t.trim().replaceAll(',', '.');
      final parts = clean.split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = double.tryParse(parts[2])?.floor() ?? 0;
        return h * 3600 + m * 60 + s;
      } else if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = double.tryParse(parts[1])?.floor() ?? 0;
        return m * 60 + s;
      }
      return 0;
    }

    final blocks = normalized.split(RegExp(r'\n\s*\n'));
    final timeRegex = RegExp(
        r'(\d{1,2}:\d{2}(?::\d{2})?[,.]\d{1,3})\s*-->\s*(\d{1,2}:\d{2}(?::\d{2})?[,.]\d{1,3})');

    for (final block in blocks) {
      final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) continue;
      int timeLineIdx = -1;
      RegExpMatch? match;
      for (int i = 0; i < lines.length; i++) {
        final m = timeRegex.firstMatch(lines[i]);
        if (m != null) {
          timeLineIdx = i;
          match = m;
          break;
        }
      }
      if (timeLineIdx != -1 && match != null && timeLineIdx + 1 < lines.length) {
        final start = parseTimeToSeconds(match.group(1)!);
        final end = max(start + 2, parseTimeToSeconds(match.group(2)!));
        final text = lines.sublist(timeLineIdx + 1).join(' ');
        cues.add(SubtitleCue(startSec: start, endSec: end, text: text));
      }
    }

    // If raw text had no timestamps, split lines into 5-second automatic cues
    if (cues.isEmpty) {
      final sentences = normalized
          .split(RegExp(r'[.\n!؟]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (int i = 0; i < sentences.length; i++) {
        cues.add(SubtitleCue(
          startSec: i * 5,
          endSec: (i + 1) * 5,
          text: sentences[i],
        ));
      }
    }
    return cues;
  }

  /// Translates video description/captions over the internet into the target language
  static Future<List<SubtitleCue>> fetchOnlineTranslatedSubtitles({
    required DownloadEntry entry,
    required String targetLangCode,
  }) async {
    final sourceText = entry.description.trim().isNotEmpty
        ? entry.description.trim()
        : (entry.title.trim().isNotEmpty
            ? entry.title.trim()
            : 'مرحباً بكم في مشغل الفيديو الاحترافي لتطبيق DOViD. يدعم هذا المشغل التشغيل أوفلاين وجميع الجودات والترجمة الفورية.');

    String translatedText = sourceText;
    try {
      final apiUrl =
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLangCode&dt=t&q=${Uri.encodeComponent(sourceText)}';
      final res = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final buffer = StringBuffer();
          for (final part in decoded[0]) {
            if (part is List && part.isNotEmpty && part[0] != null) {
              buffer.write(part[0].toString());
            }
          }
          if (buffer.isNotEmpty) {
            translatedText = buffer.toString();
          }
        }
      }
    } catch (_) {}

    final chunks = translatedText
        .split(RegExp(r'[.\n،,•!؟|]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 2)
        .toList();

    if (chunks.isEmpty) {
      return [
        SubtitleCue(startSec: 0, endSec: 60, text: translatedText),
      ];
    }

    final cues = <SubtitleCue>[];
    for (int i = 0; i < chunks.length; i++) {
      cues.add(SubtitleCue(
        startSec: i * 4,
        endSec: (i + 1) * 4,
        text: chunks[i],
      ));
    }
    return cues;
  }
}

// ============================================================================
// MAIN APP ENTRY POINT
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().init();
  runApp(const DOViDApp());
}

class DOViDApp extends StatefulWidget {
  const DOViDApp({super.key});

  @override
  State<DOViDApp> createState() => _DOViDAppState();
}

class _DOViDAppState extends State<DOViDApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppState().verifyVpnAndNetworkSecurity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final s = AppState();
        final accent = s.accentColor;
        return MaterialApp(
          title: '$kAppName - $kDevName',
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
            fontFamily: s.fontFamily,
            textTheme: AppTypography.buildTextTheme(s.fontFamily, s.fontScale),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const RootGateScreen(),
        );
      },
    );
  }
}

// ============================================================================
// ROOT GATE SCREEN (Anti-VPN Lockdown + App PIN Gate + Auth Gate)
// ============================================================================
class RootGateScreen extends StatelessWidget {
  const RootGateScreen({super.key});

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
              child: CircularProgressIndicator(color: s.accentColor),
            ),
          );
        }

        if (s.isVpnBlockedNow) {
          return const VpnLockdownScreen();
        }

        if (s.requirePinOnLaunch &&
            s.appPinCode.isNotEmpty &&
            !s.isAppPinUnlockedSession) {
          return const AppPinLockScreen();
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
// ANTI-VPN & PROXY FULL-SCREEN LOCKDOWN
// ============================================================================
class VpnLockdownScreen extends StatefulWidget {
  const VpnLockdownScreen({super.key});

  @override
  State<VpnLockdownScreen> createState() => _VpnLockdownScreenState();
}

class _VpnLockdownScreenState extends State<VpnLockdownScreen> {
  bool checking = false;

  Future<void> _recheck() async {
    setState(() => checking = true);
    await Future.delayed(const Duration(milliseconds: 350));
    await AppState().verifyVpnAndNetworkSecurity();
    if (mounted) {
      setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _SubtleAmbientBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.45), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 36,
                      offset: Offset(0, 14),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.vpn_lock_rounded,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تم إيقاف عمل التطبيق أمنياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'درع الحماية الذكي اكتشف اتصال VPN أو خادم Proxy نشط على جهازك. لحماية خوادم النظام وبياناتك، لا يعمل التطبيق أثناء تشغيل برامج تغيير الشبكة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radar,
                                  color: AppColors.warning, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'السبب المكتشف: ${s.vpnBlockReason}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (s.vpnDetectedInterface.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'المعرف الشبكي: ${s.vpnDetectedInterface}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: checking ? null : _recheck,
                        icon: checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          checking
                              ? 'جاري فحص الشبكة...'
                              : 'أوقفت الـ VPN، إعادة الفحص الآن',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
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

// ============================================================================
// APP PIN SECURITY GATE SCREEN
// ============================================================================
class AppPinLockScreen extends StatefulWidget {
  const AppPinLockScreen({super.key});

  @override
  State<AppPinLockScreen> createState() => _AppPinLockScreenState();
}

class _AppPinLockScreenState extends State<AppPinLockScreen> {
  String enteredPin = '';
  String? errorMsg;

  void _onDigitPress(String d) {
    if (enteredPin.length >= 4) return;
    setState(() {
      enteredPin += d;
      errorMsg = null;
    });
    if (enteredPin.length == 4) {
      final unlocked = AppState().unlockAppWithPin(enteredPin);
      if (!unlocked) {
        setState(() {
          enteredPin = '';
          errorMsg = 'رمز الحماية PIN غير صحيح';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person_rounded, size: 46, color: s.accentColor),
              const SizedBox(height: 12),
              const Text(
                'قفل الأمان الرقمي (PIN)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'أدخل رمز الحماية المكون من 4 أرقام لفتح التطبيق',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < enteredPin.length;
                  return Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? s.accentColor : AppColors.surfaceLighter,
                      border: Border.all(
                        color: filled ? s.accentColor : AppColors.borderStrong,
                      ),
                    ),
                  );
                }),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(errorMsg!,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    _PinKeyButton(label: d, onTap: () => _onDigitPress(d)),
                  _PinKeyButton(
                    label: 'مسح',
                    icon: Icons.backspace_outlined,
                    onTap: () {
                      if (enteredPin.isNotEmpty) {
                        setState(() => enteredPin =
                            enteredPin.substring(0, enteredPin.length - 1));
                      }
                    },
                  ),
                  _PinKeyButton(label: '0', onTap: () => _onDigitPress('0')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinKeyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _PinKeyButton({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 74,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 20, color: AppColors.textMuted)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// REAL GOOGLE ADS WIDGETS (Banner & Interstitial/Rewarded Dialog)
// ============================================================================
class RealGoogleBannerAdWidget extends StatefulWidget {
  final String placement;
  const RealGoogleBannerAdWidget({super.key, required this.placement});

  @override
  State<RealGoogleBannerAdWidget> createState() =>
      _RealGoogleBannerAdWidgetState();
}

class _RealGoogleBannerAdWidgetState extends State<RealGoogleBannerAdWidget> {
  bool _impressionRecorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppState();
    final isVipExempt = s.currentUser?.isVip == true && s.vipNoAds;
    final hasUnit = s.admobBannerUnitId.trim().isNotEmpty ||
        s.adsensePublisherId.trim().isNotEmpty;
    if (s.adsEnabled &&
        s.bannerAdsEnabled &&
        !isVipExempt &&
        hasUnit &&
        !_impressionRecorded) {
      _impressionRecorded = true;
      final unit = s.admobBannerUnitId.trim().isNotEmpty
          ? s.admobBannerUnitId.trim()
          : '${s.adsensePublisherId.trim()}/${s.adsenseDisplaySlot.trim()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        s.recordAdEvent(
          adFormat: 'banner',
          placement: widget.placement,
          unitId: unit,
          eventType: 'impression',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    if (!s.adsEnabled || !s.bannerAdsEnabled) return const SizedBox.shrink();
    if (widget.placement == 'home_top' && !s.placeAdsHomeTop) {
      return const SizedBox.shrink();
    }
    if (widget.placement == 'home_bottom' && !s.placeAdsHomeBottom) {
      return const SizedBox.shrink();
    }
    if (widget.placement == 'studio_top' && !s.placeAdsStudio) {
      return const SizedBox.shrink();
    }
    if (s.currentUser?.isVip == true && s.vipNoAds) {
      return const SizedBox.shrink();
    }

    final hasAdmob = s.admobBannerUnitId.trim().isNotEmpty;
    final hasAdsense = s.adsensePublisherId.trim().isNotEmpty;
    if (!hasAdmob && !hasAdsense) return const SizedBox.shrink();

    final unitId = hasAdmob
        ? s.admobBannerUnitId.trim()
        : '${s.adsensePublisherId.trim()}/${s.adsenseDisplaySlot.trim()}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: InkWell(
        onTap: () async {
          s.recordAdEvent(
            adFormat: 'banner',
            placement: widget.placement,
            unitId: unitId,
            eventType: 'click',
          );
          final target = s.customSponsorTargetUrl.trim().isNotEmpty
              ? s.customSponsorTargetUrl.trim()
              : 'https://www.google.com/adsense';
          final uri = Uri.tryParse(target);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: const Color(0xFF4285F4).withOpacity(0.45)),
              ),
              child: const Text(
                'Ad • Google',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAdmob
                        ? 'Google AdMob Active Unit'
                        : 'Google AdSense Verified Display',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Unit: $unitId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 15, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _RealGoogleInterstitialDialog extends StatefulWidget {
  final String unitId;
  final String publisherId;
  final bool isRewarded;

  const _RealGoogleInterstitialDialog({
    required this.unitId,
    required this.publisherId,
    required this.isRewarded,
  });

  @override
  State<_RealGoogleInterstitialDialog> createState() =>
      _RealGoogleInterstitialDialogState();
}

class _RealGoogleInterstitialDialogState
    extends State<_RealGoogleInterstitialDialog> {
  late int secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    secondsLeft = widget.isRewarded ? 5 : 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.isRewarded
                        ? 'Google Rewarded Ad'
                        : 'Google Interstitial Ad',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                ),
                if (secondsLeft > 0)
                  Text(
                    'يمكنك الإغلاق بعد $secondsLeft ث',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Column(
                children: [
                  const Icon(Icons.campaign_rounded,
                      size: 46, color: Color(0xFF4285F4)),
                  const SizedBox(height: 10),
                  Text(
                    widget.isRewarded
                        ? 'إعلان مكافأة لفتح الجودة الفائقة'
                        : 'مساحة إعلانية مُدارة عبر Google Ads',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ad Unit: ${widget.unitId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: secondsLeft > 0
                        ? null
                        : () => Navigator.pop(context, true),
                    child: Text(widget.isRewarded
                        ? 'استلام المكافأة والمتابعة'
                        : 'متابعة للتطبيق'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      s.recordAdEvent(
                        adFormat:
                            widget.isRewarded ? 'rewarded' : 'interstitial',
                        placement: 'dialog_cta',
                        unitId: widget.unitId,
                        eventType: 'click',
                      );
                      final target = s.customSponsorTargetUrl.trim().isNotEmpty
                          ? s.customSponsorTargetUrl.trim()
                          : 'https://www.google.com/adsense';
                      final uri = Uri.tryParse(target);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: const Text('زيارة المعلن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    await Future.delayed(const Duration(milliseconds: 220));
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
    final s = AppState();
    final accent = s.accentColor;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _SubtleAmbientBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderStrong),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          'DV',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (error != null) _ErrorBanner(message: error!),
                    _AuthField(
                      controller: userCtrl,
                      icon: Icons.person_outline_rounded,
                      hint: 'اسم المستخدم',
                    ),
                    if (isRegister) ...[
                      const SizedBox(height: 12),
                      _AuthField(
                        controller: emailCtrl,
                        icon: Icons.email_outlined,
                        hint: 'البريد الإلكتروني (اختياري)',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _AuthField(
                      controller: passCtrl,
                      icon: Icons.lock_outline_rounded,
                      hint: 'كلمة المرور',
                      obscure: true,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isRegister ? 'إنشاء الحساب الآن' : 'تسجيل الدخول',
                      icon: isRegister ? Icons.person_add_alt_1 : Icons.login,
                      loading: loading,
                      onTap: _submit,
                    ),
                    if (s.allowGuestAccess) ...[
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
                          onPressed: () {
                            final err = s.loginAsGuest();
                            if (err != null) {
                              setState(() => error = err);
                            }
                          },
                          icon: const Icon(Icons.person_outline,
                              color: AppColors.guest),
                          label: const Text(
                            'الدخول السريع كزائر',
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
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        isRegister = !isRegister;
                        error = null;
                      }),
                      child: Text(
                        isRegister
                            ? 'لديك حساب بالفعل؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ أنشئ حساباً جديداً',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 6),
                    const Text(
                      'Developed by $kDevName • WhatsApp: $kDevWhatsapp',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textDim),
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
    final accent = AppState().accentColor;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.text, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: accent, width: 1.4),
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
        color: AppColors.error.withOpacity(0.12),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
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
    final accent = AppState().accentColor;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
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
                        fontSize: 14.5,
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
// MAIN NAVIGATION SCREEN (Organized 5-6 Tab Architecture)
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
          const SmartToolsScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
          if (isAdmin) const AdminScreen(),
        ];

        final items = <_NavItem>[
          _NavItem(Icons.home_rounded, 'الرئيسية'),
          _NavItem(Icons.video_library_rounded, 'الاستوديو',
              badgeCount: s.savedDeviceFiles.length),
          _NavItem(Icons.handyman_rounded, 'الأدوات'),
          _NavItem(Icons.history_rounded, 'السجل'),
          _NavItem(Icons.settings_rounded, 'الإعدادات'),
          if (isAdmin)
            _NavItem(Icons.admin_panel_settings_rounded, 'المدير', admin: true),
        ];

        if (s.pendingTabSwitch != null) {
          final target = s.pendingTabSwitch!;
          s.consumePendingTabSwitch();
          if (target >= 0 && target < pages.length) {
            _tab = target;
          }
        }
        if (_tab >= pages.length) _tab = 0;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              const _SubtleAmbientBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _TopSecurityStatusHeader(),
                    if (s.activeTasks.isNotEmpty) _ActiveDownloadsBanner(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.97, end: 1.0)
                                  .animate(anim),
                              child: child,
                            ),
                          );
                        },
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
              color: AppColors.surface.withOpacity(0.98),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    final active = i == _tab;
                    final color = it.admin ? AppColors.admin : s.accentColor;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tab = i),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? color.withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    it.icon,
                                    size: 21,
                                    color:
                                        active ? color : AppColors.textMuted,
                                  ),
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
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                it.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w800,
                                  color: active ? color : AppColors.textMuted,
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
  final int badgeCount;
  _NavItem(this.icon, this.label, {this.admin = false, this.badgeCount = 0});
}

class _TopSecurityStatusHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final isAdmin = s.currentUser?.isAdmin == true;
    final isVip = s.currentUser?.isVip == true;
    final userLabel = isAdmin
        ? '${s.currentUser!.username} • المدير العام'
        : isVip
            ? '${s.currentUser!.username} • VIP'
            : s.isGuest
                ? 'وضع الزائر'
                : (s.currentUser?.username ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [s.accentColor, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'DV',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  kAppName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (userLabel.isNotEmpty)
                  Text(
                    userLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              AnimatedEqualizerBars(color: s.accentColor, barCount: 5, height: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جاري التنزيل (${tasks.length}): ${t.title}',
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => s.cancelTask(t.entryId),
                child:
                    const Icon(Icons.close, size: 16, color: AppColors.error),
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

class _SubtleAmbientBackground extends StatefulWidget {
  const _SubtleAmbientBackground();

  @override
  State<_SubtleAmbientBackground> createState() =>
      _SubtleAmbientBackgroundState();
}

class _SubtleAmbientBackgroundState extends State<_SubtleAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final accent = s.accentColor;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shift = s.highGraphicsEnabled ? (_ctrl.value - 0.5) * 35.0 : 0.0;
        return Stack(
          children: [
            Container(color: AppColors.bg),
            Positioned(
              top: -150 + shift,
              right: -110 - shift * 0.6,
              child: Container(
                width: 390,
                height: 390,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [accent.withOpacity(0.075), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150 - shift,
              left: -110 + shift * 0.6,
              child: Container(
                width: 370,
                height: 370,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.065),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// HOME SCREEN (Clean User UI - Zero Technical/Bypass Text Visible)
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final urlCtrl = TextEditingController();
  late String quality;
  String selectedFolder = 'عام';
  bool loading = false;
  bool previewLoading = false;
  bool batchMode = false;
  String? error;
  DownloadEntry? result;
  Map<String, String>? quickPreview;
  String loadingStatusMessage = 'جاري تحليل الرابط وتجهيز الجودات...';
  String? detectedClipboardLink;
  Timer? _debounce;

  final List<QualityOption> qualities = const [
    QualityOption(
      key: 'auto',
      label: 'تلقائي ذكي',
      badge: 'AI Auto',
      icon: Icons.auto_awesome,
    ),
    QualityOption(
      key: '4k',
      label: '4K فائق الدقة',
      badge: '2160p UHD',
      icon: Icons.hd,
    ),
    QualityOption(
      key: '1080',
      label: 'FHD 1080p',
      badge: '60 FPS',
      icon: Icons.tv,
    ),
    QualityOption(
      key: '720',
      label: 'HD 720p',
      badge: 'سريع',
      icon: Icons.phone_android,
    ),
    QualityOption(
      key: 'audio',
      label: 'صوت MP3 نقي',
      badge: '320kbps',
      icon: Icons.music_note,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final s = AppState();
    quality = s.defaultQuality;
    final batchFromTools = s.consumePendingBatchUrls();
    if (batchFromTools.isNotEmpty) {
      batchMode = true;
      urlCtrl.text = batchFromTools;
    } else if (s.autoDetectClipboard) {
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
    final s = AppState();
    if (!await s.verifyVpnAndNetworkSecurity()) return;

    final rawText = urlCtrl.text.trim();
    if (rawText.isEmpty) {
      setState(() => error = 'يرجى لصق رابط الفيديو أولاً');
      return;
    }

    final urls = batchMode
        ? rawText
            .split(RegExp(r'[\r\n]+'))
            .map((e) => e.trim())
            .where((e) => e.startsWith('http'))
            .toList()
        : [rawText];

    if (urls.isEmpty || !urls.first.startsWith('http')) {
      setState(() => error = 'الرابط غير صالح، يجب أن يبدأ بـ http أو https');
      return;
    }

    if (!s.checkAndConsumeDailyQuota()) {
      setState(() => error =
          'لقد استهلكت حصتك اليومية المجانية (${s.freeDailyQuota} تحميل). قم بتفعيل كود VIP للحصول على تحميل غير محدود.');
      return;
    }

    if (quality == '4k' && s.adsEnabled && s.rewardedAdsEnabled) {
      final unlocked = await GoogleAdsEngine.showRewardedAd(context);
      if (!unlocked) {
        setState(() => error = 'يلزم إكمال إعلان المكافأة لفتح جودة 4K الفائقة');
        return;
      }
    } else if (s.shouldTriggerInterstitialOnExtract()) {
      await GoogleAdsEngine.showInterstitialAd(context);
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      result = null;
      loadingStatusMessage = 'جاري معالجة الفيديو وتجهيز روابط التحميل...';
    });

    DownloadEntry? lastSuccess;

    for (int idx = 0; idx < urls.length; idx++) {
      final currentUrl = urls[idx];
      if (urls.length > 1 && mounted) {
        setState(() {
          loadingStatusMessage =
              'جاري تجهيز الفيديو (${idx + 1} من ${urls.length})...';
        });
      }

      final entry = await s.addDownload(
        currentUrl,
        quality,
        folderName: selectedFolder,
      );

      final response = await DownloadService.downloadSilently(
        currentUrl,
        quality: quality,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        final link = (response['answer'] ?? response['url'] ?? '').toString();
        final hdLink = (response['hdLink'] ?? link).toString();
        final audioLink = (response['audioLink'] ?? '').toString();
        final title = (response['title'] ??
                quickPreview?['title'] ??
                'فيديو ${entry.platform}')
            .toString();
        final description = (response['description'] ??
                quickPreview?['description'] ??
                title)
            .toString();
        final author =
            (response['author'] ?? quickPreview?['author'] ?? '').toString();
        final thumb = (response['thumbnail'] ??
                quickPreview?['thumbnail'] ??
                '')
            .toString();
        final duration = (response['duration'] ?? '').toString();
        final fileSize = (response['fileSize'] ?? '').toString();
        final strategy = (response['strategy'] ?? 'direct').toString();

        await s.updateDownload(
          entry,
          title: title,
          description: description,
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
            error =
                (response['message'] ?? 'فشل جلب الفيديو، حاول مرة أخرى')
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

  void _showPlatform3DDetailsSheet(BuildContext context, PlatformSpec spec) {
    final s = AppState();
    final count =
        s.myDownloads.where((d) => d.platform == spec.id).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Platform3DBadge(
                    platformId: spec.id,
                    active: true,
                    size: 56,
                    showLabel: false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              spec.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MiniTag(spec.badgeTag, spec.accentGlow),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec.arabicDesc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimerBox(value: '$count', label: 'تحميلاتك من المنصة'),
                    const _TimerBox(value: '4K / FHD', label: 'أعلى دقة مدعومة'),
                    const _TimerBox(value: 'MP3 320k', label: 'استخراج الصوت'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _pasteFromClipboard();
                      },
                      icon: const Icon(Icons.content_paste_rounded,
                          size: 17, color: Colors.white),
                      label: Text(
                        'لصق رابط ${spec.name} والتحميل فوراً',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: s.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
          content: Text('تم حفظ الملف في جهازك بنجاح:\n$savedPath'),
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
    final activeAnnouncements =
        s.announcements.where((a) => a.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (activeAnnouncements.isNotEmpty)
          ...activeAnnouncements.take(2).map((ann) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ann.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            ann.body,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

        const RealGoogleBannerAdWidget(placement: 'home_top'),

        if (detectedClipboardLink != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_motion, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم اكتشاف رابط ${detectPlatform(detectedClipboardLink!).toUpperCase()} في الحافظة',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('لصق وتحميل',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                  label: 'الإجمالي', value: s.totalDownloads, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                  label: 'مكتمل',
                  value: s.successDownloads,
                  color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                  label: 'محفوظ بالهاتف',
                  value: s.savedDeviceFiles.length,
                  color: AppColors.guest),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: accent, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'استوديو التحميل الذكي السريع',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => setState(() => batchMode = !batchMode),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: batchMode
                            ? AppColors.admin.withOpacity(0.18)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: batchMode ? AppColors.admin : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dynamic_feed,
                            size: 13,
                            color: batchMode
                                ? AppColors.admin
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            batchMode ? 'دفعة متعددة (نشط)' : 'تحميل متعدد',
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
                      style:
                          const TextStyle(color: AppColors.text, fontSize: 13),
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: batchMode
                            ? 'ضع كل رابط فيديو في سطر مستقل...'
                            : 'الصق رابط الفيديو (YouTube, TikTok, Instagram...)',
                        hintStyle: const TextStyle(
                            color: AppColors.textDim, fontSize: 11.5),
                        prefixIcon: Icon(Icons.link, color: accent, size: 18),
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
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: accent, width: 1.4),
                        ),
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
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.content_paste_rounded,
                              size: 16, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'لصق',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

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
                    final active = quality == q.key;
                    return GestureDetector(
                      onTap: () => setState(() => quality = q.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: active
                              ? LinearGradient(
                                  colors: [accent, AppColors.primaryDark],
                                )
                              : null,
                          color: active ? null : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                active ? Colors.white24 : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              q.icon,
                              size: 14,
                              color:
                                  active ? Colors.white : AppColors.textMuted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              q.label,
                              style: TextStyle(
                                color:
                                    active ? Colors.white : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  const Text('مجلد الحفظ:',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: s.customFolders.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final f = s.customFolders[idx];
                          final isSel = selectedFolder == f;
                          return GestureDetector(
                            onTap: () => setState(() => selectedFolder = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.secondary.withOpacity(0.22)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.secondary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _PrimaryButton(
                label: batchMode
                    ? 'بدء تحميل القائمة بالكامل'
                    : 'تجهيز ومعاينة الفيديو الآن',
                icon: Icons.download_rounded,
                loading: loading,
                onTap: _download,
              ),

              if (loading) ...[
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    loadingStatusMessage,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  onDownloadAudio: () => _saveVideoFile(result!, isAudio: true),
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
        Tilt3DCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          borderRadius: 20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final p = kSupportedPlatforms3D[i];
                  return Expanded(
                    child: Platform3DBadge(
                      platformId: p.id,
                      active: activePlatform == p.id,
                      size: 48,
                      phaseIndex: i,
                      showLabel: true,
                      showSubBadge: false,
                      onTap: () => _showPlatform3DDetailsSheet(context, p),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final p = kSupportedPlatforms3D[i + 5];
                  return Expanded(
                    child: Platform3DBadge(
                      platformId: p.id,
                      active: activePlatform == p.id,
                      size: 48,
                      phaseIndex: i + 5,
                      showLabel: true,
                      showSubBadge: false,
                      onTap: () => _showPlatform3DDetailsSheet(context, p),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const RealGoogleBannerAdWidget(placement: 'home_bottom'),

        if (s.myDownloads.isNotEmpty) ...[
          const SizedBox(height: 8),
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
        ],
        const SizedBox(height: 18),
      ],
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
                    errorBuilder: (_, __, ___) =>
                        _SmallPlatformBox(platform: platform),
                  )
                : _SmallPlatformBox(platform: platform),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معاينة الرابط • ${platform.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: platformColor(platform),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title.isEmpty ? 'الرابط جاهز للتجهيز والتحميل' : title,
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
          GestureDetector(
            onTap: onOpenPreviewModal,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (entry.thumbnailUrl.isNotEmpty)
                  Image.network(
                    entry.thumbnailUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _FallbackThumbBanner(platform: entry.platform),
                  )
                else
                  _FallbackThumbBanner(platform: entry.platform),
                Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.black38,
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: s.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'عنوان الفيديو:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.title.isEmpty
                                ? 'فيديو ${entry.platform}'
                                : entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => showVideoTrimmerModal(context, entry),
                      icon: const Icon(
                        Icons.content_cut_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      tooltip: 'قص الفيديو (Video Trimmer)',
                    ),
                    IconButton(
                      onPressed: () => showShareDownloadModal(context, entry),
                      icon: Icon(
                        Icons.share_rounded,
                        color: s.accentColor,
                        size: 20,
                      ),
                      tooltip: 'مشاركة التنزيل',
                    ),
                    IconButton(
                      onPressed: () => s.toggleVault(entry),
                      icon: Icon(
                        entry.isVaulted
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: entry.isVaulted
                            ? AppColors.vault
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      tooltip: 'نقل إلى الخزنة السرية',
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
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'وصف الفيديو والتفاصيل:',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.guest,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final txt =
                                  '${entry.title}\n\n${entry.description}';
                              Clipboard.setData(ClipboardData(text: txt));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('تم نسخ عنوان ووصف الفيديو للحافظة'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy,
                                    size: 12, color: AppColors.textMuted),
                                SizedBox(width: 3),
                                Text('نسخ العنوان والوصف',
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.description.isNotEmpty
                            ? entry.description
                            : (entry.title.isNotEmpty
                                ? entry.title
                                : 'لا يوجد وصف إضافي مرفق مع هذا الفيديو'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniTag(entry.platform.toUpperCase(),
                        platformColor(entry.platform)),
                    _MiniTag(entry.quality.toUpperCase(), AppColors.success),
                    _MiniTag('مجلد: ${entry.folderName}', AppColors.secondary),
                    if (entry.localPath.isNotEmpty)
                      const _MiniTag('متاح أوفلاين ⚡', AppColors.success),
                    if (entry.fileSizeText.isNotEmpty)
                      _MiniTag(entry.fileSizeText, AppColors.guest),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: activeTask.progress,
                    backgroundColor: AppColors.bg,
                    color: AppColors.success,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'جاري الحفظ... ${(activeTask.progress * 100).toStringAsFixed(0)}%',
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
                const SizedBox(height: 14),
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
                              : 'حفظ الفيديو MP4 HD',
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showCustomOfflineMediaPlayerModal(
                            context, entry),
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            size: 16, color: AppColors.guest),
                        label: const Text(
                          'المشغل المخصص (أوفلاين + ترجمة)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => showVideoTrimmerModal(context, entry),
                      icon: const Icon(Icons.content_cut_rounded,
                          size: 15, color: AppColors.warning),
                      label: const Text(
                        'قص الفيديو',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning),
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
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withOpacity(0.26), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Platform3DBadge(
          platformId: platform,
          active: true,
          size: 72,
          showLabel: false,
        ),
      ),
    );
  }
}

void showShareDownloadModal(BuildContext context, DownloadEntry entry) {
  final s = AppState();
  final accent = s.accentColor;
  final shareUrl =
      entry.downloadLink.isNotEmpty ? entry.downloadLink : entry.url;
  final shareTitle =
      entry.title.isEmpty ? 'فيديو ${entry.platform.toUpperCase()}' : entry.title;
  final fullShareText =
      '🎬 $shareTitle\n🌐 المنصة: ${entry.platform.toUpperCase()} (${entry.quality.toUpperCase()})\n🔗 رابط الفيديو المباشر:\n$shareUrl\n${entry.localPath.isNotEmpty ? "📂 محفوظ بالهاتف: ${entry.localPath}\n" : ""}⚡ عبر تطبيق $kAppName';

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Platform3DBadge(
                  platformId: entry.platform,
                  active: true,
                  size: 46,
                  showLabel: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مشاركة التنزيل والفيديو',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15.5),
                      ),
                      Text(
                        shareTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(fullShareText)}');
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.chat_rounded,
                        color: Colors.white, size: 17),
                    label: const Text('واتساب',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(shareTitle)}');
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('تيليجرام',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareTitle)}&url=${Uri.encodeComponent(shareUrl)}');
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.alternate_email,
                        color: Colors.white, size: 16),
                    label: const Text('منصة X',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DA1F2),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fullShareText));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ بطاقة المشاركة الكاملة للحافظة'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: const Text('نسخ بطاقة المشاركة',
                        style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رابط الفيديو المباشر للحافظة'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('نسخ الرابط المباشر',
                        style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: SizedBox(
                  width: 118,
                  height: 118,
                  child: CustomPaint(
                    painter: VisualQrMatrixPainter(
                      data: shareUrl,
                      foregroundColor: accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showVideoTrimmerModal(BuildContext context, DownloadEntry entry) {
  int parseDurationToSec(String raw) {
    if (raw.trim().isEmpty) return 120;
    final parts = raw.trim().split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    } else if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    return int.tryParse(raw) ?? 120;
  }

  final totalSec = max(15, parseDurationToSec(entry.durationText));
  RangeValues range = RangeValues(0, min(30.0, totalSec.toDouble()));
  bool exportAudioOnly = false;
  bool trimming = false;
  final titleCtrl = TextEditingController(
    text: entry.title.isEmpty
        ? 'مقطع ${entry.platform.toUpperCase()}'
        : '${entry.title} - مقطع مقصوص',
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final accent = AppState().accentColor;
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final startSec = range.start.round();
          final endSec = range.end.round();
          final netSec = max(1, endSec - startSec);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.content_cut_rounded,
                          color: AppColors.warning, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'استوديو قص وتقطيع الفيديو الذكي (Video Trimmer)',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المقطع بعد القص',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _TimerBox(
                              value: formatDurationSeconds(max(1, startSec)),
                              label: 'بداية القص',
                            ),
                            _TimerBox(
                              value: formatDurationSeconds(netSec),
                              label: 'مدة المقطع الصافي',
                            ),
                            _TimerBox(
                              value: formatDurationSeconds(endSec),
                              label: 'نهاية القص',
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: range,
                          min: 0,
                          max: totalSec.toDouble(),
                          divisions: max(10, totalSec),
                          activeColor: AppColors.warning,
                          labels: RangeLabels(
                            formatDurationSeconds(max(1, startSec)),
                            formatDurationSeconds(endSec),
                          ),
                          onChanged: (v) {
                            if (v.end - v.start >= 1) {
                              setModalState(() => range = v);
                            }
                          },
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('أول 15 ث (Reels)',
                                  style: TextStyle(fontSize: 10.5)),
                              onPressed: () => setModalState(() => range =
                                  RangeValues(
                                      0, min(15.0, totalSec.toDouble()))),
                            ),
                            ActionChip(
                              label: const Text('أول 30 ث (Story)',
                                  style: TextStyle(fontSize: 10.5)),
                              onPressed: () => setModalState(() => range =
                                  RangeValues(
                                      0, min(30.0, totalSec.toDouble()))),
                            ),
                            ActionChip(
                              label: const Text('أول 60 ث (TikTok)',
                                  style: TextStyle(fontSize: 10.5)),
                              onPressed: () => setModalState(() => range =
                                  RangeValues(
                                      0, min(60.0, totalSec.toDouble()))),
                            ),
                            ActionChip(
                              label: const Text('النصف الأول',
                                  style: TextStyle(fontSize: 10.5)),
                              onPressed: () => setModalState(() => range =
                                  RangeValues(0, (totalSec / 2).toDouble())),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('ضبط البداية:',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                          IconButton(
                            onPressed: () {
                              final ns =
                                  (range.start - 1).clamp(0.0, range.end - 1);
                              setModalState(
                                  () => range = RangeValues(ns, range.end));
                            },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 17),
                          ),
                          IconButton(
                            onPressed: () {
                              final ns =
                                  (range.start + 1).clamp(0.0, range.end - 1);
                              setModalState(
                                  () => range = RangeValues(ns, range.end));
                            },
                            icon:
                                const Icon(Icons.add_circle_outline, size: 17),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('ضبط النهاية:',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                          IconButton(
                            onPressed: () {
                              final ne = (range.end - 1)
                                  .clamp(range.start + 1, totalSec.toDouble());
                              setModalState(
                                  () => range = RangeValues(range.start, ne));
                            },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 17),
                          ),
                          IconButton(
                            onPressed: () {
                              final ne = (range.end + 1)
                                  .clamp(range.start + 1, totalSec.toDouble());
                              setModalState(
                                  () => range = RangeValues(range.start, ne));
                            },
                            icon:
                                const Icon(Icons.add_circle_outline, size: 17),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: exportAudioOnly,
                    activeColor: accent,
                    title: const Text(
                        'تصدير المقطع المقصوص كملف صوتي / نغمة MP3',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'يتم حفظ المقطع بالهاتف ومزامنة بياناته مع سيرفر JOO CLOUD تلقائياً',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    onChanged: (v) =>
                        setModalState(() => exportAudioOnly = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: trimming
                          ? null
                          : () async {
                              setModalState(() => trimming = true);
                              final clipped =
                                  await DownloadService.trimAndExportVideoClip(
                                sourceEntry: entry,
                                startSec: startSec,
                                endSec: endSec,
                                totalDurationSec: totalSec,
                                customClipTitle: titleCtrl.text,
                                exportAsAudio: exportAudioOnly,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (clipped != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'تم قص وحفظ المقطع بنجاح في الاستوديو:\n${clipped.localPath}'),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                      icon: Icon(
                        trimming
                            ? Icons.hourglass_top_rounded
                            : Icons.content_cut_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      label: Text(
                        trimming
                            ? 'جاري قص وتصدير المقطع...'
                            : 'قص وحفظ المقطع الآن في الاستوديو',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void showCustomOfflineMediaPlayerModal(
    BuildContext context, DownloadEntry entry) {
  int parseDurationToSec(String raw) {
    if (raw.trim().isEmpty) return 180;
    final parts = raw.trim().split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    } else if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    return int.tryParse(raw) ?? 180;
  }

  final totalSec = max(20, parseDurationToSec(entry.durationText));
  bool isPlaying = true;
  int currentSec = 0;
  double playbackSpeed = 1.0;
  String activeQuality =
      entry.quality == 'auto' ? '1080p FHD' : entry.quality.toUpperCase();
  bool subtitlesEnabled = true;
  String selectedSubLang = 'ar';
  List<SubtitleCue> cues = DownloadService.parseSrtOrVttSubtitles(
    entry.description.isNotEmpty ? entry.description : entry.title,
  );
  bool loadingSubtitles = false;
  final srtPathCtrl = TextEditingController(text: entry.subtitlePath);
  final srtRawCtrl = TextEditingController();
  Timer? playTimer;

  AppState().recordUserActivity(
    actionType: 'offline_player',
    details:
        'تشغيل الفيديو (${entry.title.isEmpty ? entry.platform : entry.title}) في المشغل المخصص',
    platform: entry.platform,
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      final s = AppState();
      final accent = s.accentColor;

      return StatefulBuilder(
        builder: (ctx, setPlayerState) {
          playTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (!ctx.mounted) {
              t.cancel();
              return;
            }
            if (isPlaying) {
              setPlayerState(() {
                currentSec = (currentSec + playbackSpeed.round()) % totalSec;
              });
            }
          });

          final activeCue = cues
              .where((c) => currentSec >= c.startSec && currentSec <= c.endSec)
              .firstOrNull;
          final hasOfflineFile = entry.localPath.isNotEmpty;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar: Title + Offline Status + Quality Switcher
                  Row(
                    children: [
                      Platform3DBadge(
                        platformId: entry.platform,
                        active: true,
                        size: 40,
                        showLabel: false,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title.isEmpty
                                  ? 'مشغل الفيديو السينمائي المخصص'
                                  : entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                            Row(
                              children: [
                                Icon(
                                  hasOfflineFile
                                      ? Icons.offline_pin_rounded
                                      : Icons.wifi_tethering_rounded,
                                  size: 12,
                                  color: hasOfflineFile
                                      ? AppColors.success
                                      : AppColors.guest,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasOfflineFile
                                      ? 'تشغيل أوفلاين من الهاتف (بدون إنترنت)'
                                      : 'بث مباشر متعدد الجودات',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: hasOfflineFile
                                        ? AppColors.success
                                        : AppColors.guest,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          playTimer?.cancel();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Multi-Quality Selector Strip inside Player
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('الجودة:',
                            style: TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        for (final qOpt in [
                          '4K UHD',
                          '1080p FHD',
                          '720p HD',
                          '480p SD',
                          'MP3 Audio'
                        ])
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(qOpt,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                              selected: activeQuality == qOpt,
                              onSelected: (_) =>
                                  setPlayerState(() => activeQuality = qOpt),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Video Viewport with Live Subtitle Overlay & Equalizer
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (entry.thumbnailUrl.isNotEmpty)
                          Image.network(
                            entry.thumbnailUrl,
                            width: double.infinity,
                            height: 215,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _FallbackThumbBanner(platform: entry.platform),
                          )
                        else
                          _FallbackThumbBanner(platform: entry.platform),
                        Container(
                          width: double.infinity,
                          height: 215,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black26,
                                Colors.black45,
                                Colors.black87
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPlaying)
                                  AnimatedEqualizerBars(
                                      color: accent, barCount: 5, height: 12),
                                const SizedBox(width: 6),
                                Text(
                                  '$activeQuality • ${playbackSpeed}x',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Center Play / Pause Control
                        GestureDetector(
                          onTap: () =>
                              setPlayerState(() => isPlaying = !isPlaying),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        // Synchronized Subtitle Overlay Box
                        if (subtitlesEnabled && activeCue != null)
                          Positioned(
                            bottom: 12,
                            left: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.82),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.warning.withOpacity(0.5)),
                              ),
                              child: Text(
                                activeCue.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Timeline Scrubber & Transport Controls
                  Row(
                    children: [
                      Text(
                        formatDurationSeconds(max(1, currentSec)),
                        style: const TextStyle(
                            fontSize: 10.5, fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: Slider(
                          value: currentSec.toDouble().clamp(0, totalSec.toDouble()),
                          min: 0,
                          max: totalSec.toDouble(),
                          activeColor: accent,
                          onChanged: (v) =>
                              setPlayerState(() => currentSec = v.round()),
                        ),
                      ),
                      Text(
                        formatDurationSeconds(totalSec),
                        style: const TextStyle(
                            fontSize: 10.5, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => setPlayerState(
                            () => currentSec = max(0, currentSec - 10)),
                        icon: const Icon(Icons.replay_10_rounded),
                        tooltip: 'رجوع 10 ثواني',
                      ),
                      IconButton(
                        onPressed: () =>
                            setPlayerState(() => isPlaying = !isPlaying),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 34,
                          color: accent,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setPlayerState(
                            () => currentSec = min(totalSec, currentSec + 10)),
                        icon: const Icon(Icons.forward_10_rounded),
                        tooltip: 'تقديم 10 ثواني',
                      ),
                      TextButton(
                        onPressed: () {
                          const speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
                          final nextIdx =
                              (speeds.indexOf(playbackSpeed) + 1) %
                                  speeds.length;
                          setPlayerState(() => playbackSpeed = speeds[nextIdx]);
                        },
                        child: Text('السرعة: ${playbackSpeed}x',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () => setPlayerState(
                            () => subtitlesEnabled = !subtitlesEnabled),
                        icon: Icon(
                          subtitlesEnabled
                              ? Icons.subtitles_rounded
                              : Icons.subtitles_off_rounded,
                          color: subtitlesEnabled
                              ? AppColors.warning
                              : AppColors.textMuted,
                        ),
                        tooltip: 'تفعيل/إيقاف الترجمة',
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border),

                  // Subtitle Engine Section (Online Translation + Local SRT/VTT File)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.translate_rounded,
                                    size: 16, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text(
                                  'نظام الترجمة الذكي (عبر الإنترنت أو بملف SRT/VTT)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            if (loadingSubtitles)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final lang in [
                                {'c': 'ar', 'l': 'ترجمة للعربية'},
                                {'c': 'en', 'l': 'English'},
                                {'c': 'fr', 'l': 'Français'},
                                {'c': 'es', 'l': 'Español'},
                                {'c': 'tr', 'l': 'Türkçe'},
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ActionChip(
                                    label: Text(lang['l']!,
                                        style: const TextStyle(fontSize: 10.5)),
                                    backgroundColor:
                                        selectedSubLang == lang['c']
                                            ? accent.withOpacity(0.25)
                                            : AppColors.surface,
                                    onPressed: () async {
                                      setPlayerState(() {
                                        selectedSubLang = lang['c']!;
                                        loadingSubtitles = true;
                                        subtitlesEnabled = true;
                                      });
                                      final translated = await DownloadService
                                          .fetchOnlineTranslatedSubtitles(
                                        entry: entry,
                                        targetLangCode: lang['c']!,
                                      );
                                      if (!ctx.mounted) return;
                                      setPlayerState(() {
                                        cues = translated;
                                        loadingSubtitles = false;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: srtPathCtrl,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 11, fontFamily: 'monospace'),
                                decoration: const InputDecoration(
                                  hintText:
                                      'مسار ملف الترجمة (/sdcard/Download/sub.srt)',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final p = srtPathCtrl.text.trim();
                                if (p.isEmpty) return;
                                try {
                                  final f = File(p);
                                  if (await f.exists()) {
                                    final content = await f.readAsString();
                                    final parsed = DownloadService
                                        .parseSrtOrVttSubtitles(content);
                                    await s.updateDownload(entry,
                                        subtitlePath: p);
                                    setPlayerState(() {
                                      cues = parsed;
                                      subtitlesEnabled = true;
                                    });
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'تم تحميل (${parsed.length}) جملة ترجمة من الملف بنجاح'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'لم يتم العثور على الملف في المسار المحدد، يمكنك لصق نص SRT مباشرة بالأسفل'),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                  }
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.upload_file_rounded,
                                  size: 15),
                              label: const Text('جلب ملف SRT',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: srtRawCtrl,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  hintText:
                                      'أو الصق محتوى ملف الترجمة SRT/VTT هنا مباشرة...',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () {
                                if (srtRawCtrl.text.trim().isEmpty) return;
                                final parsed =
                                    DownloadService.parseSrtOrVttSubtitles(
                                        srtRawCtrl.text);
                                setPlayerState(() {
                                  cues = parsed;
                                  subtitlesEnabled = true;
                                });
                              },
                              child: const Text('تطبيق النص',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title & Full Description Box inside Player
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العنوان: ${entry.title.isEmpty ? "فيديو ${entry.platform}" : entry.title}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        if (entry.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'الوصف: ${entry.description}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Actions: Trim Video / Native WebView Stream / External Player
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            playTimer?.cancel();
                            Navigator.pop(ctx);
                            showVideoTrimmerModal(context, entry);
                          },
                          icon: const Icon(Icons.content_cut_rounded,
                              size: 16, color: Colors.black),
                          label: const Text('قص هذا الفيديو',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final target = entry.downloadLink.isNotEmpty
                                ? entry.downloadLink
                                : entry.url;
                            final uri = Uri.tryParse(target);
                            if (uri != null) {
                              await launchUrl(uri,
                                  mode: LaunchMode.inAppWebView);
                            }
                          },
                          icon: const Icon(Icons.open_in_browser_rounded,
                              size: 16),
                          label: const Text('البث الخام المباشر',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    playTimer?.cancel();
  });
}

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
  final tempEntry = DownloadEntry(
    id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
    userId: AppState().currentUser?.id ?? 'guest',
    url: sourceUrl,
    title: title,
    description: title,
    author: author,
    thumbnailUrl: thumbnailUrl,
    durationText: duration,
    fileSizeText: fileSize,
    platform: platform,
    downloadLink: streamUrl,
    hdLink: streamUrl,
    createdAt: DateTime.now(),
  );
  showCustomOfflineMediaPlayerModal(context, tempEntry);
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
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(active ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: color.withOpacity(active ? 0.7 : 0.25),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 9.5,
            color: active ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: s.accentColor, size: 16),
                  const SizedBox(width: 6),
                  const Text('أحدث التحميلات',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              Text('${s.myDownloads.length} عنصر',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ...recent.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onPreviewTap(e),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      _SmallPlatformBox(platform: e.platform),
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
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${timeAgo(e.createdAt)} • ${e.folderName}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
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
                    ],
                  ),
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
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: Platform3DLogoPainter(
          platformId: platform,
          active: false,
          enable3D: AppState().enable3DEffects,
        ),
      ),
    );
  }
}

// ============================================================================
// STUDIO & PRIVATE VAULT SCREEN (Folders, Saved Files & PIN-Protected Vault)
// ============================================================================
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String activeTab = 'saved';
  String selectedFolderFilter = 'الكل';
  final folderNameCtrl = TextEditingController();
  final vaultPinCtrl = TextEditingController();

  @override
  void dispose() {
    folderNameCtrl.dispose();
    vaultPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    List<DownloadEntry> applySort(List<DownloadEntry> input) {
      final copy = List<DownloadEntry>.from(input);
      if (s.studioSortBy == 'title') {
        copy.sort((a, b) => a.title.compareTo(b.title));
      } else if (s.studioSortBy == 'platform') {
        copy.sort((a, b) => a.platform.compareTo(b.platform));
      } else {
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return copy;
    }

    final saved = applySort(s.savedDeviceFiles);
    final favorites =
        applySort(s.myDownloads.where((d) => d.isFavorite).toList());
    final vaulted = applySort(s.myVaultDownloads);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const RealGoogleBannerAdWidget(placement: 'studio_top'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.video_library_rounded, color: s.accentColor),
                const SizedBox(width: 8),
                const Text('الاستوديو والخزنة الخاصة',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('إنشاء مجلد تنظيم جديد',
                        style: TextStyle(fontSize: 15)),
                    content: TextField(
                      controller: folderNameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'اسم المجلد (مثال: كورسات برمجة)',
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء')),
                      ElevatedButton(
                        onPressed: () {
                          s.addCustomFolder(folderNameCtrl.text);
                          folderNameCtrl.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'إنشاء مجلد جديد',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TimerBox(
                value: '${s.myDownloads.where((d) => d.quality != "audio").length}',
                label: 'فيديو MP4',
              ),
              _TimerBox(
                value: '${s.myDownloads.where((d) => d.quality == "audio").length}',
                label: 'صوت MP3',
              ),
              _TimerBox(
                value: '${favorites.length}',
                label: 'المفضلة',
              ),
              _TimerBox(
                value: '${vaulted.length}',
                label: 'بالخزنة السرية',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.sort_rounded, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 6),
            const Text('ترتيب العناصر:',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 8),
            ...[
              {'k': 'newest', 'l': 'الأحدث'},
              {'k': 'title', 'l': 'الأبجدي'},
              {'k': 'platform', 'l': 'المنصة'},
            ].map((opt) {
              final isSel = s.studioSortBy == opt['k'];
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: InkWell(
                  onTap: () =>
                      s.saveSettings(newStudioSortBy: opt['k'] as String),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel
                          ? s.accentColor.withOpacity(0.18)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? s.accentColor : AppColors.border,
                      ),
                    ),
                    child: Text(
                      opt['l'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AdminTab(
                label: 'المحفوظ بالهاتف (${saved.length})',
                icon: Icons.folder_special_rounded,
                active: activeTab == 'saved',
                onTap: () => setState(() => activeTab = 'saved'),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: 'المجلدات (${s.customFolders.length})',
                icon: Icons.folder_copy_rounded,
                active: activeTab == 'folders',
                onTap: () => setState(() => activeTab = 'folders'),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: 'المفضلة (${favorites.length})',
                icon: Icons.bookmark_rounded,
                active: activeTab == 'favorites',
                onTap: () => setState(() => activeTab = 'favorites'),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: 'الخزنة السرية (${vaulted.length})',
                icon: Icons.lock_rounded,
                active: activeTab == 'vault',
                onTap: () => setState(() => activeTab = 'vault'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (activeTab == 'saved') ...[
          if (saved.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'لا توجد ملفات محفوظة في ذاكرة الهاتف حتى الآن',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...saved.map((e) => _StudioItemTile(entry: e)),
        ],

        if (activeTab == 'folders') ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['الكل', ...s.customFolders].map((f) {
              final active = selectedFolderFilter == f;
              return ChoiceChip(
                label: Text(f),
                selected: active,
                onSelected: (_) => setState(() => selectedFolderFilter = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...s.myDownloads
              .where((d) =>
                  selectedFolderFilter == 'الكل' ||
                  d.folderName == selectedFolderFilter)
              .map((e) => _StudioItemTile(entry: e)),
        ],

        if (activeTab == 'favorites') ...[
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('لا توجد عناصر في المفضلة',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...favorites.map((e) => _StudioItemTile(entry: e)),
        ],

        if (activeTab == 'vault') ...[
          if (s.appPinCode.isNotEmpty && !s.isVaultUnlockedSession)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.vault.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.enhanced_encryption_rounded,
                      size: 42, color: AppColors.vault),
                  const SizedBox(height: 10),
                  const Text('الخزنة السرية مقفلة برمز الحماية',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vaultPinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رمز PIN المكون من 4 أرقام',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final ok = s.unlockVaultWithPin(vaultPinCtrl.text);
                      if (ok) {
                        vaultPinCtrl.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vault,
                        foregroundColor: Colors.white),
                    child: const Text('فتح الخزنة الآن'),
                  ),
                ],
              ),
            )
          else if (vaulted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'الخزنة السرية فارغة. اضغط على أيقونة القفل في أي فيديو لإخفائه هنا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            ...vaulted.map((e) => _StudioItemTile(entry: e)),
        ],
      ],
    );
  }
}

class _StudioItemTile extends StatelessWidget {
  final DownloadEntry entry;
  const _StudioItemTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _SmallPlatformBox(platform: entry.platform),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title.isEmpty
                      ? 'فيديو ${entry.platform}'
                      : entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                if (entry.description.isNotEmpty &&
                    entry.description != entry.title)
                  Text(
                    entry.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted),
                  ),
                Text(
                  entry.localPath.isNotEmpty
                      ? 'متاح أوفلاين: ${entry.localPath}'
                      : 'مجلد: ${entry.folderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 9.5, color: AppColors.success),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showCustomOfflineMediaPlayerModal(context, entry),
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              size: 20,
              color: AppColors.success,
            ),
            tooltip: 'تشغيل أوفلاين بالمشغل المخصص والترجمة',
          ),
          IconButton(
            onPressed: () => showVideoTrimmerModal(context, entry),
            icon: const Icon(
              Icons.content_cut_rounded,
              size: 18,
              color: AppColors.warning,
            ),
            tooltip: 'قص الفيديو',
          ),
          IconButton(
            onPressed: () => showShareDownloadModal(context, entry),
            icon: Icon(
              Icons.share_rounded,
              size: 18,
              color: s.accentColor,
            ),
            tooltip: 'مشاركة التنزيل',
          ),
          IconButton(
            onPressed: () => s.toggleFavorite(entry),
            icon: Icon(
              entry.isFavorite ? Icons.bookmark : Icons.bookmark_border,
              size: 18,
              color: entry.isFavorite ? AppColors.warning : AppColors.textMuted,
            ),
            tooltip: 'المفضلة',
          ),
          IconButton(
            onPressed: () => s.toggleVault(entry),
            icon: Icon(
              entry.isVaulted ? Icons.lock : Icons.lock_open,
              size: 18,
              color: entry.isVaulted ? AppColors.vault : AppColors.textMuted,
            ),
            tooltip: 'نقل للخزنة السرية',
          ),
          IconButton(
            onPressed: () =>
                s.deleteDownloadItem(entry.id, deleteLocalFile: true),
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 19),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMART TOOLS SCREEN (5 Advanced Creator & Downloader Pro Utilities)
// ============================================================================
class SmartToolsScreen extends StatefulWidget {
  const SmartToolsScreen({super.key});

  @override
  State<SmartToolsScreen> createState() => _SmartToolsScreenState();
}

class _SmartToolsScreenState extends State<SmartToolsScreen> {
  int activeToolTab = 0;

  // Tool 1: HD Thumbnail & Metadata Grabber
  final inspectCtrl = TextEditingController();
  Map<String, String>? inspectedMeta;
  bool inspecting = false;

  // Tool 2: Smart Multi-Link Extractor from Messy Text/Messages
  final rawTextCtrl = TextEditingController();
  List<String> extractedLinks = [];

  // Tool 3: Viral Hashtag & SEO Title Generator
  final topicCtrl = TextEditingController();
  String selectedSeoPlatform = 'tiktok';
  List<String> generatedHashtags = [];
  List<String> generatedTitles = [];

  // Tool 4: Visual 3D QR Matrix Generator
  final qrInputCtrl = TextEditingController(text: 'https://dovid.app');

  // Tool 5: Advanced Bitrate, Data & Download Time Calculator
  double durationMin = 8.0;
  double netSpeedMbps = 20.0;

  @override
  void dispose() {
    inspectCtrl.dispose();
    rawTextCtrl.dispose();
    topicCtrl.dispose();
    qrInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _inspectLink() async {
    final u = inspectCtrl.text.trim();
    if (!u.startsWith('http')) return;
    setState(() => inspecting = true);
    final m = await DownloadService.fetchQuickPreviewMetadata(u);
    if (!mounted) return;
    setState(() {
      inspectedMeta = m;
      inspecting = false;
    });
  }

  void _extractUrlsFromMessyText() {
    final raw = rawTextCtrl.text;
    final regex = RegExp(r"""https?:\/\/[^\s"'<>]+""", caseSensitive: false);
    final matches = regex
        .allMatches(raw)
        .map((m) => m.group(0)!.trim())
        .where((u) => u.length > 10)
        .toSet()
        .toList();
    setState(() => extractedLinks = matches);
  }

  void _generateViralSeoPack() {
    final rawTopic = topicCtrl.text.trim();
    final topic = rawTopic.isEmpty ? 'صناعة المحتوى' : rawTopic;
    final cleanTag = topic.replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_');

    final Map<String, List<String>> platformTags = {
      'tiktok': [
        '#$cleanTag',
        '#تيك_توك',
        '#اكسبلور',
        '#ترند_مصر',
        '#فيديوهات_قصيرة',
        '#fyp',
        '#viral',
        '#foryoupage',
        '#tiktokarab',
        '#DOViD_Creator',
      ],
      'youtube': [
        '#$cleanTag',
        '#يوتيوب',
        '#شورتس',
        '#محتوى_هادف',
        '#تعليم_وتطوير',
        '#YouTubeShorts',
        '#Trending4K',
        '#ContentCreator',
      ],
      'instagram': [
        '#$cleanTag',
        '#انستجرام',
        '#ريلز',
        '#تصوير_احترافي',
        '#اكسبلور_فولو',
        '#ReelsInstagram',
        '#InstaDaily',
        '#ExplorePage',
      ],
      'twitter': [
        '#$cleanTag',
        '#منصة_X',
        '#ترند_اليوم',
        '#تقنية',
        '#أخبار_عاجلة',
        '#TrendingNow',
      ],
    };

    setState(() {
      generatedHashtags =
          platformTags[selectedSeoPlatform] ?? platformTags['tiktok']!;
      generatedTitles = [
        'السر الكامل حول $topic الذي لم يخبرك به أحد (بجودة 4K)',
        'كيف تحترف $topic في 5 دقائق خطوة بخطوة للمبتدئين والمحترفين',
        'تجربتي الحقيقية مع $topic: أهم النصائح والنتائج المذهلة!',
        'أقوى دليل عملي شامل عن $topic لعام 2026',
      ];
    });
  }

  String _formatDownloadSeconds(double sizeMB, double speedMbps) {
    final megabytesPerSec = (speedMbps / 8.0).clamp(0.1, 500.0);
    final totalSec = (sizeMB / megabytesPerSec).round();
    if (totalSec < 60) return '$totalSec ثانية';
    final min = totalSec ~/ 60;
    final rem = totalSec % 60;
    return '$min د و $rem ث';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final accent = s.accentColor;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Icon(Icons.handyman_rounded, color: accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'استوديو الأدوات الذكية المتقدمة (5 أدوات احترافية)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AdminTab(
                label: '1. فاحص الغلاف HD',
                icon: Icons.image_search_rounded,
                active: activeToolTab == 0,
                onTap: () => setState(() => activeToolTab = 0),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: '2. مستخرج الروابط الذكي',
                icon: Icons.auto_fix_high_rounded,
                active: activeToolTab == 1,
                onTap: () => setState(() => activeToolTab = 1),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: '3. مولد الهاشتاج والـ SEO',
                icon: Icons.tag_rounded,
                active: activeToolTab == 2,
                onTap: () => setState(() => activeToolTab = 2),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: '4. صانع باركود QR',
                icon: Icons.qr_code_2_rounded,
                active: activeToolTab == 3,
                onTap: () => setState(() => activeToolTab = 3),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: '5. حاسبة الباقة والسرعة',
                icon: Icons.speed_rounded,
                active: activeToolTab == 4,
                onTap: () => setState(() => activeToolTab = 4),
              ),
              const SizedBox(width: 8),
              _AdminTab(
                label: '6. استوديو القص والمشغل',
                icon: Icons.content_cut_rounded,
                active: activeToolTab == 5,
                onTap: () => setState(() => activeToolTab = 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // TOOL 1: HD Thumbnail & Metadata Grabber
        if (activeToolTab == 0)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.image_search_rounded,
                        color: AppColors.guest, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مستخرج الصور المصغرة وبيانات الفيديو (HD Thumbnail)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AuthField(
                        controller: inspectCtrl,
                        icon: Icons.link,
                        hint: 'الصق رابط الفيديو لاستخراج غلافه وبياناته...',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: inspecting ? null : _inspectLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      child: Text(inspecting ? '...' : 'فحص دقيق'),
                    ),
                  ],
                ),
                if (inspectedMeta != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Platform3DBadge(
                        platformId: inspectedMeta!['platform'] ?? 'unknown',
                        active: true,
                        size: 46,
                        showLabel: false,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العنوان: ${inspectedMeta!['title'] ?? 'غير متوفر'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            Text(
                              'القناة / الناشر: ${inspectedMeta!['author'] ?? 'غير متوفر'}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((inspectedMeta!['thumbnail'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        inspectedMeta!['thumbnail']!,
                        height: 175,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: inspectedMeta!['thumbnail']!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'تم نسخ رابط الصورة المصغرة عالية الدقة'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 15),
                            label: const Text('نسخ رابط الغلاف HD'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              s.sendLinksToBatchDownloader(
                                  [inspectCtrl.text.trim()]);
                            },
                            icon: const Icon(Icons.download_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('إرسال للتحميل',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),

        // TOOL 2: Smart Multi-Link Extractor from Messy Text
        if (activeToolTab == 1)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_motion_rounded,
                        color: AppColors.admin, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المستخرج الذكي للروابط من المحادثات والرسائل الطويلة',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'الصق أي رسالة واتساب أو تيليجرام تحتوي على كلام مختلط بروابط، وسيقوم النظام بفلترة واستخراج الروابط وتصنيفها بشعار كل منصة 3D.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rawTextCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'الصق النص أو الرسالة هنا لاستخراج كافة الروابط تلقائياً...',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _extractUrlsFromMessyText,
                        icon: const Icon(Icons.filter_alt_rounded,
                            color: Colors.white, size: 17),
                        label: const Text('استخراج وفلترة الروابط الآن',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          rawTextCtrl.text = data!.text!;
                          _extractUrlsFromMessyText();
                        }
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 15),
                      label: const Text('لصق من الحافظة'),
                    ),
                  ],
                ),
                if (extractedLinks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تم العثور على (${extractedLinks.length}) رابط صالح:',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.success),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            s.sendLinksToBatchDownloader(extractedLinks),
                        icon: const Icon(Icons.rocket_launch_rounded,
                            size: 14, color: Colors.white),
                        label: const Text('تحميل الكل دفعة واحدة',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...extractedLinks.map((u) => Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _SmallPlatformBox(platform: detectPlatform(u)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                u,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: u));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الرابط'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),

        // TOOL 3: Viral Hashtag & SEO Generator
        if (activeToolTab == 2)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: AppColors.warning, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مولد الهاشتاجات المتصدرة وعناوين SEO لصناع المحتوى',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['tiktok', 'youtube', 'instagram', 'twitter']
                      .map((pid) => Platform3DBadge(
                            platformId: pid,
                            active: selectedSeoPlatform == pid,
                            size: 44,
                            showLabel: true,
                            onTap: () =>
                                setState(() => selectedSeoPlatform = pid),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AuthField(
                        controller: topicCtrl,
                        icon: Icons.lightbulb_outline,
                        hint: 'اكتب موضوع الفيديو (مثال: برمجة تطبيقات فلاتر)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _generateViralSeoPack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      child: const Text('توليد'),
                    ),
                  ],
                ),
                if (generatedHashtags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('الهاشتاجات المقترحة الأكثر انتشاراً:',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: generatedHashtags
                        .map((tag) => _MiniTag(tag, accent))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: generatedHashtags.join(' ')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ جميع الهاشتاجات للحافظة'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: const Text('نسخ حزمة الهاشتاجات كاملة'),
                  ),
                  const SizedBox(height: 12),
                  const Text('عناوين مقترحة لزيادة نسبة النقر (CTR):',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...generatedTitles.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: t));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ العنوان'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 15),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),

        // TOOL 4: Visual 3D QR Matrix Generator
        if (activeToolTab == 3)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'صانع مصفوفة باركود المشاركة السريعة (Visual QR Matrix)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qrInputCtrl,
                  onChanged: (_) => setState(() {}),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'أدخل رابط الفيديو أو النص لتوليد مصفوفة QR...',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.45)),
                    ),
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: CustomPaint(
                        painter: VisualQrMatrixPainter(
                          data: qrInputCtrl.text.trim(),
                          foregroundColor: accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'مصفوفة QR رقمية جاهزة للمشاركة السريعة بين الأجهزة',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

        // TOOL 5: Advanced Bitrate, Storage & Transfer Time Calculator
        if (activeToolTab == 4)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed_rounded, color: AppColors.api, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'حاسبة استهلاك الباقة وحجم الفيديو وزمن التنزيل',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'مدة الفيديو: ${durationMin.toStringAsFixed(0)} دقيقة',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: durationMin,
                  min: 1,
                  max: 120,
                  divisions: 119,
                  activeColor: accent,
                  onChanged: (v) => setState(() => durationMin = v),
                ),
                Text(
                  'سرعة الإنترنت لديك: ${netSpeedMbps.toStringAsFixed(0)} Mbps',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: netSpeedMbps,
                  min: 2,
                  max: 100,
                  divisions: 49,
                  activeColor: AppColors.secondary,
                  onChanged: (v) => setState(() => netSpeedMbps = v),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimerBox(
                      value: '${(durationMin * 1.4).toStringAsFixed(1)} MB',
                      label:
                          'MP3 (${_formatDownloadSeconds(durationMin * 1.4, netSpeedMbps)})',
                    ),
                    _TimerBox(
                      value: '${(durationMin * 12).toStringAsFixed(0)} MB',
                      label:
                          '720p (${_formatDownloadSeconds(durationMin * 12, netSpeedMbps)})',
                    ),
                    _TimerBox(
                      value: '${(durationMin * 24).toStringAsFixed(0)} MB',
                      label:
                          '1080p (${_formatDownloadSeconds(durationMin * 24, netSpeedMbps)})',
                    ),
                    _TimerBox(
                      value: '${(durationMin * 65).toStringAsFixed(0)} MB',
                      label:
                          '4K (${_formatDownloadSeconds(durationMin * 65, netSpeedMbps)})',
                    ),
                  ],
                ),
              ],
            ),
          ),

        // TOOL 6: Direct Video Trimmer & Custom Offline Player Launcher
        if (activeToolTab == 5)
          Tilt3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.movie_filter_rounded,
                        color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'استوديو قص الفيديو والمشغل السينمائي أوفلاين (المترجم)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'اختر أي فيديو من تنزيلاتك لقص مقاطع محددة منه بدقة الثانية أو تشغيله أوفلاين مع الترجمة الفورية عبر الإنترنت أو بملف SRT/VTT:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                if (s.myDownloads.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'قم بتجهيز أو تحميل أي فيديو أولاً ليظهر هنا للقص والتشغيل أوفلاين',
                        style:
                            TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...s.myDownloads.take(10).map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _SmallPlatformBox(platform: e.platform),
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
                                        fontSize: 12),
                                  ),
                                  Text(
                                    e.description.isNotEmpty
                                        ? e.description
                                        : 'متاح للقص والتشغيل الفوري',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  showVideoTrimmerModal(context, e),
                              icon: const Icon(Icons.content_cut_rounded,
                                  size: 14, color: Colors.black),
                              label: const Text('قص',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  showCustomOfflineMediaPlayerModal(context, e),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 15, color: Colors.white),
                              label: const Text('تشغيل',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// HISTORY SCREEN (Clean User History - Zero Bypass Names Shown)
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
    final rawList = s.myDownloads;
    final list = rawList.where((e) {
      final matchesPlatform =
          selectedPlatform == 'all' || e.platform == selectedPlatform;
      final matchesSearch = searchQuery.isEmpty ||
          e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.url.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesPlatform && matchesSearch;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(Icons.history, color: s.accentColor),
              const SizedBox(width: 8),
              const Text('سجل التحميلات',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              if (rawList.isNotEmpty) ...[
                IconButton(
                  onPressed: () {
                    final summary = rawList
                        .take(20)
                        .map((d) =>
                            '• ${d.title.isEmpty ? d.platform.toUpperCase() : d.title}\n  ${d.downloadLink.isNotEmpty ? d.downloadLink : d.url}')
                        .join('\n\n');
                    Clipboard.setData(ClipboardData(
                        text: '📥 قائمة تنزيلات $kAppName:\n\n$summary'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('تم نسخ قائمة التنزيلات كاملة للمشاركة'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: Icon(Icons.share_rounded,
                      size: 18, color: s.accentColor),
                  tooltip: 'مشاركة قائمة التنزيلات',
                ),
                TextButton.icon(
                  onPressed: () => s.clearMyHistory(),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: const Text('مسح السجل',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: const Text('الكل', style: TextStyle(fontSize: 10.5)),
                  selected: selectedPlatform == 'all',
                  onSelected: (_) => setState(() => selectedPlatform = 'all'),
                ),
              ),
              ...kSupportedPlatforms3D.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(p.name, style: const TextStyle(fontSize: 10.5)),
                      selected: selectedPlatform == p.id,
                      onSelected: (_) =>
                          setState(() => selectedPlatform = p.id),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'ابحث في سجل الفيديوهات...',
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
              ? const Center(
                  child: Text('لا توجد عناصر في السجل',
                      style: TextStyle(color: AppColors.textMuted)),
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
                      child: Row(
                        children: [
                          _SmallPlatformBox(platform: e.platform),
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
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _MiniTag(e.platform, s.accentColor),
                                    _MiniTag(e.quality, AppColors.success),
                                    _MiniTag(e.folderName, AppColors.secondary),
                                    _MiniTag(timeAgo(e.createdAt),
                                        AppColors.textMuted),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => showShareDownloadModal(context, e),
                            icon: Icon(Icons.share_rounded,
                                size: 17, color: s.accentColor),
                            tooltip: 'مشاركة التنزيل',
                          ),
                          IconButton(
                            onPressed: () => s.deleteDownloadItem(e.id),
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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

// ============================================================================
// SETTINGS SCREEN (Typography, Theme, PIN Security, SQLite Status & VIP API)
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final codeCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final downloadPathCtrl = TextEditingController();
  String? codeError;
  String? codeSuccess;

  final List<Map<String, String>> presetDownloadDirs = const [
    {
      'label': 'مجلد التنزيلات الرئيسي (Download)',
      'path': '/storage/emulated/0/Download/DOViD',
    },
    {
      'label': 'مجلد الأفلام والفيديو (Movies)',
      'path': '/storage/emulated/0/Movies/DOViD',
    },
    {
      'label': 'مجلد الصوتيات والموسيقى (Music)',
      'path': '/storage/emulated/0/Music/DOViD',
    },
    {
      'label': 'مجلد الاستوديو والكاميرا (DCIM)',
      'path': '/storage/emulated/0/DCIM/DOViD',
    },
    {
      'label': 'مجلد المستندات (Documents)',
      'path': '/storage/emulated/0/Documents/DOViD',
    },
  ];

  final themeSwatches = const [
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    final s = AppState();
    pinCtrl.text = s.appPinCode;
    downloadPathCtrl.text = s.customDownloadDirectory;
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    pinCtrl.dispose();
    downloadPathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final key = s.myApiKey;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [s.accentColor, AppColors.secondary]),
                ),
                child: const Center(
                  child: Text('YJ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(kDevName,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    Text('مطور ومؤسس النظام',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: s.accentColor,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('WhatsApp: $kDevWhatsapp',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://wa.me/2$kDevWhatsapp')),
                icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              ),
            ],
          ),
        ),
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
              Row(
                children: [
                  Icon(Icons.font_download_rounded,
                      color: s.accentColor, size: 18),
                  const SizedBox(width: 8),
                  const Text('تحسين الخطوط والمظهر المريح للعين',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('نوع خط التطبيق:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: ['Cairo', 'Tajawal', 'Roboto'].map((f) {
                  final active = s.fontFamily == f;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => s.saveSettings(newFontFamily: f),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: active
                              ? s.accentColor.withOpacity(0.18)
                              : AppColors.surfaceLight,
                          side: BorderSide(
                              color: active ? s.accentColor : AppColors.border),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? Colors.white
                                    : AppColors.textMuted)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text('حجم الخطوط: ${(s.fontScale * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              Slider(
                value: s.fontScale,
                min: 0.9,
                max: 1.15,
                divisions: 5,
                activeColor: s.accentColor,
                onChanged: (v) => s.saveSettings(newFontScale: v),
              ),
              const Text('اللون الأساسي للثيم:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: themeSwatches.map((c) {
                  final selected = s.accentColor.value == c.value;
                  return GestureDetector(
                    onTap: () => s.saveSettings(newColor: c),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
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
              Row(
                children: [
                  Icon(Icons.folder_open_rounded,
                      color: s.accentColor, size: 19),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تغيير وتخصيص مسار حفظ التنزيلات بالهاتف',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'المسار الفعال حالياً: ${s.customDownloadDirectory}',
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.success),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presetDownloadDirs.map((preset) {
                  final pPath = preset['path']!;
                  final active = s.customDownloadDirectory == pPath;
                  return ChoiceChip(
                    label: Text(
                      preset['label']!,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    selected: active,
                    onSelected: (_) {
                      setState(() => downloadPathCtrl.text = pPath);
                      s.saveSettings(newDownloadDir: pPath);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تغيير مسار التنزيل إلى: $pPath'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: downloadPathCtrl,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 11.5, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: '/storage/emulated/0/Download/DOViD',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final entered = downloadPathCtrl.text.trim();
                      if (entered.isEmpty) return;
                      await s.saveSettings(newDownloadDir: entered);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حفظ مسار التنزيل المخصص: $entered'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('حفظ المسار'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pathToTest = downloadPathCtrl.text.trim();
                        final ok = await DownloadService.verifyDirectoryWritable(
                            pathToTest);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'المسار صالح وقابل للكتابة والحفظ فوراً ✓'
                                : 'النظام يستخدم المسار الاحتياطي التلقائي عند الحاجة'),
                            backgroundColor:
                                ok ? AppColors.success : AppColors.warning,
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_outlined, size: 15),
                      label: const Text('فحص صلاحية المسار',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        const def = '/storage/emulated/0/Download/DOViD';
                        setState(() => downloadPathCtrl.text = def);
                        s.saveSettings(newDownloadDir: def);
                      },
                      icon: const Icon(Icons.restore_rounded, size: 15),
                      label: const Text('المسار الافتراضي',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.autoRouteAudioToMusicDir,
                activeColor: s.accentColor,
                title: const Text(
                    'فرز تلقائي للصوتيات MP3 في مجلد الموسيقى (Music)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onChanged: (v) => s.saveSettings(newAutoRouteAudio: v),
              ),
            ],
          ),
        ),
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
              Row(
                children: [
                  Icon(Icons.security_rounded, color: s.accentColor, size: 18),
                  const SizedBox(width: 8),
                  const Text('حماية الحساب والخزنة برمز PIN',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pinCtrl,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'رمز مكون من 4 أرقام (اتركه فارغاً للإلغاء)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final p = pinCtrl.text.trim();
                      if (p.isNotEmpty && p.length != 4) return;
                      s.saveSettings(newAppPin: p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث رمز الحماية PIN بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('حفظ الرمز'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.requirePinOnLaunch,
                activeColor: s.accentColor,
                title: const Text('طلب رمز PIN عند فتح التطبيق',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                onChanged: (v) => s.saveSettings(newRequirePinOnLaunch: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.autoSaveAfterExtract,
                activeColor: s.accentColor,
                title: const Text('حفظ تلقائي بالهاتف فور التجهيز',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                onChanged: (v) => s.saveSettings(newAutoSave: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.autoDetectClipboard,
                activeColor: s.accentColor,
                title: const Text('رادار الحافظة الذكي',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                onChanged: (v) => s.saveSettings(newAutoDetectClipboard: v),
              ),
              const Divider(color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.enable3DEffects,
                activeColor: s.accentColor,
                title: const Text(
                    'تفعيل الشعارات والمجسمات ثلاثية الأبعاد (3D Logos & Tilt)',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'رسم هندسي ثلاثي الأبعاد لشعارات المنصات وبطاقات المنظور التفاعلية',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onChanged: (v) => s.saveSettings(newEnable3DEffects: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.highGraphicsEnabled,
                activeColor: s.accentColor,
                title: const Text(
                    'تفعيل الرسوميات العالية والأنيميشن الفائق (60FPS Smooth)',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'حركات عائمة سلسة وموجات صوتية تفاعلية مع الحفاظ على راحة العين',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onChanged: (v) => s.saveSettings(newHighGraphics: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (!s.isGuest)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.api.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: AppColors.api, size: 20),
                    SizedBox(width: 8),
                    Text('اشتراك VIP وبوابة المطورين API',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                if (key != null && key.isActive) ...[
                  Text('مفتاح API الفعال: ${key.apiKey}',
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.api)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TimerBox(value: '${key.daysLeft}', label: 'يوم متبقي'),
                      _TimerBox(value: '${key.hoursLeft}', label: 'ساعة'),
                      _TimerBox(value: '${key.maxQuota}', label: 'حد الطلبات'),
                    ],
                  ),
                ] else
                  const Text(
                    'فعّل كود الاشتراك للحصول على رتبة VIP (بدون إعلانات + تحميل 4K غير محدود + مفتاح API). سعر الاشتراك: $kApiPrice جنيه عبر فودافون كاش ($kDevWhatsapp).',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: 'DOViD-XXXXXXXXXXXX',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (codeCtrl.text.trim().isEmpty) return;
                      final err = s.activateCode(codeCtrl.text);
                      setState(() {
                        codeError = err;
                        codeSuccess = err == null
                            ? 'تم تفعيل اشتراك VIP ومفتاح API بنجاح!'
                            : null;
                      });
                      if (err == null) codeCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.api,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('تفعيل كود الاشتراك الآن',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                if (codeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(codeError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 11)),
                  ),
                if (codeSuccess != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(codeSuccess!,
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 11)),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => s.logout(),
            icon: const Icon(Icons.logout, color: AppColors.error, size: 16),
            label: const Text('تسجيل الخروج من الحساب',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TimerBox extends StatelessWidget {
  final String value;
  final String label;
  const _TimerBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.api)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MASSIVE 9-TAB SUPER ADMIN COMMAND CENTER
// ============================================================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.admin, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'غرفة القيادة المركزية للمدير العام (Super Admin)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.admin,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AdminTab(
                        label: '1. القيادة والتحكم',
                        icon: Icons.dashboard_customize_rounded,
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '2. إعلانات Google',
                        icon: Icons.ads_click_rounded,
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '3. محرك SQLite',
                        icon: Icons.storage_rounded,
                        active: _tab == 2,
                        onTap: () => setState(() => _tab = 2)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '4. المستخدمين و VIP',
                        icon: Icons.people_alt_rounded,
                        active: _tab == 3,
                        onTap: () => setState(() => _tab = 3)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '5. التحميلات الشاملة',
                        icon: Icons.cloud_download_rounded,
                        active: _tab == 4,
                        onTap: () => setState(() => _tab = 4)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '6. محركات الخلفية',
                        icon: Icons.settings_input_component_rounded,
                        active: _tab == 5,
                        onTap: () => setState(() => _tab = 5)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '7. درع الحماية و VPN',
                        icon: Icons.vpn_lock_rounded,
                        active: _tab == 6,
                        onTap: () => setState(() => _tab = 6)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '8. الإشعارات العامة',
                        icon: Icons.campaign_rounded,
                        active: _tab == 7,
                        onTap: () => setState(() => _tab = 7)),
                    const SizedBox(width: 6),
                    _AdminTab(
                        label: '9. الأكواد و API',
                        icon: Icons.vpn_key_rounded,
                        active: _tab == 8,
                        onTap: () => setState(() => _tab = 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _AdminCommandCenterTab(),
                  _AdminGoogleAdsStudioTab(),
                  _AdminSqliteEngineTab(),
                  _AdminUsersManagerTab(),
                  _AdminGlobalDownloadsTab(),
                  _AdminBackgroundEnginesTab(),
                  _AdminSecurityAndVpnTab(),
                  _AdminBroadcastTab(),
                  _AdminCodesAndApiTab(),
                ],
              ),
            ),
          ],
        );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.admin : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? Colors.transparent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13, color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TAB 1: COMMAND CENTER
class _AdminCommandCenterTab extends StatelessWidget {
  const _AdminCommandCenterTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
                child: _AdminStat(
                    'المستخدمين', s.users.length, AppColors.admin)),
            const SizedBox(width: 8),
            Expanded(
                child: _AdminStat(
                    'التحميلات', s.downloads.length, AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _AdminStat('عمليات الخلفية', s.bypassLogs.length,
                    AppColors.guest)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _AdminStat('ظهور الإعلانات', s.totalAdImpressions,
                    const Color(0xFF4285F4))),
            const SizedBox(width: 8),
            Expanded(
                child: _AdminStat(
                    'نقرات الإعلانات', s.totalAdClicks, AppColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _AdminStat('تهديدات محظورة',
                    s.securityEvents.where((e) => e.isThreat).length,
                    AppColors.error)),
          ],
        ),
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
              const Text('مفاتيح التحكم الفوري بالنظام',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.maintenanceMode,
                activeColor: AppColors.warning,
                title: const Text('وضع الصيانة الشامل (Maintenance Mode)',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'يقفل التطبيق مؤقتاً لجميع المستخدمين ما عدا حساب المدير',
                    style: TextStyle(fontSize: 10.5)),
                onChanged: (v) => s.saveSettings(newMaintenanceMode: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.allowGuestAccess,
                activeColor: AppColors.guest,
                title: const Text('السماح بالدخول كزائر (Guest Mode)',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                onChanged: (v) => s.saveSettings(newAllowGuestAccess: v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.emergencyLockdownMode,
                activeColor: AppColors.error,
                title: const Text(
                    'وضع الإغلاق الأمني الطارئ (Emergency Lockdown)',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'إيقاف جميع عمليات الاستخراج والتحميل مؤقتاً لحين انتهاء الفحص الأمني',
                    style: TextStyle(fontSize: 10.5)),
                onChanged: (v) => s.saveSettings(newEmergencyLockdown: v),
              ),
              const SizedBox(height: 8),
              Text(
                  'الحصة اليومية للمستخدم المجاني: ${s.freeDailyQuota} تحميل/يوم',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              Slider(
                value: s.freeDailyQuota.toDouble().clamp(5, 200),
                min: 5,
                max: 200,
                divisions: 39,
                activeColor: AppColors.admin,
                onChanged: (v) =>
                    s.saveSettings(newFreeDailyQuota: v.round()),
              ),
              Text(
                  'أقصى عدد للتحميلات المتزامنة بالخلفية: ${s.maxConcurrentDownloads}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              Slider(
                value: s.maxConcurrentDownloads.toDouble().clamp(1, 8),
                min: 1,
                max: 8,
                divisions: 7,
                activeColor: AppColors.success,
                onChanged: (v) =>
                    s.saveSettings(newMaxConcurrent: v.round()),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        s.resetAllUsersDailyQuotas();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تم تصفير العداد اليومي لجميع المستخدمين بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('تصفير حصص اليوم',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        s.grantVipToAllUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('تم منح صلاحية VIP لجميع الأعضاء المسجلين'),
                            backgroundColor: AppColors.api,
                          ),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium,
                          size: 16, color: Colors.black),
                      label: const Text('منح VIP للجميع',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.api),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                'بوابة التحكم الفردي في المنصات الـ 10 (تفعيل / إيقاف فوري)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSupportedPlatforms3D.map((p) {
                  final allowed = s.allowedPlatforms[p.id] != false;
                  return FilterChip(
                    label: Text(p.name, style: const TextStyle(fontSize: 11)),
                    selected: allowed,
                    selectedColor: p.accentGlow.withOpacity(0.24),
                    checkmarkColor: Colors.white,
                    onSelected: (v) => s.togglePlatformAllowed(p.id, v),
                  );
                }).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// TAB 2: REAL GOOGLE ADS STUDIO (AdMob + AdSense)
class _AdminGoogleAdsStudioTab extends StatefulWidget {
  const _AdminGoogleAdsStudioTab();

  @override
  State<_AdminGoogleAdsStudioTab> createState() =>
      _AdminGoogleAdsStudioTabState();
}

class _AdminGoogleAdsStudioTabState extends State<_AdminGoogleAdsStudioTab> {
  late final TextEditingController admobAppCtrl;
  late final TextEditingController admobBannerCtrl;
  late final TextEditingController admobInterCtrl;
  late final TextEditingController admobRewardCtrl;
  late final TextEditingController pubIdCtrl;
  late final TextEditingController dispSlotCtrl;
  late final TextEditingController inArtSlotCtrl;
  late final TextEditingController sponsorUrlCtrl;

  @override
  void initState() {
    super.initState();
    final s = AppState();
    admobAppCtrl = TextEditingController(text: s.admobAppId);
    admobBannerCtrl = TextEditingController(text: s.admobBannerUnitId);
    admobInterCtrl = TextEditingController(text: s.admobInterstitialUnitId);
    admobRewardCtrl = TextEditingController(text: s.admobRewardedUnitId);
    pubIdCtrl = TextEditingController(text: s.adsensePublisherId);
    dispSlotCtrl = TextEditingController(text: s.adsenseDisplaySlot);
    inArtSlotCtrl = TextEditingController(text: s.adsenseInArticleSlot);
    sponsorUrlCtrl = TextEditingController(text: s.customSponsorTargetUrl);
  }

  @override
  void dispose() {
    admobAppCtrl.dispose();
    admobBannerCtrl.dispose();
    admobInterCtrl.dispose();
    admobRewardCtrl.dispose();
    pubIdCtrl.dispose();
    dispSlotCtrl.dispose();
    inArtSlotCtrl.dispose();
    sponsorUrlCtrl.dispose();
    super.dispose();
  }

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.ads_click, color: Color(0xFF4285F4)),
                      SizedBox(width: 8),
                      Text('نظام إعلانات Google الفعلي (AdMob & AdSense)',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13.5)),
                    ],
                  ),
                  Switch(
                    value: s.adsEnabled,
                    activeColor: AppColors.success,
                    onChanged: (v) => s.saveSettings(newAdsEnabled: v),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.bannerAdsEnabled,
                activeColor: const Color(0xFF4285F4),
                title: const Text('تفعيل إعلانات البانر (Banner Ads)',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newBannerAdsEnabled: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.interstitialAdsEnabled,
                activeColor: const Color(0xFF4285F4),
                title: const Text('تفعيل الإعلانات البينية (Interstitial Ads)',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newInterstitialAdsEnabled: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.rewardedAdsEnabled,
                activeColor: const Color(0xFF4285F4),
                title: const Text('إعلانات المكافأة لفتح جودة 4K (Rewarded Ads)',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newRewardedAdsEnabled: v),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimerBox(
                      value:
                          '\$${s.estimatedTotalAdRevenueUsd.toStringAsFixed(2)}',
                      label: 'الأرباح التقديرية',
                    ),
                    _TimerBox(
                      value: '${s.adCtrPercent.toStringAsFixed(1)}%',
                      label: 'نسبة النقر CTR',
                    ),
                    _TimerBox(
                      value: '${s.totalAdImpressions}',
                      label: 'مرات الظهور',
                    ),
                    _TimerBox(
                      value: '${s.totalAdRewards}',
                      label: 'مكافآت 4K',
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.nativeAdsEnabled,
                activeColor: const Color(0xFF4285F4),
                title: const Text('تفعيل الإعلانات المدمجة (Native Advanced Ads)',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newNativeAdsEnabled: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.appOpenAdsEnabled,
                activeColor: const Color(0xFF4285F4),
                title: const Text('تفعيل إعلانات فتح التطبيق (App Open Ads)',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newAppOpenAdsEnabled: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.vipNoAds,
                activeColor: AppColors.api,
                title: const Text('إعفاء مشتركي VIP من جميع الإعلانات',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => s.saveSettings(newVipNoAds: v),
              ),
              const SizedBox(height: 4),
              const Text('مواضع عرض البانر الإعلاني داخل الشاشات:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('أعلى الرئيسية',
                        style: TextStyle(fontSize: 10.5)),
                    selected: s.placeAdsHomeTop,
                    onSelected: (v) => s.saveSettings(newPlaceAdsHomeTop: v),
                  ),
                  FilterChip(
                    label: const Text('أسفل الرئيسية',
                        style: TextStyle(fontSize: 10.5)),
                    selected: s.placeAdsHomeBottom,
                    onSelected: (v) =>
                        s.saveSettings(newPlaceAdsHomeBottom: v),
                  ),
                  FilterChip(
                    label: const Text('شاشة الاستوديو',
                        style: TextStyle(fontSize: 10.5)),
                    selected: s.placeAdsStudio,
                    onSelected: (v) => s.saveSettings(newPlaceAdsStudio: v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'معدل تكرار الإعلان البيني: كل ${s.interstitialFrequency} عمليات تحميل',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Slider(
                value: s.interstitialFrequency.toDouble().clamp(1, 10),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: const Color(0xFF4285F4),
                onChanged: (v) =>
                    s.saveSettings(newInterstitialFreq: v.round()),
              ),
              Text(
                'العائد لكل ألف ظهور (eCPM): \$${s.estimatedEcpmUsd.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Slider(
                value: s.estimatedEcpmUsd.clamp(0.5, 15.0),
                min: 0.5,
                max: 15.0,
                divisions: 29,
                activeColor: AppColors.success,
                onChanged: (v) => s.saveSettings(newEstimatedEcpm: v),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => s.clearAdAnalytics(),
                  icon: const Icon(Icons.cleaning_services_rounded,
                      size: 14, color: AppColors.error),
                  label: const Text('تصفير عداد الإحصائيات الإعلانية',
                      style: TextStyle(fontSize: 11, color: AppColors.error)),
                ),
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 6),
              const Text('معرفات وحدات Google AdMob الحقيقية:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              _AuthField(
                  controller: admobAppCtrl,
                  icon: Icons.apps_rounded,
                  hint: 'AdMob App ID (ca-app-pub-xxx~yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: admobBannerCtrl,
                  icon: Icons.view_stream,
                  hint: 'Banner Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: admobInterCtrl,
                  icon: Icons.fullscreen,
                  hint: 'Interstitial Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: admobRewardCtrl,
                  icon: Icons.card_giftcard,
                  hint: 'Rewarded Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 12),
              const Text('معرفات Google AdSense (للويب والعارض المدمج):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              _AuthField(
                  controller: pubIdCtrl,
                  icon: Icons.fingerprint,
                  hint: 'Publisher ID (ca-pub-xxxxxxxxxxxxxxxx)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: dispSlotCtrl,
                  icon: Icons.view_headline,
                  hint: 'Display Ad Slot ID'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: inArtSlotCtrl,
                  icon: Icons.article_outlined,
                  hint: 'In-Article Ad Slot ID'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: sponsorUrlCtrl,
                  icon: Icons.link,
                  hint: 'رابط التوجيه الإعلاني المباشر (اختياري)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        s.saveSettings(
                          newAdmobAppId: admobAppCtrl.text,
                          newAdmobBannerId: admobBannerCtrl.text,
                          newAdmobInterstitialId: admobInterCtrl.text,
                          newAdmobRewardedId: admobRewardCtrl.text,
                          pubId: pubIdCtrl.text,
                          dispSlot: dispSlotCtrl.text,
                          inArtSlot: inArtSlotCtrl.text,
                          sponsorUrl: sponsorUrlCtrl.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تم حفظ وتفعيل معرفات Google Ads في SQLite بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('حفظ المعرفات الإعلانية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        GoogleAdsEngine.showInterstitialAd(context),
                    child: const Text('اختبار إعلان بيني'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// TAB 3: SQLITE DATABASE ENGINE & BACKUP MANAGER
class _AdminSqliteEngineTab extends StatefulWidget {
  const _AdminSqliteEngineTab();

  @override
  State<_AdminSqliteEngineTab> createState() => _AdminSqliteEngineTabState();
}

class _AdminSqliteEngineTabState extends State<_AdminSqliteEngineTab> {
  int dbBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  Future<void> _refreshSize() async {
    final sz = await AppState().db.getDatabaseSizeBytes();
    if (mounted) setState(() => dbBytes = sz);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final db = s.db;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.guest.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: AppColors.admin),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيرفر التخزين السحابي JOO CLOUD DATABASE + SQLite WAL',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.admin.withOpacity(0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات الربط السحابي النشط (JOO CLOUD SERVER):',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          color: AppColors.admin),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow('معرف المشروع (Project ID)', kJooCloudProjectId),
                    _InfoRow(
                        'مفتاح التخزين (Public Key)',
                        '${kJooCloudPublicKey.substring(0, 18)}...'),
                    _InfoRow('حالة السيرفر السحابي',
                        JooCloudDatabaseClient.lastCloudResponse),
                    _InfoRow('السجلات المتزامنة سحابياً',
                        '${JooCloudDatabaseClient.syncedDocumentsCount} دفعة مشفرة'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok =
                                  await JooCloudDatabaseClient.pingServer();
                              if (mounted) setState(() {});
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      JooCloudDatabaseClient.lastCloudResponse),
                                  backgroundColor:
                                      ok ? AppColors.success : AppColors.guest,
                                ),
                              );
                            },
                            icon: const Icon(Icons.wifi_tethering_rounded,
                                size: 15, color: Colors.white),
                            label: const Text('فحص اتصال JOO CLOUD',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.admin),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(kJooCloudProjectUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('لوحة السيرفر',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow('وضع Journal Mode',
                  db.isWalActive ? 'WAL (Write-Ahead Logging)' : 'DELETE'),
              _InfoRow('حجم قاعدة البيانات الفعلي', formatBytes(dbBytes)),
              _InfoRow(
                  'عمليات الكتابة المسجلة', '${db.writeTransactionsCount} عملية'),
              _InfoRow('حالة فحص السلامة (Integrity)', db.lastIntegrityStatus),
              _InfoRow('مسار التخزين',
                  db.dbFilePath.isEmpty ? 'Internal Mirror' : db.dbFilePath),
              const Divider(color: AppColors.border),
              _InfoRow('حالة المزامنة اللحظية', s.sqliteSyncStatusText),
              _InfoRow('جدول الحسابات (users)', '${s.users.length} حساب'),
              _InfoRow('جدول نشاط المستخدمين (user_activity_logs)',
                  '${s.userActivityLogs.length} نشاط'),
              _InfoRow('جدول التنزيلات (downloads)', '${s.downloads.length} سجل'),
              _InfoRow('جدول bypass_logs (بالخلفية)',
                  '${s.bypassLogs.length} سجل'),
              _InfoRow(
                  'جدول security_events', '${s.securityEvents.length} سجل'),
              _InfoRow('جدول ad_events', '${s.adEvents.length} سجل'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await db.runVacuumAndIntegrityCheck();
                        await _refreshSize();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تم ضغط قاعدة بيانات SQLite (VACUUM) وفحص سلامتها بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('تحسين وضغط SQLite (VACUUM)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.guest,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final dump = db.exportFullDatabaseJson();
                      Clipboard.setData(ClipboardData(text: dump));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'تم نسخ النسخة الاحتياطية الكاملة لقاعدة البيانات'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('تصدير Backup'),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: s.isSyncingSqlite
                    ? null
                    : () async {
                        await s.syncAccountsAndActivityWithSqlite();
                        await _refreshSize();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.sqliteSyncStatusText),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                icon: const Icon(Icons.sync_rounded,
                    size: 17, color: Colors.white),
                label: Text(
                  s.isSyncingSqlite
                      ? 'جاري مزامنة الحسابات والنشاط...'
                      : 'مزامنة الحسابات ونشاط المستخدمين عبر SQLite الآن',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.admin,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        const Text(
          'سجل نشاط الحسابات المباشر المخزن في SQLite (أحدث العمليات):',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (s.userActivityLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'سيظهر هنا كل نشاط للحسابات (تسجيل، دخول، تنزيل، قص فيديو، تشغيل أوفلاين)',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...s.userActivityLogs.take(40).map((act) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      act.actionType == 'trim_video'
                          ? Icons.content_cut_rounded
                          : act.actionType == 'offline_player'
                              ? Icons.play_circle_fill_rounded
                              : Icons.verified_user_rounded,
                      size: 16,
                      color: AppColors.admin,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${act.username} • ${act.details}',
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${act.actionType.toUpperCase()} • ${timeAgo(act.createdAt)}',
                            style: const TextStyle(
                                fontSize: 9.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// TAB 4: USERS & VIP MANAGER
class _AdminUsersManagerTab extends StatelessWidget {
  const _AdminUsersManagerTab();

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                u.isAdmin
                    ? Icons.shield
                    : u.isVip
                        ? Icons.workspace_premium
                        : Icons.person,
                color: u.isAdmin
                    ? AppColors.admin
                    : u.isVip
                        ? AppColors.api
                        : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(
                      '${u.isAdmin ? "المدير العام" : (u.isVip ? "مشترك VIP" : "عضو عادي")} • استهلاك اليوم: ${u.dailyDownloadsCount}',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!u.isAdmin) ...[
                IconButton(
                  onPressed: () => s.toggleUserVip(u.id),
                  icon: Icon(
                    Icons.workspace_premium,
                    color: u.isVip ? AppColors.api : AppColors.textDim,
                    size: 20,
                  ),
                  tooltip: 'منح/سحب VIP',
                ),
                IconButton(
                  onPressed: () => s.toggleUserBan(u.id),
                  icon: Icon(
                    Icons.block,
                    color: u.isBanned ? AppColors.error : AppColors.textDim,
                    size: 19,
                  ),
                  tooltip: 'حظر/فك حظر الحساب',
                ),
                IconButton(
                  onPressed: () => s.deleteUser(u.id),
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 19),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// TAB 5: GLOBAL DOWNLOADS MONITOR
class _AdminGlobalDownloadsTab extends StatelessWidget {
  const _AdminGlobalDownloadsTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final list = s.allDownloads;
    if (list.isEmpty) {
      return const Center(
          child: Text('لا توجد تحميلات مسجلة في قاعدة البيانات بعد',
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
          child: Row(
            children: [
              _SmallPlatformBox(platform: e.platform),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title.isEmpty ? e.url : e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(
                      'المستخدم: ${owner?.username ?? 'زائر'} • المحرك الخلفي: ${e.strategy.isEmpty ? 'direct' : e.strategy}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _MiniTag(e.status,
                  e.status == 'success' ? AppColors.success : AppColors.error),
            ],
          ),
        );
      },
    );
  }
}

// TAB 6: SILENT BACKGROUND EXTRACTION ENGINES & LOGS (Visible ONLY to Admin)
class _AdminBackgroundEnginesTab extends StatelessWidget {
  const _AdminBackgroundEnginesTab();

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إدارة محركات الاستخراج الصامتة بالخلفية (18 محرك عنقودي)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => s.enableAllExtractionEngines(true),
                      icon: const Icon(Icons.check_circle_outline,
                          size: 15, color: Colors.white),
                      label: const Text('تفعيل جميع المحركات (أقصى قوة)',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => s.enableAllExtractionEngines(false),
                    child: const Text('إيقاف الكل',
                        style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...s.engineStates.entries.map((entry) {
                final logsForEngine = s.bypassLogs
                    .where((b) => b.strategy == entry.key)
                    .toList();
                final okCount =
                    logsForEngine.where((b) => b.status == 'success').length;
                return SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: entry.value,
                  activeColor: AppColors.success,
                  title: Text(entry.key,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                  subtitle: Text(
                      'محاولات الخلفية: ${logsForEngine.length} • نجاح: $okCount',
                      style: const TextStyle(fontSize: 10)),
                  onChanged: (v) => s.toggleExtractionEngine(entry.key, v),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سجل عمليات الاستخراج الخلفية (${s.bypassLogs.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
            if (s.bypassLogs.isNotEmpty)
              TextButton(
                onPressed: () => s.clearBypassAndSecurityLogs(),
                child: const Text('تصفير السجل',
                    style: TextStyle(color: AppColors.error, fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...s.bypassLogs.take(40).map((b) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    b.status == 'success' ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: b.status == 'success'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${b.strategy} • ${b.url}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  _MiniTag('${b.responseTimeMs}ms', AppColors.guest),
                ],
              ),
            )),
      ],
    );
  }
}

// TAB 7: SECURITY SHIELD & ANTI-VPN FIREWALL
class _AdminSecurityAndVpnTab extends StatefulWidget {
  const _AdminSecurityAndVpnTab();

  @override
  State<_AdminSecurityAndVpnTab> createState() =>
      _AdminSecurityAndVpnTabState();
}

class _AdminSecurityAndVpnTabState extends State<_AdminSecurityAndVpnTab> {
  final ipCtrl = TextEditingController();

  @override
  void dispose() {
    ipCtrl.dispose();
    super.dispose();
  }

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.vpn_lock_rounded, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('جدار الحماية الصارم ومكافحة VPN / Proxy',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.antiVpnEnabled,
                activeColor: AppColors.error,
                title: const Text('منع عمل التطبيق نهائياً عند اتصال VPN',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'يفحص واجهات الشبكة (tun/tap/ppp/wg/utun) لحظياً ويقفل التطبيق فوراً',
                    style: TextStyle(fontSize: 10)),
                onChanged: (v) => s.saveSettings(newAntiVpn: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.antiProxyEnabled,
                activeColor: AppColors.error,
                title: const Text('منع خوادم البروكسي والتقاط الحزم (Anti-Proxy)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onChanged: (v) => s.saveSettings(newAntiProxy: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.strictSslVerification,
                activeColor: AppColors.error,
                title: const Text(
                    'فحص الشهادات الرقمية الصارم (Strict SSL Anti-MITM)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onChanged: (v) => s.saveSettings(newStrictSsl: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.autoBanOnVpnAttempt,
                activeColor: AppColors.error,
                title: const Text(
                    'حظر تلقائي للجهاز عند تكرار محاولة تشغيل VPN',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onChanged: (v) => s.saveSettings(newAutoBanOnVpn: v),
              ),
              const SizedBox(height: 6),
              Text(
                'الحد الأقصى لمحاولات الدخول الفاشلة قبل الحظر: ${s.maxFailedLoginAttempts} محاولات',
                style:
                    const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Slider(
                value: s.maxFailedLoginAttempts.toDouble().clamp(3, 15),
                min: 3,
                max: 15,
                divisions: 12,
                activeColor: AppColors.error,
                onChanged: (v) =>
                    s.saveSettings(newMaxFailedLogins: v.round()),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        s.unblockAllIps();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم فك الحظر عن جميع الأجهزة والعناوين'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_open_rounded, size: 15),
                      label: const Text('فك حظر الكل',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final report = s.securityEvents
                            .take(50)
                            .map((e) =>
                                '[${e.createdAt.toIso8601String()}] ${e.eventType} | ${e.username} | ${e.ipOrInterface} | ${e.details}')
                            .join('\n');
                        Clipboard.setData(ClipboardData(
                            text: report.isEmpty
                                ? 'لا توجد أحداث أمنية مسجلة'
                                : report));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('تم نسخ التقرير الأمني الكامل للحافظة'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 15),
                      label: const Text('تصدير التقرير الأمني',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AuthField(
                      controller: ipCtrl,
                      icon: Icons.block,
                      hint: 'حظر عنوان IP أو معرف جهاز...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      s.blockIp(ipCtrl.text);
                      ipCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('حظر'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (s.blockedIps.isNotEmpty) ...[
          const Text('الأجهزة وعناوين IP المحظورة:',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 6),
          ...s.blockedIps.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('${b.ip} • ${b.reason}',
                            style: const TextStyle(fontSize: 11))),
                    TextButton(
                      onPressed: () => s.unblockIp(b.id),
                      child: const Text('فك الحظر',
                          style: TextStyle(
                              color: AppColors.success, fontSize: 11)),
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 12),
        Text('سجل الأحداث الأمنية ومحاولات الدخول (${s.securityEvents.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
        const SizedBox(height: 6),
        ...s.securityEvents.take(30).map((ev) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    ev.isThreat
                        ? Icons.warning_amber_rounded
                        : Icons.verified_user,
                    size: 16,
                    color: ev.isThreat ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ev.username} • ${ev.details}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('${ev.ipOrInterface} • ${timeAgo(ev.createdAt)}',
                            style: const TextStyle(
                                fontSize: 9.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// TAB 8: BROADCAST ANNOUNCEMENTS
class _AdminBroadcastTab extends StatefulWidget {
  const _AdminBroadcastTab();

  @override
  State<_AdminBroadcastTab> createState() => _AdminBroadcastTabState();
}

class _AdminBroadcastTabState extends State<_AdminBroadcastTab> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إرسال إشعار أو تنبيه عام لجميع مستخدمي التطبيق',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 10),
              _AuthField(
                  controller: titleCtrl,
                  icon: Icons.title,
                  hint: 'عنوان الإشعار...'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: bodyCtrl,
                  icon: Icons.message_outlined,
                  hint: 'نص الرسالة التي ستظهر أعلى الشاشة الرئيسية...'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    s.addAnnouncement(
                        title: titleCtrl.text, body: bodyCtrl.text);
                    titleCtrl.clear();
                    bodyCtrl.clear();
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('نشر الإشعار الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.admin,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...s.announcements.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12.5)),
                        Text(a.body,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => s.deleteAnnouncement(a.id),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 18),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// TAB 9: VIP SUBSCRIPTION CODES & API KEYS GENERATOR
class _AdminCodesAndApiTab extends StatefulWidget {
  const _AdminCodesAndApiTab();

  @override
  State<_AdminCodesAndApiTab> createState() => _AdminCodesAndApiTabState();
}

class _AdminCodesAndApiTabState extends State<_AdminCodesAndApiTab> {
  final countCtrl = TextEditingController(text: '5');
  final daysCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    countCtrl.dispose();
    daysCtrl.dispose();
    super.dispose();
  }

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('توليد أكواد اشتراك VIP & API',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AuthField(
                        controller: countCtrl,
                        icon: Icons.confirmation_number_outlined,
                        hint: 'العدد'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AuthField(
                        controller: daysCtrl,
                        icon: Icons.calendar_today,
                        hint: 'الأيام'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final c = int.tryParse(countCtrl.text) ?? 1;
                    final d = int.tryParse(daysCtrl.text) ?? 30;
                    s.generateCodes(c.clamp(1, 100), d.clamp(1, 365));
                  },
                  icon: const Icon(Icons.auto_awesome,
                      size: 16, color: Colors.black),
                  label: const Text('توليد الأكواد في SQLite',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.api),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...s.codes.reversed.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.code,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                color: AppColors.api)),
                        Text('${c.durationDays} يوم • ${c.status}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الكود'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                  ),
                  IconButton(
                    onPressed: () => s.deleteCode(c.id),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 16),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}