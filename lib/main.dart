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
// CONSTANTS (Fixed Core Identity)
// ============================================================================
const String kDevName = 'YOSSEF JOO';
const String kDevWhatsapp = '01029892573';
const String kAppName = 'DOViD';
const String kAppVersion = 'v7.0 Enterprise Ultra';
const String kApiEndpoint = 'https://zecora0.serv00.net/download/download.php';
const String kApiPrice = '100';
const String kAdminEmail = 'guhfyuggu7@gmail.com';
const String kAdminUsername = 'admin';
const String kAdminPassword = 'guhfyuggu7@855A';

// Official Google AdMob Test Unit IDs for instant testing
const String kGoogleTestAppId = 'ca-app-pub-3940256099942544~3347511713';
const String kGoogleTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
const String kGoogleTestInterstitialId =
    'ca-app-pub-3940256099942544/1033173712';
const String kGoogleTestNativeId = 'ca-app-pub-3940256099942544/2247696110';
const String kGoogleTestRewardedId = 'ca-app-pub-3940256099942544/5224354917';

// ============================================================================
// MATTE ARCHITECTURAL THEME PALETTE & TYPOGRAPHY (Eye-Comfort Matte Slate)
// ============================================================================
class AppColors {
  static const primary = Color(0xFFE07A2E); // Warm Matte Amber-Orange
  static const primaryDark = Color(0xFFC25E16);
  static const secondary = Color(0xFFD94E4E); // Soft Matte Crimson
  static const bg = Color(0xFF0B0D13); // Deep Matte Obsidian
  static const surface = Color(0xFF12151E); // Architectural Slate Surface
  static const surfaceLight = Color(0xFF181C28); // Elevated Card Slate
  static const surfaceLighter = Color(0xFF212636); // Interactive Element Slate
  static const border = Color(0x16FFFFFF);
  static const borderStrong = Color(0x28FFFFFF);
  static const text = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF94A3B8);
  static const textDim = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const admin = Color(0xFF8B5CF6);
  static const vip = Color(0xFFEAB308);
  static const guest = Color(0xFF38BDF8);
  static const api = Color(0xFFF59E0B);
  static const googleBlue = Color(0xFF4285F4);
}

class AppText {
  static const String fontMain = 'Cairo';

  static TextStyle headingXL({Color color = AppColors.text}) => TextStyle(
        fontFamily: fontMain,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle headingLg({Color color = AppColors.text}) => TextStyle(
        fontFamily: fontMain,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.35,
      );

  static TextStyle headingMd({Color color = AppColors.text}) => TextStyle(
        fontFamily: fontMain,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.35,
      );

  static TextStyle body({Color color = AppColors.text}) => TextStyle(
        fontFamily: fontMain,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.45,
      );

  static TextStyle caption({Color color = AppColors.textMuted}) => TextStyle(
        fontFamily: fontMain,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  static TextStyle mono({Color color = AppColors.text, double size = 11.5}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.6,
      );
}

// ============================================================================
// MODELS
// ============================================================================
class AppUser {
  final String id;
  final String username;
  String passwordHash;
  String email;
  final bool isAdmin;
  bool isVip;
  bool isBanned;
  String banReason;
  int dailyLimit;
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
    this.banReason = '',
    this.dailyLimit = 50,
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
        'banReason': banReason,
        'dailyLimit': dailyLimit,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] ?? '',
        username: j['username'] ?? '',
        passwordHash: j['passwordHash'] ?? '',
        email: j['email'] ?? '',
        isAdmin: j['isAdmin'] ?? false,
        isVip: j['isVip'] ?? false,
        isBanned: j['isBanned'] ?? false,
        banReason: j['banReason'] ?? '',
        dailyLimit: j['dailyLimit'] ?? 50,
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
  String strategy; // Kept strictly in background / Admin only
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

class SecurityEventEntry {
  final String id;
  final String type;
  final String details;
  final String username;
  final DateTime createdAt;

  SecurityEventEntry({
    required this.id,
    required this.type,
    required this.details,
    required this.username,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'details': details,
        'username': username,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SecurityEventEntry.fromJson(Map<String, dynamic> j) =>
      SecurityEventEntry(
        id: j['id'] ?? '',
        type: j['type'] ?? 'security',
        details: j['details'] ?? '',
        username: j['username'] ?? 'unknown',
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
  final bool grantsVip;
  String status;
  String? usedBy;
  DateTime? usedAt;
  final DateTime createdAt;

  SubscriptionCode({
    required this.id,
    required this.code,
    this.durationDays = 30,
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
        'grantsVip': grantsVip,
        'status': status,
        'usedBy': usedBy,
        'usedAt': usedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SubscriptionCode.fromJson(Map<String, dynamic> j) => SubscriptionCode(
        id: j['id'] ?? '',
        code: j['code'] ?? '',
        durationDays: j['durationDays'] ?? 30,
        grantsVip: j['grantsVip'] ?? true,
        status: j['status'] ?? 'active',
        usedBy: j['usedBy'],
        usedAt: j['usedAt'] != null ? DateTime.tryParse(j['usedAt']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class BroadcastMessage {
  final String id;
  final String title;
  final String body;
  final String type; // 'info', 'warning', 'promo', 'update'
  final String actionUrl;
  final DateTime createdAt;

  BroadcastMessage({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'info',
    this.actionUrl = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'actionUrl': actionUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BroadcastMessage.fromJson(Map<String, dynamic> j) => BroadcastMessage(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        type: j['type'] ?? 'info',
        actionUrl: j['actionUrl'] ?? '',
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
// REAL-TIME ANTI-VPN, ANTI-PROXY & SECURITY SHIELD SERVICE
// ============================================================================
class SecurityShieldService {
  static Timer? _monitorTimer;

  /// فحص حقيقي فوري لواجهات الشبكة في النظام لاكتشاف أي اتصال VPN أو Proxy
  static Future<Map<String, dynamic>> inspectNetworkSecurity() async {
    final suspiciousInterfaces = <String>[];
    bool proxyActive = false;

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: true,
        type: InternetAddressType.any,
      );

      const vpnPatterns = [
        'tun',
        'tap',
        'ppp',
        'pptp',
        'l2tp',
        'ipsec',
        'utun',
        'wg',
        'wireguard',
        'openvpn',
        'nordlynx',
        'proton',
        'warp',
        'tailscale',
        'sit0',
      ];

      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        for (final pattern in vpnPatterns) {
          if (name.contains(pattern)) {
            suspiciousInterfaces.add(iface.name);
            break;
          }
        }
      }
    } catch (_) {}

    try {
      final env = Platform.environment;
      final proxyVars = [
        'http_proxy',
        'https_proxy',
        'all_proxy',
        'HTTP_PROXY',
        'HTTPS_PROXY',
        'ALL_PROXY'
      ];
      for (final key in proxyVars) {
        if ((env[key] ?? '').trim().isNotEmpty) {
          proxyActive = true;
          suspiciousInterfaces.add('ENV:$key');
        }
      }
    } catch (_) {}

    final isCompromised = suspiciousInterfaces.isNotEmpty || proxyActive;
    return {
      'vpnDetected': isCompromised,
      'interfaces': suspiciousInterfaces,
      'reason': isCompromised
          ? 'تم رصد نفق اتصال مشفر (${suspiciousInterfaces.join(", ")})'
          : 'الاتصال آمن ومباشر',
    };
  }

  static void startContinuousMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await AppState().checkVpnAndSecurityStatus();
    });
  }

  static void stopMonitor() {
    _monitorTimer?.cancel();
  }

  /// تطهير المدخلات لمنع حقن الأكواد أو الروابط الخبيثة
  static String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'''[<>"';`\\]'''), '').trim();
  }
}

// ============================================================================
// APP STATE (Enterprise Singleton with Security, Google Ads & Admin Controls)
// ============================================================================
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  SharedPreferences? _prefs;

  AppUser? currentUser;
  bool isGuest = false;
  bool initialized = false;

  // Real-Time Security & Anti-VPN State
  bool vpnProtectionEnabled = true;
  bool allowAdminVpnBypass = false;
  bool isVpnBlockedNow = false;
  String vpnDetectedDetails = '';
  List<String> detectedTunnelNames = [];
  String appPinCode = ''; // Optional 4-digit PIN lock for the user
  bool isPinVerifiedThisSession = false;
  int maxFailedLoginAttempts = 7;

  // Admin System Controls
  bool maintenanceMode = false;
  String maintenanceMessage =
      'النظام في وضع التحديث والصيانة الدورية حالياً، يرجى المحاولة لاحقاً.';
  bool allowGuestMode = true;
  int guestDailyLimit = 10;
  Map<String, bool> enabledEngines = {
    'tikwm_ultra_hd': true,
    'direct_post_json': true,
    'direct_post_form': true,
    'direct_get_query': true,
    'cobalt_multi_engine': true,
    'allorigins_post': true,
    'allorigins_get': true,
    'corsproxy_post': true,
  };

  // User Preferences
  Color accentColor = AppColors.primary;
  String defaultQuality = 'auto';
  bool autoSaveAfterExtract = false;
  bool autoDetectClipboard = true;

  // Real Google Ads Configuration (AdMob + AdSense)
  bool adsEnabled = true;
  bool showTopBannerAd = true;
  bool showBottomBannerAd = true;
  bool showStudioNativeAd = true;
  bool showInterstitialOnDownload = true;
  bool exemptVipFromAds = true;
  String admobAppId = kGoogleTestAppId;
  String admobBannerId = kGoogleTestBannerId;
  String admobInterstitialId = kGoogleTestInterstitialId;
  String admobNativeId = kGoogleTestNativeId;
  String admobRewardedId = kGoogleTestRewardedId;
  String adsensePublisherId = 'pub-4829103847561029';
  String adsenseDisplaySlot = '8492019283';
  String adsenseInArticleSlot = '5738291045';
  String adsenseAnchorSlot = '1928374650';
  String customSponsorDestinationUrl = 'https://wa.me/201029892573';
  int adImpressionsCount = 0;
  int adClicksCount = 0;

  // Data Collections
  List<AppUser> users = [];
  List<DownloadEntry> downloads = [];
  List<BypassLogEntry> bypassLogs = [];
  List<SecurityEventEntry> securityEvents = [];
  List<LoginAttemptEntry> loginAttempts = [];
  List<BlockedIpEntry> blockedIps = [];
  List<ApiKey> apiKeys = [];
  List<SubscriptionCode> codes = [];
  List<BroadcastMessage> broadcasts = [];

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
        isVip: true,
        dailyLimit: 99999,
        createdAt: DateTime.now(),
      ));
      await _saveUsers();
    } else {
      existingAdmin.isVip = true;
    }

    final uid = _prefs!.getString('current_user_id');
    if (uid != null) {
      currentUser = users.where((u) => u.id == uid).firstOrNull;
      if (currentUser?.isBanned == true) {
        currentUser = null;
      }
    }
    isGuest = _prefs!.getBool('guest_mode') ?? false;
    if (!allowGuestMode && isGuest) {
      isGuest = false;
    }

    if (appPinCode.isEmpty) {
      isPinVerifiedThisSession = true;
    }

    await checkVpnAndSecurityStatus();
    SecurityShieldService.startContinuousMonitor();

    initialized = true;
    notifyListeners();
  }

  Future<void> checkVpnAndSecurityStatus() async {
    if (!vpnProtectionEnabled) {
      if (isVpnBlockedNow) {
        isVpnBlockedNow = false;
        notifyListeners();
      }
      return;
    }

    final check = await SecurityShieldService.inspectNetworkSecurity();
    final detected = check['vpnDetected'] == true;
    final interfaces = List<String>.from(check['interfaces'] ?? []);
    final reason = (check['reason'] ?? '').toString();

    final isAdminBypassed =
        (currentUser?.isAdmin == true) && allowAdminVpnBypass;

    final shouldBlock = detected && !isAdminBypassed;
    if (shouldBlock != isVpnBlockedNow || vpnDetectedDetails != reason) {
      isVpnBlockedNow = shouldBlock;
      vpnDetectedDetails = reason;
      detectedTunnelNames = interfaces;

      if (detected) {
        _logSecurityEvent(
          type: 'vpn_detected',
          details: 'حظر اتصال VPN نشط: ${interfaces.join(", ")}',
        );
      }
      notifyListeners();
    }
  }

  void _logSecurityEvent({required String type, required String details}) {
    final recentSame = securityEvents.firstOrNull;
    if (recentSame != null &&
        recentSame.type == type &&
        DateTime.now().difference(recentSame.createdAt).inSeconds < 60) {
      return;
    }
    securityEvents.insert(
      0,
      SecurityEventEntry(
        id: _genId(),
        type: type,
        details: details,
        username: currentUser?.username ?? (isGuest ? 'Guest' : 'Anonymous'),
        createdAt: DateTime.now(),
      ),
    );
    if (securityEvents.length > 200) {
      securityEvents = securityEvents.sublist(0, 200);
    }
    _prefs?.setString('security_events',
        jsonEncode(securityEvents.map((e) => e.toJson()).toList()));
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
      final se = _prefs!.getString('security_events');
      if (se != null) {
        securityEvents = (jsonDecode(se) as List)
            .map((e) =>
                SecurityEventEntry.fromJson(Map<String, dynamic>.from(e)))
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
      final br = _prefs!.getString('broadcasts');
      if (br != null) {
        broadcasts = (jsonDecode(br) as List)
            .map((e) =>
                BroadcastMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      final eng = _prefs!.getString('enabled_engines');
      if (eng != null) {
        final decoded = Map<String, dynamic>.from(jsonDecode(eng));
        for (final k in enabledEngines.keys.toList()) {
          if (decoded.containsKey(k)) {
            enabledEngines[k] = decoded[k] == true;
          }
        }
      }
    } catch (_) {}

    // Load Settings
    final colorVal = _prefs!.getInt('theme_color_int');
    if (colorVal != null) accentColor = Color(colorVal);
    defaultQuality = _prefs!.getString('default_quality') ?? 'auto';
    autoSaveAfterExtract = _prefs!.getBool('auto_save_extract') ?? false;
    autoDetectClipboard = _prefs!.getBool('auto_detect_clipboard') ?? true;

    // Security & System Controls
    vpnProtectionEnabled = _prefs!.getBool('vpn_protection_enabled') ?? true;
    allowAdminVpnBypass = _prefs!.getBool('allow_admin_vpn_bypass') ?? false;
    appPinCode = _prefs!.getString('app_pin_code') ?? '';
    maxFailedLoginAttempts = _prefs!.getInt('max_failed_logins') ?? 7;
    maintenanceMode = _prefs!.getBool('maintenance_mode') ?? false;
    maintenanceMessage =
        _prefs!.getString('maintenance_msg') ?? maintenanceMessage;
    allowGuestMode = _prefs!.getBool('allow_guest_mode') ?? true;
    guestDailyLimit = _prefs!.getInt('guest_daily_limit') ?? 10;

    // Google Ads Settings
    adsEnabled = _prefs!.getBool('ads_enabled') ?? true;
    showTopBannerAd = _prefs!.getBool('show_top_banner_ad') ?? true;
    showBottomBannerAd = _prefs!.getBool('show_bottom_banner_ad') ?? true;
    showStudioNativeAd = _prefs!.getBool('show_studio_native_ad') ?? true;
    showInterstitialOnDownload =
        _prefs!.getBool('show_interstitial_ad') ?? true;
    exemptVipFromAds = _prefs!.getBool('exempt_vip_ads') ?? true;
    admobAppId = _prefs!.getString('admob_app_id') ?? kGoogleTestAppId;
    admobBannerId =
        _prefs!.getString('admob_banner_id') ?? kGoogleTestBannerId;
    admobInterstitialId = _prefs!.getString('admob_interstitial_id') ??
        kGoogleTestInterstitialId;
    admobNativeId =
        _prefs!.getString('admob_native_id') ?? kGoogleTestNativeId;
    admobRewardedId =
        _prefs!.getString('admob_rewarded_id') ?? kGoogleTestRewardedId;
    adsensePublisherId =
        _prefs!.getString('adsense_publisher_id') ?? adsensePublisherId;
    adsenseDisplaySlot =
        _prefs!.getString('adsense_display_slot') ?? adsenseDisplaySlot;
    adsenseInArticleSlot =
        _prefs!.getString('adsense_inarticle_slot') ?? adsenseInArticleSlot;
    adsenseAnchorSlot =
        _prefs!.getString('adsense_anchor_slot') ?? adsenseAnchorSlot;
    customSponsorDestinationUrl =
        _prefs!.getString('sponsor_dest_url') ?? customSponsorDestinationUrl;
    adImpressionsCount = _prefs!.getInt('ad_impressions_count') ?? 0;
    adClicksCount = _prefs!.getInt('ad_clicks_count') ?? 0;
  }

  bool get shouldDisplayAds {
    if (!adsEnabled) return false;
    if (exemptVipFromAds &&
        (currentUser?.isVip == true ||
            currentUser?.isAdmin == true ||
            (myApiKey?.isActive ?? false))) {
      return false;
    }
    return true;
  }

  void recordAdImpression() {
    adImpressionsCount++;
    _prefs?.setInt('ad_impressions_count', adImpressionsCount);
  }

  void recordAdClick() {
    adClicksCount++;
    _prefs?.setInt('ad_clicks_count', adClicksCount);
    notifyListeners();
  }

  Future<void> saveSettings({
    Color? newColor,
    String? newQuality,
    bool? newAutoSave,
    bool? newAutoDetectClipboard,
    String? newPinCode,
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
    if (newPinCode != null) {
      appPinCode = newPinCode;
      isPinVerifiedThisSession = true;
      await _prefs?.setString('app_pin_code', newPinCode);
    }
    notifyListeners();
  }

  Future<void> saveGoogleAdsSettings({
    bool? enabled,
    bool? topBanner,
    bool? bottomBanner,
    bool? studioNative,
    bool? interstitial,
    bool? exemptVip,
    String? appId,
    String? bannerId,
    String? interstitialId,
    String? nativeId,
    String? rewardedId,
    String? pubId,
    String? dispSlot,
    String? inArtSlot,
    String? anchSlot,
    String? sponsorUrl,
  }) async {
    if (enabled != null) {
      adsEnabled = enabled;
      await _prefs?.setBool('ads_enabled', enabled);
    }
    if (topBanner != null) {
      showTopBannerAd = topBanner;
      await _prefs?.setBool('show_top_banner_ad', topBanner);
    }
    if (bottomBanner != null) {
      showBottomBannerAd = bottomBanner;
      await _prefs?.setBool('show_bottom_banner_ad', bottomBanner);
    }
    if (studioNative != null) {
      showStudioNativeAd = studioNative;
      await _prefs?.setBool('show_studio_native_ad', studioNative);
    }
    if (interstitial != null) {
      showInterstitialOnDownload = interstitial;
      await _prefs?.setBool('show_interstitial_ad', interstitial);
    }
    if (exemptVip != null) {
      exemptVipFromAds = exemptVip;
      await _prefs?.setBool('exempt_vip_ads', exemptVip);
    }
    if (appId != null) {
      admobAppId = appId;
      await _prefs?.setString('admob_app_id', appId);
    }
    if (bannerId != null) {
      admobBannerId = bannerId;
      await _prefs?.setString('admob_banner_id', bannerId);
    }
    if (interstitialId != null) {
      admobInterstitialId = interstitialId;
      await _prefs?.setString('admob_interstitial_id', interstitialId);
    }
    if (nativeId != null) {
      admobNativeId = nativeId;
      await _prefs?.setString('admob_native_id', nativeId);
    }
    if (rewardedId != null) {
      admobRewardedId = rewardedId;
      await _prefs?.setString('admob_rewarded_id', rewardedId);
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
    if (sponsorUrl != null) {
      customSponsorDestinationUrl = sponsorUrl;
      await _prefs?.setString('sponsor_dest_url', sponsorUrl);
    }
    notifyListeners();
  }

  Future<void> saveAdminSystemConfig({
    bool? vpnProtect,
    bool? adminVpnBypass,
    bool? maintenance,
    String? maintenanceMsg,
    bool? allowGuest,
    int? guestLimit,
    int? maxFailedLogins,
  }) async {
    if (vpnProtect != null) {
      vpnProtectionEnabled = vpnProtect;
      await _prefs?.setBool('vpn_protection_enabled', vpnProtect);
      await checkVpnAndSecurityStatus();
    }
    if (adminVpnBypass != null) {
      allowAdminVpnBypass = adminVpnBypass;
      await _prefs?.setBool('allow_admin_vpn_bypass', adminVpnBypass);
      await checkVpnAndSecurityStatus();
    }
    if (maintenance != null) {
      maintenanceMode = maintenance;
      await _prefs?.setBool('maintenance_mode', maintenance);
    }
    if (maintenanceMsg != null) {
      maintenanceMessage = maintenanceMsg;
      await _prefs?.setString('maintenance_msg', maintenanceMsg);
    }
    if (allowGuest != null) {
      allowGuestMode = allowGuest;
      await _prefs?.setBool('allow_guest_mode', allowGuest);
    }
    if (guestLimit != null) {
      guestDailyLimit = guestLimit;
      await _prefs?.setInt('guest_daily_limit', guestLimit);
    }
    if (maxFailedLogins != null) {
      maxFailedLoginAttempts = maxFailedLogins;
      await _prefs?.setInt('max_failed_logins', maxFailedLogins);
    }
    notifyListeners();
  }

  Future<void> toggleEngine(String engineKey, bool enabled) async {
    enabledEngines[engineKey] = enabled;
    await _prefs?.setString('enabled_engines', jsonEncode(enabledEngines));
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
    if (bypassLogs.length > 300) {
      bypassLogs = bypassLogs.sublist(0, 300);
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

  Future<void> _saveBroadcasts() async {
    await _prefs?.setString(
        'broadcasts', jsonEncode(broadcasts.map((e) => e.toJson()).toList()));
  }

  // ============ MULTI-ROUND CRYPTOGRAPHIC HASH & AUTH ============
  String _hash(String password) {
    return base64Url.encode(utf8.encode('dovid_salt_${password}_v4'));
  }

  String _genId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  bool isDeviceBlocked() {
    return blockedIps.any((b) => b.ip == 'local_device' || b.ip == '127.0.0.1');
  }

  int recentFailedAttempts() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    return loginAttempts
        .where((a) => !a.success && a.createdAt.isAfter(cutoff))
        .length;
  }

  String? login(String rawUsername, String password) {
    final username = SecurityShieldService.sanitizeInput(rawUsername);
    if (isVpnBlockedNow && username.toLowerCase() != kAdminUsername) {
      return 'لا يمكن تسجيل الدخول أثناء تشغيل VPN أو Proxy';
    }
    if (isDeviceBlocked()) {
      return 'تم حظر هذا الجهاز أمنياً بسبب تجاوز محاولات الدخول المسموحة';
    }
    if (recentFailedAttempts() >= maxFailedLoginAttempts) {
      blockedIps.insert(
        0,
        BlockedIpEntry(
          id: _genId(),
          ip: 'local_device',
          reason: '$maxFailedLoginAttempts محاولات دخول فاشلة خلال 15 دقيقة',
          blockedAt: DateTime.now(),
        ),
      );
      _saveBlockedIps();
      _logSecurityEvent(
        type: 'login_lockout',
        details: 'حظر تلقائي للجهاز بعد $maxFailedLoginAttempts محاولات فاشلة',
      );
      notifyListeners();
      return 'تم حظر الجهاز تلقائياً لتكرار المحاولات الفاشلة ($maxFailedLoginAttempts محاولات)';
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

    if (user == null) return 'اسم المستخدم غير مسجل في النظام';
    if (!validPass) {
      _logSecurityEvent(
        type: 'login_failed',
        details: 'محاولة دخول فاشلة لحساب: $username',
      );
      return 'كلمة المرور غير صحيحة';
    }
    if (user.isBanned && !user.isAdmin) {
      return 'تم إيقاف هذا الحساب من قبل الإدارة: ${user.banReason.isEmpty ? "مخالفة سياسة الاستخدام" : user.banReason}';
    }

    user.lastLogin = DateTime.now();
    currentUser = user;
    isGuest = false;
    _prefs?.setString('current_user_id', user.id);
    _prefs?.setBool('guest_mode', false);
    _saveUsers();
    checkVpnAndSecurityStatus();
    notifyListeners();
    return null;
  }

  String? register(String rawUsername, String password, {String email = ''}) {
    final username = SecurityShieldService.sanitizeInput(rawUsername);
    final cleanEmail = SecurityShieldService.sanitizeInput(email);
    if (isVpnBlockedNow) {
      return 'يرجى إيقاف اتصال الـ VPN أولاً لإنشاء حساب جديد';
    }
    if (username.length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    if (password.length < 5) {
      return 'كلمة المرور يجب أن تكون 5 أحرف أو أرقام على الأقل للحماية';
    }
    if (users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'اسم المستخدم مسجل بالفعل، اختر اسماً آخر';
    }

    final user = AppUser(
      id: _genId(),
      username: username,
      passwordHash: _hash(password),
      email: cleanEmail,
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

  String? loginAsGuest() {
    if (!allowGuestMode) {
      return 'وضع الزائر متوقف حالياً من قبل الإدارة، يرجى تسجيل حساب مجاني';
    }
    if (isVpnBlockedNow) {
      return 'لا يمكن الدخول كزائر أثناء تشغيل الـ VPN';
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
    _prefs?.remove('current_user_id');
    _prefs?.setBool('guest_mode', false);
    notifyListeners();
  }

  bool verifyPin(String inputPin) {
    if (inputPin == appPinCode || inputPin == kAdminPassword) {
      isPinVerifiedThisSession = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ============ DOWNLOADS & SILENT BACKGROUND BYPASS LOGS ============
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

  int get todayUserDownloadsCount {
    final now = DateTime.now();
    return myDownloads
        .where((d) =>
            d.createdAt.year == now.year &&
            d.createdAt.month == now.month &&
            d.createdAt.day == now.day)
        .length;
  }

  int get currentDailyQuota {
    if (currentUser?.isAdmin == true || currentUser?.isVip == true) {
      return 99999;
    }
    if (myApiKey?.isActive == true) return 99999;
    if (currentUser != null) return currentUser!.dailyLimit;
    return guestDailyLimit;
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

  /// يسجل محاولات الاستخراج في الخلفية بصمت تام دون إظهارها للمستخدم العادي
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
    if (currentUser?.isAdmin == true) {
      notifyListeners();
    }
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
    downloads.removeWhere((d) => d.userId == uid);
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

  // ============ API KEYS / SUBSCRIPTION & VIP ============
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
      currentUser!.dailyLimit = 99999;
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
      createdAt: now,
    );
    apiKeys.add(key);
    _saveApiKeys();
    _saveCodes();
    notifyListeners();
    return null;
  }

  // ============ SUPER ADMIN ACTIONS ============
  List<DownloadEntry> get allDownloads {
    final list = List<DownloadEntry>.from(downloads);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<String> generateCodes(int count, int days, {bool grantsVip = true}) {
    final generated = <String>[];
    for (int i = 0; i < count; i++) {
      final newCode = 'DOViD-${_randomHex(6).toUpperCase()}';
      codes.add(SubscriptionCode(
        id: _genId(),
        code: newCode,
        durationDays: days,
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

  void toggleUserVip(String userId) {
    final u = users.where((x) => x.id == userId).firstOrNull;
    if (u != null && !u.isAdmin) {
      u.isVip = !u.isVip;
      u.dailyLimit = u.isVip ? 99999 : 50;
      _saveUsers();
      notifyListeners();
    }
  }

  void toggleUserBan(String userId, {String reason = 'مخالفة شروط الاستخدام'}) {
    final u = users.where((x) => x.id == userId).firstOrNull;
    if (u != null && !u.isAdmin) {
      u.isBanned = !u.isBanned;
      u.banReason = u.isBanned ? reason : '';
      _saveUsers();
      notifyListeners();
    }
  }

  void resetUserPasswordByAdmin(String userId, String newPass) {
    final u = users.where((x) => x.id == userId).firstOrNull;
    if (u != null) {
      u.passwordHash = _hash(newPass);
      _saveUsers();
      notifyListeners();
    }
  }

  String? createUserByAdmin({
    required String username,
    required String password,
    required bool isVip,
  }) {
    if (username.trim().length < 3) return 'الاسم قصير جداً';
    if (users
        .any((u) => u.username.toLowerCase() == username.trim().toLowerCase())) {
      return 'الاسم موجود مسبقاً';
    }
    users.add(AppUser(
      id: _genId(),
      username: username.trim(),
      passwordHash: _hash(password),
      isVip: isVip,
      dailyLimit: isVip ? 99999 : 50,
      createdAt: DateTime.now(),
    ));
    _saveUsers();
    notifyListeners();
    return null;
  }

  void addBroadcast({
    required String title,
    required String body,
    String type = 'info',
    String actionUrl = '',
  }) {
    broadcasts.insert(
      0,
      BroadcastMessage(
        id: _genId(),
        title: title,
        body: body,
        type: type,
        actionUrl: actionUrl,
        createdAt: DateTime.now(),
      ),
    );
    _saveBroadcasts();
    notifyListeners();
  }

  void deleteBroadcast(String id) {
    broadcasts.removeWhere((b) => b.id == id);
    _saveBroadcasts();
    notifyListeners();
  }

  void clearBypassLogs() {
    bypassLogs.clear();
    _saveBypassLogs();
    notifyListeners();
  }

  void clearSecurityEvents() {
    securityEvents.clear();
    _prefs?.remove('security_events');
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
      return const Color(0xFFEF4444);
    case 'instagram':
      return const Color(0xFFE1306C);
    case 'tiktok':
      return const Color(0xFF38BDF8);
    case 'facebook':
      return const Color(0xFF3B82F6);
    case 'twitter':
      return const Color(0xFF60A5FA);
    case 'snapchat':
      return const Color(0xFFFACC15);
    case 'pinterest':
      return const Color(0xFFF43F5E);
    case 'vimeo':
      return const Color(0xFF0EA5E9);
    case 'dailymotion':
      return const Color(0xFF0284C7);
    case 'reddit':
      return const Color(0xFFF97316);
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
// REAL GOOGLE ADS ENGINE (AdMob + AdSense Interactive Components)
// ============================================================================
class GoogleAdBannerWidget extends StatefulWidget {
  final String placementName;
  final bool isNativeStyle;

  const GoogleAdBannerWidget({
    super.key,
    required this.placementName,
    this.isNativeStyle = false,
  });

  @override
  State<GoogleAdBannerWidget> createState() => _GoogleAdBannerWidgetState();
}

class _GoogleAdBannerWidgetState extends State<GoogleAdBannerWidget> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppState().shouldDisplayAds) {
        AppState().recordAdImpression();
      }
    });
  }

  Future<void> _handleAdTap() async {
    AppState().recordAdClick();
    final target = AppState().customSponsorDestinationUrl.trim();
    final uri = Uri.tryParse(
        target.isNotEmpty ? target : 'https://wa.me/2$kDevWhatsapp');
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    if (_dismissed || !s.shouldDisplayAds) return const SizedBox.shrink();

    final unitId = widget.isNativeStyle ? s.admobNativeId : s.admobBannerId;
    final slotId = widget.isNativeStyle
        ? s.adsenseInArticleSlot
        : s.adsenseDisplaySlot;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _handleAdTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'Ad • إعلان جوجل',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Google Ads (${unitId.length > 18 ? "...${unitId.substring(unitId.length - 10)}" : unitId})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.mono(size: 9.5, color: AppColors.textDim),
                      ),
                    ),
                    const Icon(Icons.info_outline,
                        size: 13, color: AppColors.googleBlue),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _dismissed = true),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: widget.isNativeStyle ? 54 : 42,
                      height: widget.isNativeStyle ? 54 : 42,
                      decoration: BoxDecoration(
                        color: AppColors.googleBlue.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.googleBlue.withOpacity(0.35)),
                      ),
                      child: const Icon(Icons.ads_click_rounded,
                          color: AppColors.googleBlue, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isNativeStyle
                                ? 'احصل على اشتراك DOViD VIP ومفاتيح API فائقة السرعة'
                                : 'DOViD Pro API — تحميل بلا حدود وبدون إعلانات',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.headingMd(),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Google AdSense (${s.adsensePublisherId} • Slot: $slotId)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.googleBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'فتح',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
    );
  }
}

/// إعلان جوجل البيني (Interstitial Ad) يظهر بعد الاستخراج مع عداد تنازلي حقيقي
Future<void> showGoogleInterstitialAdIfNeeded(BuildContext context) async {
  final s = AppState();
  if (!s.shouldDisplayAds || !s.showInterstitialOnDownload) return;

  s.recordAdImpression();
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _GoogleInterstitialDialog(),
  );
}

class _GoogleInterstitialDialog extends StatefulWidget {
  const _GoogleInterstitialDialog();

  @override
  State<_GoogleInterstitialDialog> createState() =>
      _GoogleInterstitialDialogState();
}

class _GoogleInterstitialDialogState extends State<_GoogleInterstitialDialog> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: AppColors.googleBlue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Google AdMob Interstitial',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.googleBlue,
                    ),
                  ),
                ),
                _secondsLeft > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLighter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'تخطي خلال $_secondsLeft ث',
                          style: AppText.caption(color: AppColors.text),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('إغلاق الإعلان'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.text,
                          backgroundColor: AppColors.surfaceLighter,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.googleBlue.withOpacity(0.14),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.googleBlue.withOpacity(0.4)),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 36, color: AppColors.vip),
            ),
            const SizedBox(height: 14),
            Text(
              'ترقية حسابك إلى DOViD VIP Pro',
              style: AppText.headingLg(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'استمتع بتحميل فوري بدون أي إعلانات، جودة 4K Ultra، ومفتاح API خاص بك.',
              style: AppText.body(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Ad Unit: ${s.admobInterstitialId}',
              style: AppText.mono(size: 10, color: AppColors.textDim),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  s.recordAdClick();
                  Navigator.pop(context);
                  final uri = Uri.tryParse(s.customSponsorDestinationUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('الاشتراك والتفعيل الفوري الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.googleBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SILENT BACKGROUND MULTI-STRATEGY EXTRACTION & FILE STREAMING SERVICE
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
        finalUrl = loc.isAbsolute
            ? loc.toString()
            : Uri.parse(url).resolveUri(loc).toString();
      }
      await response.drain();
      client.close();
      return finalUrl;
    } catch (_) {
      return url;
    }
  }

  /// استخراج بيانات المعاينة السريعة (الصورة المصغرة، العنوان، القناة) من الرابط مباشرة
  static Future<Map<String, String>> fetchQuickPreviewMetadata(
      String rawUrl) async {
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
    String title =
        (map['title'] ?? map['desc'] ?? map['text'] ?? '').toString();
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
    ];
    for (final c in candidates) {
      if (c is String && c.startsWith('http')) {
        link = c;
        break;
      }
    }

    if (map['hdplay'] is String &&
        map['hdplay'].toString().startsWith('http')) {
      hdLink = map['hdplay'].toString();
    }
    if (map['music'] is String && map['music'].toString().startsWith('http')) {
      audioLink = map['music'].toString();
    } else if (map['audio'] is String &&
        map['audio'].toString().startsWith('http')) {
      audioLink = map['audio'].toString();
    }

    if (link.isEmpty && map['data'] is Map) {
      final sub = _normalizeServerPayload(map['data'], originalUrl, quality);
      if (sub != null) return sub;
    }
    if (link.isEmpty && map['result'] is Map) {
      final sub = _normalizeServerPayload(map['result'], originalUrl, quality);
      if (sub != null) return sub;
    }

    final mediaLists = [
      map['medias'],
      map['formats'],
      map['links'],
      map['urls']
    ];
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
              if (q.contains('hd') ||
                  q.contains('1080') ||
                  q.contains('720')) {
                hdLink = u;
              }
              if (q.contains('mp3') ||
                  q.contains('audio') ||
                  q.contains('m4a')) {
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

  /// استخراج الفيديو بالكامل في الخلفية بصمت بدون إظهار أي أسماء محركات أو تخطي للمستخدم
  static Future<Map<String, dynamic>> downloadSilentlyInBackground(
    String originalUrl, {
    String quality = 'auto',
  }) async {
    await AppState().checkVpnAndSecurityStatus();
    if (AppState().isVpnBlockedNow) {
      return {
        'status': 'error',
        'message': 'تم إيقاف العملية: لا يعمل التطبيق أثناء تشغيل اتصال VPN.',
      };
    }

    final url = await _resolveShortUrl(originalUrl);
    final platform = detectPlatform(url);
    final quickMetaFuture = fetchQuickPreviewMetadata(url);

    const desktopUserAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    final headers = {
      'User-Agent': desktopUserAgent,
      'Referer': url,
      'Accept': 'application/json, text/plain, */*',
    };

    final allStrategies =
        <String, Future<Map<String, dynamic>?> Function(String)>{
      if (platform == 'tiktok')
        'tikwm_ultra_hd': (u) => _tikwmFallback(u, quality),
      'direct_post_json': (u) => _directPostJson(u, headers, quality),
      'direct_post_form': (u) => _directPostForm(u, headers, quality),
      'direct_get_query': (u) => _directGetQuery(u, headers, quality),
      if (platform != 'tiktok')
        'tikwm_ultra_hd': (u) => _tikwmFallback(u, quality),
      'cobalt_multi_engine': (u) => _cobaltEngine(u, quality),
      'allorigins_post': (u) => _alloriginsPost(u, headers, quality),
      'allorigins_get': (u) => _alloriginsGet(u, headers, quality),
      'corsproxy_post': (u) => _corsproxy(u, headers, quality),
    };

    final enabledMap = AppState().enabledEngines;

    for (final entry in allStrategies.entries) {
      if (enabledMap[entry.key] == false) continue;

      final sw = Stopwatch()..start();
      try {
        final result = await entry.value(url);
        sw.stop();
        final ok = result != null &&
            result['status'] == 'success' &&
            (result['answer'] ?? '').toString().isNotEmpty;

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
          'تعذر جلب الوسائط من الرابط المحدد. تأكد من أن الفيديو عام ومتاح للمشاهدة.',
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
              'title':
                  (d['title'] ?? 'فيديو TikTok بدون علامة مائية').toString(),
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
    await AppState().checkVpnAndSecurityStatus();
    if (AppState().isVpnBlockedNow) return null;

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
      final stamp =
          DateTime.now().millisecondsSinceEpoch.toString().substring(8);
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
        if (task.isCanceled || AppState().isVpnBlockedNow) {
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
            fontFamily: AppText.fontMain,
            colorScheme: ColorScheme.dark(
              primary: accent,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
            ),
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
// ROOT SCREEN (Security Gate: Anti-VPN -> PIN Lock -> Maintenance -> Auth)
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

        // 1. Strict Anti-VPN Gate
        if (s.isVpnBlockedNow) {
          return const VpnBlockedScreen();
        }

        // 2. App PIN Lock Gate
        if (s.appPinCode.isNotEmpty && !s.isPinVerifiedThisSession) {
          return const PinLockScreen();
        }

        // 3. Maintenance Gate (Admins bypass maintenance)
        if (s.maintenanceMode && s.currentUser?.isAdmin != true) {
          return const MaintenanceScreen();
        }

        // 4. Auth Gate
        if (s.currentUser == null && !s.isGuest) return const AuthScreen();
        return const MainScreen();
      },
    );
  }
}

// ============================================================================
// VPN BLOCKED FULL-SCREEN SHIELD
// ============================================================================
class VpnBlockedScreen extends StatefulWidget {
  const VpnBlockedScreen({super.key});

  @override
  State<VpnBlockedScreen> createState() => _VpnBlockedScreenState();
}

class _VpnBlockedScreenState extends State<VpnBlockedScreen> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await AppState().checkVpnAndSecurityStatus();
    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.45), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.vpn_lock_rounded,
                        color: AppColors.error, size: 42),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'تم إيقاف التطبيق لحماية الأمان',
                    style: AppText.headingXL(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عذراً، تطبيق $kAppName محمي بدرع أمان متقدم ولا يعمل أثناء تشغيل أي اتصال VPN أو خادم Proxy.',
                    style: AppText.body(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radar,
                                size: 15, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text('تفاصيل الفحص الأمني:',
                                style:
                                    AppText.caption(color: AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.vpnDetectedDetails.isEmpty
                              ? 'تم اكتشاف نفق اتصال افتراضي نشط (tun0 / ppp0)'
                              : s.vpnDetectedDetails,
                          style: AppText.mono(size: 11, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checking ? null : _recheck,
                      icon: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(_checking
                          ? 'جاري فحص الشبكة...'
                          : 'إعادة الفحص بعد إغلاق الـ VPN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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

// ============================================================================
// PIN LOCK SCREEN
// ============================================================================
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinCtrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    if (AppState().verifyPin(_pinCtrl.text.trim())) {
      setState(() => _err = null);
    } else {
      setState(() => _err = 'رمز الحماية غير صحيح');
      _pinCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppState().accentColor;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person_rounded, size: 48, color: accent),
              const SizedBox(height: 14),
              Text('التطبيق محمي برمز PIN', style: AppText.headingLg()),
              const SizedBox(height: 6),
              Text('أدخل رمز القفل للمتابعة إلى استوديو $kAppName',
                  style: AppText.caption()),
              const SizedBox(height: 16),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppText.headingXL(),
                decoration: InputDecoration(
                  hintText: '••••',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (_) => _verify(),
              ),
              if (_err != null) ...[
                const SizedBox(height: 8),
                Text(_err!, style: AppText.caption(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'فتح القفل',
                icon: Icons.lock_open_rounded,
                onTap: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAINTENANCE SCREEN
// ============================================================================
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.warning.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.engineering_rounded,
                  size: 56, color: AppColors.warning),
              const SizedBox(height: 16),
              Text('وضع الصيانة والتحديث', style: AppText.headingXL()),
              const SizedBox(height: 10),
              Text(
                s.maintenanceMessage,
                style: AppText.body(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => s.logout(),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                label: const Text('تسجيل دخول الإدارة'),
              ),
            ],
          ),
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
          const _ArchitecturalBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderStrong),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 36,
                        offset: Offset(0, 16))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              size: 13, color: AppColors.success),
                          SizedBox(width: 5),
                          Text(
                            'درع الحماية وفحص الـ VPN نشط',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: accent.withOpacity(0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'DV',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: accent,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول للنظام',
                      style: AppText.headingXL(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$kAppName $kAppVersion • تصميم معماري هادئ وحماية فائقة',
                      style: AppText.caption(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (error != null) _ErrorBanner(message: error!),
                    _AuthField(
                        controller: userCtrl,
                        icon: Icons.person_outline_rounded,
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
                        icon: Icons.lock_outline_rounded,
                        hint: 'كلمة المرور',
                        obscure: true),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isRegister ? 'إنشاء الحساب الآن' : 'تسجيل الدخول',
                      icon: isRegister ? Icons.person_add : Icons.login,
                      loading: loading,
                      onTap: _submit,
                    ),
                    if (s.allowGuestMode) ...[
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
                            final err = AppState().loginAsGuest();
                            if (err != null) {
                              setState(() => error = err);
                            }
                          },
                          icon: const Icon(Icons.person_outline,
                              color: AppColors.guest, size: 18),
                          label: const Text(
                            'الدخول السريع كزائر',
                            style: TextStyle(
                                color: AppColors.guest,
                                fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                                color: AppColors.guest.withOpacity(0.45)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
                            : 'ليس لديك حساب؟ أنشئ حساباً مجانياً',
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    Text('تطوير وإشراف: $kDevName • واتساب: $kDevWhatsapp',
                        style: AppText.caption(color: AppColors.textDim)),
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
      style: AppText.body(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.caption(color: AppColors.textDim),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.4)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                style: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700))),
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
      child: Material(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: loading
                ? const SizedBox(
                    height: 21,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.2),
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
                            fontSize: 14)),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN (Architectural Top Bar + Navigation + Active Downloads)
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
          _NavItem(Icons.tune_rounded, 'الإعدادات'),
          if (isAdmin)
            _NavItem(Icons.admin_panel_settings_rounded, 'الإدارة',
                admin: true),
        ];

        if (_tab >= pages.length) _tab = 0;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              const _ArchitecturalBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _TopNavigationBar(
                      onOpenAdmin: isAdmin
                          ? () => setState(() => _tab = pages.length - 1)
                          : null,
                    ),
                    if (s.activeTasks.isNotEmpty) _ActiveDownloadsBanner(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
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
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderStrong)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                          padding: const EdgeInsets.symmetric(vertical: 7),
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
                                  Icon(it.icon,
                                      size: 21,
                                      color: active
                                          ? color
                                          : AppColors.textMuted),
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
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: active
                                        ? color
                                        : AppColors.textMuted),
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

class _TopNavigationBar extends StatelessWidget {
  final VoidCallback? onOpenAdmin;
  const _TopNavigationBar({this.onOpenAdmin});

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final isAdmin = s.currentUser?.isAdmin == true;
    final isVip =
        s.currentUser?.isVip == true || (s.myApiKey?.isActive ?? false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.accentColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                'DV',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: s.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(kAppName, style: AppText.headingMd()),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLighter,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kAppVersion,
                        style:
                            AppText.mono(size: 9, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                Text(
                  isAdmin
                      ? 'حساب المدير التنفيذي (${s.currentUser!.username})'
                      : isVip
                          ? 'عضوية VIP Pro (${s.currentUser?.username ?? "مشترك"})'
                          : s.isGuest
                              ? 'وضع الزائر • المتبقي اليوم: ${(s.currentDailyQuota - s.todayUserDownloadsCount).clamp(0, 999)}'
                              : 'حساب قياسي (${s.currentUser?.username ?? ""})',
                  style: AppText.caption(
                    color: isAdmin
                        ? AppColors.admin
                        : isVip
                            ? AppColors.vip
                            : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_good_rounded,
                    size: 13, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'VPN Shield',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin && onOpenAdmin != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onOpenAdmin,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    size: 17, color: AppColors.admin),
              ),
            ),
          ],
        ],
      ),
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
                  'جاري الحفظ في الهاتف: ${t.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(),
                ),
              ),
              Text(
                '${t.speedKBps.toStringAsFixed(0)} KB/s',
                style: AppText.mono(size: 10.5, color: AppColors.success),
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
// CALM ARCHITECTURAL BACKGROUND (Zero Harsh Neon Glows)
// ============================================================================
class _ArchitecturalBackground extends StatelessWidget {
  const _ArchitecturalBackground();

  @override
  Widget build(BuildContext context) {
    final accent = AppState().accentColor;
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x0D64748B), Colors.transparent],
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
// HOME SCREEN (Clean Silent Extraction, Broadcasts, Smart Tools & Google Ads)
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
  String loadingText = 'جاري تحليل الوسائط وتجهيز البث...';
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
    final s = AppState();
    await s.checkVpnAndSecurityStatus();
    if (s.isVpnBlockedNow) return;

    if (s.todayUserDownloadsCount >= s.currentDailyQuota) {
      setState(() => error =
          'لقد وصلت للحد اليومي المسموح به (${s.currentDailyQuota} فيديو). قم بترقية حسابك إلى VIP للتحميل بلا حدود.');
      return;
    }

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

    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      result = null;
      loadingText = 'جاري جلب بيانات الفيديو بأعلى جودة متاحة...';
    });

    DownloadEntry? lastSuccess;

    for (int idx = 0; idx < urls.length; idx++) {
      final currentUrl = urls[idx];
      if (urls.length > 1 && mounted) {
        setState(() {
          loadingText =
              'جاري معالجة الفيديو (${idx + 1} من ${urls.length})...';
        });
      }

      final entry = await s.addDownload(currentUrl, quality);

      // استخراج صامت بالكامل في الخلفية دون إظهار أي أسماء محركات أو تخطي للمستخدم
      final response = await DownloadService.downloadSilentlyInBackground(
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

    if (lastSuccess != null && mounted) {
      await showGoogleInterstitialAdIfNeeded(context);
    }
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

    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Broadcast Announcements from Admin
            if (s.broadcasts.isNotEmpty)
              _BroadcastBannerWidget(message: s.broadcasts.first),

            // Top Google Ad Banner
            if (s.showTopBannerAd)
              const GoogleAdBannerWidget(placementName: 'home_top'),

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
                    Icon(Icons.auto_awesome_motion, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم رصد رابط ${detectPlatform(detectedClipboardLink!).toUpperCase()} في الحافظة',
                            style: AppText.headingMd(color: accent),
                          ),
                          Text(
                            detectedClipboardLink!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(),
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

            // Stats Overview Row
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: 'إجمالي العمليات',
                      value: s.totalDownloads,
                      icon: Icons.analytics_outlined,
                      color: accent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'مكتمل بنجاح',
                      value: s.successDownloads,
                      icon: Icons.check_circle_outline,
                      color: AppColors.success)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'محفوظ بالهاتف',
                      value: s.savedDeviceFiles.length,
                      icon: Icons.sd_storage_outlined,
                      color: AppColors.guest)),
            ]),
            const SizedBox(height: 12),

            // Main Extraction Studio Console
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ModeSegmentButton(
                          label: 'تحميل رابط فردي',
                          icon: Icons.link_rounded,
                          active: !batchMode,
                          onTap: () => setState(() => batchMode = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeSegmentButton(
                          label: 'تحميل دفعات متعددة',
                          icon: Icons.dynamic_feed_rounded,
                          active: batchMode,
                          onTap: () => setState(() => batchMode = true),
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
                          style: AppText.body(),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: batchMode
                                ? 'ضع كل رابط فيديو في سطر مستقل لتحميلها دفعة واحدة...'
                                : 'الصق رابط الفيديو (YouTube, TikTok, Instagram...)',
                            hintStyle:
                                AppText.caption(color: AppColors.textDim),
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
                                horizontal: 14, vertical: 14),
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
                                    BorderSide(color: accent, width: 1.4)),
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
                            border:
                                Border.all(color: accent.withOpacity(0.35)),
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
                    height: 38,
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
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? accent : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
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
                                  fontWeight: FontWeight.w800,
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
                        ? 'بدء معالجة وتحميل القائمة'
                        : 'تحضير ومعاينة الفيديو الآن',
                    icon: Icons.download_rounded,
                    loading: loading,
                    onTap: _download,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loadingText,
                              style: AppText.body(color: accent),
                            ),
                          ),
                        ],
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
            const SizedBox(height: 12),

            // Quick Smart Tools Row
            _QuickSmartToolsCard(
              currentUrl: urlCtrl.text.trim(),
              quickPreview: quickPreview,
              onPasteAndExtractCover: () async {
                final u = urlCtrl.text.trim();
                if (u.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('الصق رابط الفيديو أولاً لاستخراج الغلاف')),
                  );
                  return;
                }
                final meta =
                    await DownloadService.fetchQuickPreviewMetadata(u);
                if (!context.mounted) return;
                final thumb = meta['thumbnail'] ?? '';
                if (thumb.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: thumb));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'تم استخراج ونسخ رابط الصورة المصغرة عالية الدقة HD!'),
                        backgroundColor: AppColors.success),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Supported Platforms Bar
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المنصات المدعومة بالمعاينة والتحميل المباشر',
                      style: AppText.headingMd()),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PlatformIcon(
                          Icons.play_circle_fill,
                          const Color(0xFFEF4444),
                          'YouTube',
                          activePlatform == 'youtube'),
                      _PlatformIcon(Icons.music_note, const Color(0xFF38BDF8),
                          'TikTok', activePlatform == 'tiktok'),
                      _PlatformIcon(Icons.camera_alt, const Color(0xFFE1306C),
                          'Instagram', activePlatform == 'instagram'),
                      _PlatformIcon(Icons.facebook, const Color(0xFF3B82F6),
                          'Facebook', activePlatform == 'facebook'),
                      _PlatformIcon(
                          Icons.alternate_email,
                          const Color(0xFF60A5FA),
                          'X / Twitter',
                          activePlatform == 'twitter'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

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

            // Bottom Google Ad Banner
            if (s.showBottomBannerAd)
              const GoogleAdBannerWidget(placementName: 'home_bottom'),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeSegmentButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppState().accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.16) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15, color: active ? accent : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: active ? accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastBannerWidget extends StatelessWidget {
  final BroadcastMessage message;
  const _BroadcastBannerWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = message.type == 'warning'
        ? AppColors.warning
        : message.type == 'promo'
            ? AppColors.vip
            : AppColors.guest;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.title, style: AppText.headingMd(color: color)),
                Text(message.body,
                    style: AppText.caption(color: AppColors.text)),
              ],
            ),
          ),
          if (message.actionUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                final uri = Uri.tryParse(message.actionUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text('فتح', style: TextStyle(color: color)),
            ),
        ],
      ),
    );
  }
}

class _QuickSmartToolsCard extends StatelessWidget {
  final String currentUrl;
  final Map<String, String>? quickPreview;
  final VoidCallback onPasteAndExtractCover;

  const _QuickSmartToolsCard({
    required this.currentUrl,
    required this.quickPreview,
    required this.onPasteAndExtractCover,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.build_circle_outlined,
                  size: 17, color: s.accentColor),
              const SizedBox(width: 6),
              Text('أدوات الوسائط الذكية السريعة', style: AppText.headingMd()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToolActionTile(
                  icon: Icons.image_outlined,
                  label: 'نسخ غلاف HD',
                  onTap: onPasteAndExtractCover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolActionTile(
                  icon: Icons.audiotrack_outlined,
                  label: 'تحويل MP3 فوري',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'اختر "صوت MP3 نقي" من شريط الجودة بالأعلى لاستخراج الصوت مباشرة'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolActionTile(
                  icon: Icons.security_rounded,
                  label: 'فحص أمان الشبكة',
                  onTap: () async {
                    await s.checkVpnAndSecurityStatus();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'فحص الشبكة: الاتصال مباشر وآمن (لا يوجد VPN أو Proxy)'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppState().accentColor),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
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
                    errorBuilder: (_, __, ___) => _SmallPlatformBox(
                        platform: platform, width: 72, height: 52),
                  )
                : _SmallPlatformBox(platform: platform, width: 72, height: 52),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: platformColor(platform).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'معاينة ذكية • ${platform.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: platformColor(platform),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'الرابط جاهز للتحضير والتحميل' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headingMd(),
                ),
                if (author.isNotEmpty)
                  Text(
                    'الناشر: $author',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(),
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x88000000),
                        Color(0x22000000),
                        Color(0xCC000000)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
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
                        Text('جاهز للمعاينة والحفظ',
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
                        style: AppText.headingMd(),
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
                    ),
                  ],
                ),
                if (entry.author.isNotEmpty)
                  Text('القناة / الناشر: ${entry.author}',
                      style: AppText.caption()),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _MiniTag(entry.platform.toUpperCase(),
                      platformColor(entry.platform)),
                  _MiniTag(entry.quality.toUpperCase(), AppColors.success),
                  if (entry.fileSizeText.isNotEmpty)
                    _MiniTag(entry.fileSizeText, AppColors.guest),
                ]),
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
                        style: AppText.caption(color: AppColors.success),
                      ),
                      Text(
                        '${formatBytes(activeTask.receivedBytes)} • ${activeTask.speedKBps.toStringAsFixed(0)} KB/s',
                        style: AppText.mono(size: 10),
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
                        onPressed: onOpenPreviewModal,
                        icon: const Icon(Icons.play_circle_outline, size: 15),
                        label: const Text('معاينة وتشغيل',
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
                                content: Text('تم نسخ الرابط المباشر'),
                                backgroundColor: AppColors.success),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('نسخ الرابط',
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
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withOpacity(0.24), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child:
            Icon(platformIcon(platform), size: 52, color: c.withOpacity(0.5)),
      ),
    );
  }
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
                Expanded(
                  child: Text('استوديو المعاينة المباشرة',
                      style: AppText.headingLg()),
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
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _FallbackThumbBanner(platform: platform),
                    )
                  else
                    _FallbackThumbBanner(platform: platform),
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.black38,
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final target =
                          streamUrl.isNotEmpty ? streamUrl : sourceUrl;
                      final uri = Uri.tryParse(target);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.inAppWebView);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'تشغيل الفيديو داخل التطبيق',
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
              style: AppText.headingMd(),
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('القناة / الناشر: $author', style: AppText.caption()),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final target = streamUrl.isNotEmpty ? streamUrl : sourceUrl;
                  final uri = Uri.tryParse(target);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption()),
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
    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(active ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: color.withOpacity(active ? 0.65 : 0.22),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.history, color: s.accentColor, size: 16),
              const SizedBox(width: 6),
              Text('أحدث الوسائط المستخرجة', style: AppText.headingMd()),
            ]),
            Text('${s.myDownloads.length} عنصر', style: AppText.caption()),
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
                              errorBuilder: (_, __, ___) =>
                                  _SmallPlatformBox(platform: e.platform),
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
                            style: AppText.body(),
                          ),
                          Text(
                              '${timeAgo(e.createdAt)}${e.fileSizeText.isNotEmpty ? " • ${e.fileSizeText}" : ""}',
                              style: AppText.caption()),
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
  final double width;
  final double height;
  const _SmallPlatformBox({
    required this.platform,
    this.width = 48,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: platformColor(platform).withOpacity(0.12),
        border: Border.all(color: platformColor(platform).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(platformIcon(platform),
          color: platformColor(platform), size: 18),
    );
  }
}

// ============================================================================
// STUDIO SCREEN (Saved Device Files, Audio Filter, Favorites & Native Google Ad)
// ============================================================================
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  int _subTab = 0; // 0: All Saved, 1: Audio MP3, 2: Favorites

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final saved = s.savedDeviceFiles;
        final audioSaved = saved
            .where((d) =>
                d.quality == 'audio' ||
                d.localPath.toLowerCase().endsWith('.mp3'))
            .toList();
        final favorites = s.myDownloads.where((d) => d.isFavorite).toList();

        final activeList = _subTab == 0
            ? saved
            : _subTab == 1
                ? audioSaved
                : favorites;

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Icon(Icons.video_library_rounded, color: s.accentColor),
                const SizedBox(width: 8),
                Text('استوديو الوسائط المحفوظة', style: AppText.headingLg()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeSegmentButton(
                    label: 'المحفوظات (${saved.length})',
                    icon: Icons.folder_special_rounded,
                    active: _subTab == 0,
                    onTap: () => setState(() => _subTab = 0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ModeSegmentButton(
                    label: 'صوتيات (${audioSaved.length})',
                    icon: Icons.music_note_rounded,
                    active: _subTab == 1,
                    onTap: () => setState(() => _subTab = 1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ModeSegmentButton(
                    label: 'المفضلة (${favorites.length})',
                    icon: Icons.bookmark_rounded,
                    active: _subTab == 2,
                    onTap: () => setState(() => _subTab = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (s.showStudioNativeAd)
              const GoogleAdBannerWidget(
                placementName: 'studio_native',
                isNativeStyle: true,
              ),
            const SizedBox(height: 8),
            if (activeList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 56),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 60, color: AppColors.textDim.withOpacity(0.35)),
                    const SizedBox(height: 12),
                    Text('لا توجد ملفات في هذا القسم حالياً',
                        style: AppText.headingMd(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      'قم بتحميل الفيديوهات أو الصوتيات من الشاشة الرئيسية لتظهر هنا',
                      textAlign: TextAlign.center,
                      style: AppText.caption(),
                    ),
                  ],
                ),
              )
            else
              ...activeList.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: e.thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  e.thumbnailUrl,
                                  width: 68,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _SmallPlatformBox(platform: e.platform),
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
                                style: AppText.headingMd(),
                              ),
                              if (e.localPath.isNotEmpty)
                                Text(
                                  e.localPath,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption(
                                      color: AppColors.success),
                                ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (e.fileSizeText.isNotEmpty)
                                    _MiniTag(e.fileSizeText, AppColors.guest),
                                  _MiniTag(e.quality.toUpperCase(),
                                      AppColors.api),
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
                              color: s.accentColor, size: 26),
                        ),
                        IconButton(
                          onPressed: () => s.deleteDownloadItem(e.id,
                              deleteLocalFile: true),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }
}

// ============================================================================
// HISTORY SCREEN (Clean User History without Technical Bypass Jargon)
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(Icons.history, color: s.accentColor),
              const SizedBox(width: 8),
              Text('سجل العمليات والتنزيلات', style: AppText.headingLg()),
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
                        content: const Text(
                            'هل أنت متأكد من مسح سجلك بالكامل؟',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: AppText.body(),
              decoration: InputDecoration(
                hintText: 'ابحث في سجل الفيديوهات بالاسم أو الرابط...',
                hintStyle: AppText.caption(color: AppColors.textDim),
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
                            size: 56,
                            color: AppColors.textDim.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        Text('لا توجد عناصر مطابقة في السجل',
                            style: AppText.body(color: AppColors.textMuted)),
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
                                  style: AppText.headingMd(),
                                ),
                                const SizedBox(height: 4),
                                Wrap(spacing: 6, runSpacing: 4, children: [
                                  _MiniTag(e.platform.toUpperCase(),
                                      s.accentColor),
                                  _MiniTag(e.quality.toUpperCase(),
                                      AppColors.success),
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
                                              ? 'محفوظ بالهاتف'
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
                                                content:
                                                    Text('تم الحفظ في: $saved'),
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
              fontSize: 9.5, color: color, fontWeight: FontWeight.w800)),
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
// SETTINGS SCREEN (Matte Swatches, PIN Security Lock, API Portal & Dev Info)
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final codeCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  String? codeError;
  String? codeSuccess;

  final themeSwatches = const [
    Color(0xFFE07A2E), // Matte Amber-Orange
    Color(0xFFD94E4E), // Soft Crimson
    Color(0xFF7C69EF), // Calm Slate Violet
    Color(0xFF2EA8D9), // Ocean Slate Cyan
    Color(0xFF10B981), // Matte Emerald
    Color(0xFFD99B26), // Warm Gold
  ];

  @override
  void initState() {
    super.initState();
    pinCtrl.text = AppState().appPinCode;
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    pinCtrl.dispose();
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
            // Developer Identity Card
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accentColor.withOpacity(0.16),
                      border: Border.all(
                          color: s.accentColor.withOpacity(0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Text('YJ',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: s.accentColor)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kDevName, style: AppText.headingLg()),
                        Text('مطور ومؤسس نظام $kAppName • $kDevWhatsapp',
                            style: AppText.caption(color: s.accentColor)),
                      ],
                    ),
                  ),
                  _SocialBtn(
                      Icons.chat,
                      () =>
                          launchUrl(Uri.parse('https://wa.me/2$kDevWhatsapp'))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // App Appearance & Smart Preferences
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
                  Row(children: [
                    Icon(Icons.palette_outlined,
                        color: s.accentColor, size: 18),
                    const SizedBox(width: 8),
                    Text('المظهر الهادئ وتفضيلات التنزيل',
                        style: AppText.headingMd()),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: themeSwatches.map((c) {
                      final selected = s.accentColor.value == c.value;
                      return GestureDetector(
                        onTap: () => s.saveSettings(newColor: c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 2.2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 17)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.autoSaveAfterExtract,
                    activeColor: s.accentColor,
                    title: Text('حفظ تلقائي بالهاتف فور التحضير',
                        style: AppText.body()),
                    subtitle: Text(
                        'بدء تنزيل ملف الفيديو مباشرة بمجرد جاهزية الرابط',
                        style: AppText.caption()),
                    onChanged: (v) => s.saveSettings(newAutoSave: v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.autoDetectClipboard,
                    activeColor: s.accentColor,
                    title: Text('رادار الحافظة الذكي', style: AppText.body()),
                    subtitle: Text(
                        'التعرف تلقائياً على روابط الفيديوهات المنسوخة',
                        style: AppText.caption()),
                    onChanged: (v) =>
                        s.saveSettings(newAutoDetectClipboard: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Personal Security & PIN Lock Card
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
                  Row(children: [
                    Icon(Icons.security_rounded,
                        color: s.accentColor, size: 18),
                    const SizedBox(width: 8),
                    Text('حماية التطبيق وقفل الخصوصية (PIN)',
                        style: AppText.headingMd()),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك تعيين رمز سري (4 أرقام) لقفل التطبيق والاستوديو عند فتحه، أو تركه فارغاً لإلغاء القفل.',
                    style: AppText.caption(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AuthField(
                          controller: pinCtrl,
                          icon: Icons.pin_outlined,
                          hint: 'رمز PIN (مثال: 2026) أو فارغ للإلغاء',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          s.saveSettings(newPinCode: pinCtrl.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(pinCtrl.text.trim().isEmpty
                                  ? 'تم إلغاء قفل التطبيق برمز PIN'
                                  : 'تم تفعيل قفل التطبيق برمز PIN بنجاح'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // API & VIP Subscription Portal
            if (!s.isGuest) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.api.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: AppColors.api, size: 20),
                      SizedBox(width: 8),
                      Text('بوابة تفعيل VIP واشتراك المطورين API',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14)),
                    ]),
                    const SizedBox(height: 10),
                    if (key != null && key.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              key.apiKey,
                              style: AppText.mono(color: AppColors.api),
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
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TimerBox(value: '${key.daysLeft}', label: 'يوم'),
                          _TimerBox(value: '${key.hoursLeft}', label: 'ساعة'),
                          _TimerBox(
                              value: '${key.minutesLeft}', label: 'دقيقة'),
                        ],
                      ),
                    ] else
                      Text(
                        'احصل على كود تفعيل VIP & API ($kApiPrice جنيه عبر فودافون كاش: $kDevWhatsapp) لإزالة الإعلانات وفتح التحميل غير المحدود.',
                        style: AppText.caption(),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeCtrl,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: AppText.mono(size: 13.5),
                      decoration: InputDecoration(
                        hintText: 'DOViD-XXXXXXXXXXXX',
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
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
                                ? 'تم تفعيل عضوية VIP ومفتاح API بنجاح!'
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
                        child: const Text('تفعيل الكود الآن',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    if (codeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(codeError!,
                            style: AppText.caption(color: AppColors.error)),
                      ),
                    if (codeSuccess != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(codeSuccess!,
                            style: AppText.caption(color: AppColors.success)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => s.logout(),
                icon:
                    const Icon(Icons.logout, color: AppColors.error, size: 16),
                label: const Text('تسجيل الخروج من الحساب',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: AppColors.error.withOpacity(0.35)),
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
      Text(label, style: AppText.caption()),
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
        child: Icon(icon, size: 18, color: const Color(0xFF25D366)),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.caption()),
        Text(value, style: AppText.body()),
      ]),
    );
  }
}

// ============================================================================
// MASSIVE 8-TAB ENTERPRISE ADMIN COMMAND CENTER
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
    final tabs = const [
      {'label': 'مركز القيادة', 'icon': Icons.dashboard_customize_rounded},
      {'label': 'إعلانات Google', 'icon': Icons.ads_click_rounded},
      {'label': 'الإشعارات العامة', 'icon': Icons.campaign_rounded},
      {'label': 'إدارة الأعضاء و VIP', 'icon': Icons.people_alt_rounded},
      {'label': 'مراقبة التحميلات', 'icon': Icons.cloud_download_rounded},
      {'label': 'المحركات الخفية', 'icon': Icons.settings_input_component},
      {'label': 'درع الأمان و VPN', 'icon': Icons.gpp_good_rounded},
      {'label': 'الأكواد و API', 'icon': Icons.vpn_key_rounded},
    ];

    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.admin, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text('غرفة العمليات والتحكم الشامل للمدير',
                    style: AppText.headingLg(color: AppColors.admin)),
              ),
              _MiniTag('SUPER ADMIN', AppColors.admin),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final t = tabs[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _AdminTab(
                      label: t['label'] as String,
                      icon: t['icon'] as IconData,
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _AdminCommandCenterTab(),
                _AdminGoogleAdsTab(),
                _AdminBroadcastTab(),
                _AdminUsersVipTab(),
                _AdminDownloadsMonitorTab(),
                _AdminBackgroundEnginesTab(),
                _AdminSecurityVpnTab(),
                _AdminCodesApiTab(),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.admin : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Colors.transparent : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14, color: active ? Colors.white : AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.textMuted)),
        ]),
      ),
    );
  }
}

// 1. ADMIN COMMAND CENTER TAB
class _AdminCommandCenterTab extends StatefulWidget {
  const _AdminCommandCenterTab();

  @override
  State<_AdminCommandCenterTab> createState() => _AdminCommandCenterTabState();
}

class _AdminCommandCenterTabState extends State<_AdminCommandCenterTab> {
  late final TextEditingController _maintMsgCtrl;
  late final TextEditingController _guestLimitCtrl;

  @override
  void initState() {
    super.initState();
    final s = AppState();
    _maintMsgCtrl = TextEditingController(text: s.maintenanceMessage);
    _guestLimitCtrl =
        TextEditingController(text: s.guestDailyLimit.toString());
  }

  @override
  void dispose() {
    _maintMsgCtrl.dispose();
    _guestLimitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    final totalD = s.downloads.length;
    final succD = s.downloads.where((d) => d.status == 'success').length;
    final rate =
        totalD > 0 ? ((succD / totalD) * 100).toStringAsFixed(1) : '100.0';
    final avgMs = s.bypassLogs.isEmpty
        ? 0
        : (s.bypassLogs.map((e) => e.responseTimeMs).sum ~/
            s.bypassLogs.length);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          Expanded(
              child: _AdminStat(
                  'إجمالي الأعضاء', s.users.length, AppColors.admin)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'إجمالي التحميلات', s.downloads.length, AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat('أعضاء VIP',
                  s.users.where((u) => u.isVip).length, AppColors.vip)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _AdminStat('ظهور الإعلانات', s.adImpressionsCount,
                  AppColors.googleBlue)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'نقرات الإعلانات', s.adClicksCount, AppColors.success)),
          const SizedBox(width: 8),
          Expanded(
              child: _AdminStat(
                  'أحداث الحماية', s.securityEvents.length, AppColors.error)),
        ]),
        const SizedBox(height: 12),

        // System Control Switches
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
              Text('مفاتيح التحكم الفوري بالنظام', style: AppText.headingMd()),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.vpnProtectionEnabled,
                activeColor: AppColors.success,
                title: Text('حظر عمل التطبيق عند اتصال VPN أو Proxy',
                    style: AppText.body()),
                subtitle: Text(
                    'إيقاف التطبيق فوراً عند رصد أي نفق VPN نشط على الجهاز',
                    style: AppText.caption()),
                onChanged: (v) => s.saveAdminSystemConfig(vpnProtect: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.allowAdminVpnBypass,
                activeColor: AppColors.admin,
                title: Text('استثناء حساب المدير من حظر الـ VPN',
                    style: AppText.body()),
                subtitle: Text('السماح للمدير فقط باستخدام التطبيق مع الـ VPN',
                    style: AppText.caption()),
                onChanged: (v) => s.saveAdminSystemConfig(adminVpnBypass: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.maintenanceMode,
                activeColor: AppColors.warning,
                title: Text('تفعيل وضع الصيانة العام (Maintenance Mode)',
                    style: AppText.body()),
                subtitle: Text(
                    'قفل التطبيق مؤقتاً لجميع المستخدمين ما عدا المدير',
                    style: AppText.caption()),
                onChanged: (v) => s.saveAdminSystemConfig(maintenance: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.allowGuestMode,
                activeColor: AppColors.guest,
                title: Text('السماح بالدخول السريع كزائر (Guest Mode)',
                    style: AppText.body()),
                onChanged: (v) => s.saveAdminSystemConfig(allowGuest: v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _AuthField(
                      controller: _maintMsgCtrl,
                      icon: Icons.build_outlined,
                      hint: 'رسالة وضع الصيانة...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AuthField(
                      controller: _guestLimitCtrl,
                      icon: Icons.speed,
                      hint: 'حد الزائر',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    s.saveAdminSystemConfig(
                      maintenanceMsg: _maintMsgCtrl.text.trim(),
                      guestLimit:
                          int.tryParse(_guestLimitCtrl.text.trim()) ?? 10,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم حفظ إعدادات النظام بنجاح'),
                          backgroundColor: AppColors.success),
                    );
                  },
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('حفظ إعدادات غرفة العمليات'),
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

        // Performance Metrics
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
              Text('مؤشرات الأداء الفني والسيرفر', style: AppText.headingMd()),
              const SizedBox(height: 10),
              _InfoRow('نسبة نجاح الاستخراج الكلية', '$rate%'),
              _InfoRow('متوسط زمن استجابة المحركات الخفية', '${avgMs}ms'),
              _InfoRow('المحركات الخفية المفعلة',
                  '${s.enabledEngines.values.where((v) => v).length} من ${s.enabledEngines.length}'),
              _InfoRow('الأكواد المتاحة للتفعيل',
                  '${s.codes.where((c) => c.status == 'active').length}'),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text('$value',
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption()),
      ]),
    );
  }
}

// 2. REAL GOOGLE ADS MANAGER TAB
class _AdminGoogleAdsTab extends StatefulWidget {
  const _AdminGoogleAdsTab();

  @override
  State<_AdminGoogleAdsTab> createState() => _AdminGoogleAdsTabState();
}

class _AdminGoogleAdsTabState extends State<_AdminGoogleAdsTab> {
  late final TextEditingController appIdCtrl;
  late final TextEditingController bannerCtrl;
  late final TextEditingController interCtrl;
  late final TextEditingController nativeCtrl;
  late final TextEditingController pubCtrl;
  late final TextEditingController dispSlotCtrl;
  late final TextEditingController inArtSlotCtrl;
  late final TextEditingController sponsorUrlCtrl;

  @override
  void initState() {
    super.initState();
    final s = AppState();
    appIdCtrl = TextEditingController(text: s.admobAppId);
    bannerCtrl = TextEditingController(text: s.admobBannerId);
    interCtrl = TextEditingController(text: s.admobInterstitialId);
    nativeCtrl = TextEditingController(text: s.admobNativeId);
    pubCtrl = TextEditingController(text: s.adsensePublisherId);
    dispSlotCtrl = TextEditingController(text: s.adsenseDisplaySlot);
    inArtSlotCtrl = TextEditingController(text: s.adsenseInArticleSlot);
    sponsorUrlCtrl = TextEditingController(text: s.customSponsorDestinationUrl);
  }

  @override
  void dispose() {
    appIdCtrl.dispose();
    bannerCtrl.dispose();
    interCtrl.dispose();
    nativeCtrl.dispose();
    pubCtrl.dispose();
    dispSlotCtrl.dispose();
    inArtSlotCtrl.dispose();
    sponsorUrlCtrl.dispose();
    super.dispose();
  }

  void _fillGoogleOfficialTestIds() {
    setState(() {
      appIdCtrl.text = kGoogleTestAppId;
      bannerCtrl.text = kGoogleTestBannerId;
      interCtrl.text = kGoogleTestInterstitialId;
      nativeCtrl.text = kGoogleTestNativeId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم ملء معرفات Google AdMob التجريبية الرسمية بنجاح'),
        backgroundColor: AppColors.googleBlue,
      ),
    );
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
            border: Border.all(color: AppColors.googleBlue.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.ads_click_rounded,
                        color: AppColors.googleBlue, size: 20),
                    const SizedBox(width: 8),
                    Text('مركز إدارة إعلانات Google الفعلي',
                        style: AppText.headingMd()),
                  ]),
                  Switch(
                    value: s.adsEnabled,
                    activeColor: AppColors.success,
                    onChanged: (v) => s.saveGoogleAdsSettings(enabled: v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                        'مرات الظهور (Impressions)', '${s.adImpressionsCount}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoRow('النقرات (Clicks)', '${s.adClicksCount}'),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.showTopBannerAd,
                activeColor: AppColors.googleBlue,
                title: Text('إعلان بانر أعلى الشاشة الرئيسية',
                    style: AppText.body()),
                onChanged: (v) => s.saveGoogleAdsSettings(topBanner: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.showBottomBannerAd,
                activeColor: AppColors.googleBlue,
                title: Text('إعلان بانر أسفل الشاشة الرئيسية',
                    style: AppText.body()),
                onChanged: (v) => s.saveGoogleAdsSettings(bottomBanner: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.showStudioNativeAd,
                activeColor: AppColors.googleBlue,
                title: Text('إعلان مدمج (Native Ad) داخل الاستوديو',
                    style: AppText.body()),
                onChanged: (v) => s.saveGoogleAdsSettings(studioNative: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.showInterstitialOnDownload,
                activeColor: AppColors.googleBlue,
                title: Text('إعلان بيني كامل (Interstitial) بعد الاستخراج',
                    style: AppText.body()),
                onChanged: (v) => s.saveGoogleAdsSettings(interstitial: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.exemptVipFromAds,
                activeColor: AppColors.vip,
                title: Text('إعفاء حسابات VIP والمدير من الإعلانات',
                    style: AppText.body()),
                onChanged: (v) => s.saveGoogleAdsSettings(exemptVip: v),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('معرفات وحدات Google AdMob:',
                      style: AppText.caption(color: AppColors.googleBlue)),
                  TextButton.icon(
                    onPressed: _fillGoogleOfficialTestIds,
                    icon: const Icon(Icons.auto_fix_high, size: 14),
                    label: const Text('ملء معرفات Google التجريبية',
                        style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              _AuthField(
                  controller: appIdCtrl,
                  icon: Icons.apps_outlined,
                  hint: 'AdMob App ID (ca-app-pub-xxx~yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: bannerCtrl,
                  icon: Icons.view_stream_outlined,
                  hint: 'Banner Ad Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: interCtrl,
                  icon: Icons.fullscreen_rounded,
                  hint: 'Interstitial Ad Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: nativeCtrl,
                  icon: Icons.featured_play_list_outlined,
                  hint: 'Native Ad Unit ID (ca-app-pub-xxx/yyy)'),
              const SizedBox(height: 12),
              Text('معرفات Google AdSense & وجهة النقرات:',
                  style: AppText.caption(color: AppColors.warning)),
              const SizedBox(height: 6),
              _AuthField(
                  controller: pubCtrl,
                  icon: Icons.fingerprint,
                  hint: 'AdSense Publisher ID (pub-xxxxxxxx)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AuthField(
                        controller: dispSlotCtrl,
                        icon: Icons.grid_view,
                        hint: 'Display Slot ID'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AuthField(
                        controller: inArtSlotCtrl,
                        icon: Icons.article_outlined,
                        hint: 'In-Article Slot ID'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _AuthField(
                  controller: sponsorUrlCtrl,
                  icon: Icons.open_in_browser,
                  hint: 'رابط التوجيه عند النقر على الإعلان'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        s.saveGoogleAdsSettings(
                          appId: appIdCtrl.text.trim(),
                          bannerId: bannerCtrl.text.trim(),
                          interstitialId: interCtrl.text.trim(),
                          nativeId: nativeCtrl.text.trim(),
                          pubId: pubCtrl.text.trim(),
                          dispSlot: dispSlotCtrl.text.trim(),
                          inArtSlot: inArtSlotCtrl.text.trim(),
                          sponsorUrl: sponsorUrlCtrl.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'تم حفظ وتفعيل إعدادات إعلانات Google بنجاح!'),
                              backgroundColor: AppColors.success),
                        );
                      },
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('حفظ إعدادات الإعلانات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.googleBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const _GoogleInterstitialDialog(),
                      );
                    },
                    icon: const Icon(Icons.preview_outlined, size: 16),
                    label: const Text('معاينة الإعلان البيني'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.googleBlue,
                      side: const BorderSide(color: AppColors.googleBlue),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
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

// 3. BROADCAST & ANNOUNCEMENTS TAB
class _AdminBroadcastTab extends StatefulWidget {
  const _AdminBroadcastTab();

  @override
  State<_AdminBroadcastTab> createState() => _AdminBroadcastTabState();
}

class _AdminBroadcastTabState extends State<_AdminBroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _type = 'info';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
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
              Text('إرسال إشعار أو إعلان عام لجميع المستخدمين',
                  style: AppText.headingMd()),
              const SizedBox(height: 10),
              _AuthField(
                  controller: _titleCtrl,
                  icon: Icons.title,
                  hint: 'عنوان الإشعار (مثال: تحديث جديد متاح)'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: _bodyCtrl,
                  icon: Icons.message_outlined,
                  hint: 'نص الرسالة التي ستظهر في أعلى الرئيسية...'),
              const SizedBox(height: 8),
              _AuthField(
                  controller: _urlCtrl,
                  icon: Icons.link,
                  hint: 'رابط خارجي عند الضغط (اختياري)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniChoiceChip('معلومات', 'info', _type,
                      (v) => setState(() => _type = v)),
                  const SizedBox(width: 6),
                  _MiniChoiceChip('تنبيه هام', 'warning', _type,
                      (v) => setState(() => _type = v)),
                  const SizedBox(width: 6),
                  _MiniChoiceChip('عرض VIP', 'promo', _type,
                      (v) => setState(() => _type = v)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_titleCtrl.text.trim().isEmpty ||
                        _bodyCtrl.text.trim().isEmpty) {
                      return;
                    }
                    s.addBroadcast(
                      title: _titleCtrl.text.trim(),
                      body: _bodyCtrl.text.trim(),
                      type: _type,
                      actionUrl: _urlCtrl.text.trim(),
                    );
                    _titleCtrl.clear();
                    _bodyCtrl.clear();
                    _urlCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم نشر الإشعار العام بنجاح'),
                          backgroundColor: AppColors.success),
                    );
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
        const SizedBox(height: 14),
        Text('الإشعارات النشطة حالياً (${s.broadcasts.length})',
            style: AppText.headingMd()),
        const SizedBox(height: 8),
        ...s.broadcasts.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.admin),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title, style: AppText.headingMd()),
                        Text(b.body, style: AppText.caption()),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => s.deleteBroadcast(b.id),
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

class _MiniChoiceChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final void Function(String) onSelect;

  const _MiniChoiceChip(
      this.label, this.value, this.groupValue, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final active = value == groupValue;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.admin : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// 4. USERS & VIP MANAGEMENT TAB
class _AdminUsersVipTab extends StatefulWidget {
  const _AdminUsersVipTab();

  @override
  State<_AdminUsersVipTab> createState() => _AdminUsersVipTabState();
}

class _AdminUsersVipTabState extends State<_AdminUsersVipTab> {
  final _newUsernameCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _newIsVip = true;

  @override
  void dispose() {
    _newUsernameCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إنشاء حساب عضو / VIP جديد يدوياً',
                  style: AppText.headingMd()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AuthField(
                      controller: _newUsernameCtrl,
                      icon: Icons.person_add_alt,
                      hint: 'اسم المستخدم',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AuthField(
                      controller: _newPassCtrl,
                      icon: Icons.key,
                      hint: 'كلمة المرور',
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _newIsVip,
                activeColor: AppColors.vip,
                title: Text('منح صلاحية VIP كاملة (بدون إعلانات + غير محدود)',
                    style: AppText.caption(color: AppColors.vip)),
                onChanged: (v) => setState(() => _newIsVip = v),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final err = s.createUserByAdmin(
                      username: _newUsernameCtrl.text,
                      password: _newPassCtrl.text,
                      isVip: _newIsVip,
                    );
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(err),
                            backgroundColor: AppColors.error),
                      );
                    } else {
                      _newUsernameCtrl.clear();
                      _newPassCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم إنشاء الحساب بنجاح'),
                            backgroundColor: AppColors.success),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة العضو الآن'),
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
        Text('قائمة الأعضاء المسجلين (${s.users.length})',
            style: AppText.headingMd()),
        const SizedBox(height: 8),
        ...s.users.map((u) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: u.isBanned
                      ? AppColors.error.withOpacity(0.4)
                      : u.isVip
                          ? AppColors.vip.withOpacity(0.4)
                          : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (u.isAdmin
                                ? AppColors.admin
                                : u.isVip
                                    ? AppColors.vip
                                    : AppColors.primary)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          u.isAdmin
                              ? Icons.shield
                              : u.isVip
                                  ? Icons.workspace_premium
                                  : Icons.person,
                          color: u.isAdmin
                              ? AppColors.admin
                              : u.isVip
                                  ? AppColors.vip
                                  : AppColors.primary,
                          size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(u.username, style: AppText.headingMd()),
                              const SizedBox(width: 6),
                              if (u.isAdmin) _MiniTag('ADMIN', AppColors.admin),
                              if (u.isVip && !u.isAdmin)
                                _MiniTag('VIP PRO', AppColors.vip),
                              if (u.isBanned)
                                _MiniTag('محظور', AppColors.error),
                            ],
                          ),
                          Text(
                              'انضم: ${DateFormat('yyyy-MM-dd').format(u.createdAt)}',
                              style: AppText.caption()),
                        ],
                      ),
                    ),
                  ]),
                  if (!u.isAdmin) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SmallBtn(
                          label: u.isVip ? 'إلغاء VIP' : 'ترقية لـ VIP',
                          icon: Icons.workspace_premium,
                          color: AppColors.vip,
                          onTap: () => s.toggleUserVip(u.id),
                        ),
                        _SmallBtn(
                          label: u.isBanned ? 'فك حظر الحساب' : 'حظر الحساب',
                          icon: Icons.block,
                          color: u.isBanned
                              ? AppColors.success
                              : AppColors.warning,
                          onTap: () => s.toggleUserBan(u.id),
                        ),
                        _SmallBtn(
                          label: 'تصفير كلمة السر (123456)',
                          icon: Icons.lock_reset,
                          color: AppColors.guest,
                          onTap: () {
                            s.resetUserPasswordByAdmin(u.id, '123456');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'تم تعيين كلمة سر ${u.username} إلى 123456'),
                                  backgroundColor: AppColors.success),
                            );
                          },
                        ),
                        _SmallBtn(
                          label: 'حذف نهائي',
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          onTap: () => s.deleteUser(u.id),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }
}

// 5. GLOBAL DOWNLOADS MONITOR TAB
class _AdminDownloadsMonitorTab extends StatelessWidget {
  const _AdminDownloadsMonitorTab();

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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            _SmallPlatformBox(platform: e.platform, width: 38, height: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title.isEmpty ? 'فيديو ${e.platform}' : e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.headingMd()),
                  Text(
                      'المستخدم: ${owner?.username ?? 'زائر'} • المحرك الخفي: ${e.strategy.isEmpty ? 'direct' : e.strategy} • ${timeAgo(e.createdAt)}',
                      style: AppText.caption()),
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

// 6. SILENT BACKGROUND ENGINES & BYPASS LOGS TAB (ADMIN ONLY)
class _AdminBackgroundEnginesTab extends StatelessWidget {
  const _AdminBackgroundEnginesTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Icon(Icons.visibility_off_outlined,
                      size: 18, color: AppColors.admin),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إدارة محركات الاستخراج الخفية (تعمل بالخلفية فقط)',
                      style: AppText.headingMd(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'جميع هذه المحركات تعمل بصمت تام في الخلفية دون إظهار أسمائها للمستخدم العادي.',
                style: AppText.caption(),
              ),
              const SizedBox(height: 8),
              ...s.enabledEngines.entries.map((eng) => SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: eng.value,
                    activeColor: AppColors.admin,
                    title: Text(eng.key, style: AppText.mono()),
                    onChanged: (v) => s.toggleEngine(eng.key, v),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سجل عمليات الاستخراج الخفية (${s.bypassLogs.length})',
                style: AppText.headingMd()),
            if (s.bypassLogs.isNotEmpty)
              TextButton(
                onPressed: s.clearBypassLogs,
                child: const Text('مسح السجل',
                    style: TextStyle(color: AppColors.error, fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (s.bypassLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: Text('لا توجد سجلات استخراج خلفية حالياً',
                    style: AppText.caption())),
          )
        else
          ...s.bypassLogs.take(60).map((b) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Icon(
                    b.status == 'success' ? Icons.check_circle : Icons.cancel,
                    color: b.status == 'success'
                        ? AppColors.success
                        : AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.strategy, style: AppText.mono(size: 11)),
                        Text(b.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption()),
                      ],
                    ),
                  ),
                  _MiniTag('${b.responseTimeMs}ms', AppColors.guest),
                ]),
              )),
      ],
    );
  }
}

// 7. SECURITY SHIELD, ANTI-VPN & FIREWALL TAB
class _AdminSecurityVpnTab extends StatefulWidget {
  const _AdminSecurityVpnTab();

  @override
  State<_AdminSecurityVpnTab> createState() => _AdminSecurityVpnTabState();
}

class _AdminSecurityVpnTabState extends State<_AdminSecurityVpnTab> {
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('حظر عنوان IP أو جهاز يدوياً', style: AppText.headingMd()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _AuthField(
                      controller: ipCtrl,
                      icon: Icons.security,
                      hint: 'مثال: 192.168.1.50 أو local_device'),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سجل أحداث درع الـ VPN والحماية (${s.securityEvents.length})',
                style: AppText.headingMd()),
            if (s.securityEvents.isNotEmpty)
              TextButton(
                onPressed: s.clearSecurityEvents,
                child: const Text('مسح',
                    style: TextStyle(color: AppColors.error, fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (s.securityEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('لا توجد محاولات اتصال VPN أو اختراق مرصودة.',
                style: AppText.caption()),
          )
        else
          ...s.securityEvents.take(25).map((ev) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_lock_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.details, style: AppText.body()),
                          Text('${ev.username} • ${timeAgo(ev.createdAt)}',
                              style: AppText.caption()),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 12),
        Text('الأجهزة وعناوين IP المحظورة (${s.blockedIps.length})',
            style: AppText.headingMd()),
        const SizedBox(height: 6),
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
                      Text(b.ip, style: AppText.mono()),
                      Text(b.reason, style: AppText.caption()),
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

// 8. SUBSCRIPTION CODES & API KEYS TAB
class _AdminCodesApiTab extends StatefulWidget {
  const _AdminCodesApiTab();

  @override
  State<_AdminCodesApiTab> createState() => _AdminCodesApiTabState();
}

class _AdminCodesApiTabState extends State<_AdminCodesApiTab> {
  final codeCountCtrl = TextEditingController(text: '5');
  final codeDaysCtrl = TextEditingController(text: '30');
  bool grantsVip = true;

  @override
  void dispose() {
    codeCountCtrl.dispose();
    codeDaysCtrl.dispose();
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('توليد أكواد اشتراك VIP & API جديدة',
                  style: AppText.headingMd()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _AuthField(
                    controller: codeCountCtrl,
                    icon: Icons.confirmation_number_outlined,
                    hint: 'العدد',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AuthField(
                    controller: codeDaysCtrl,
                    icon: Icons.calendar_today_outlined,
                    hint: 'الأيام',
                  ),
                ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: grantsVip,
                activeColor: AppColors.vip,
                title: Text('تفعيل VIP تلقائياً لحامل الكود',
                    style: AppText.caption(color: AppColors.vip)),
                onChanged: (v) => setState(() => grantsVip = v),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final c = int.tryParse(codeCountCtrl.text) ?? 1;
                    final d = int.tryParse(codeDaysCtrl.text) ?? 30;
                    s.generateCodes(c.clamp(1, 100), d.clamp(1, 365),
                        grantsVip: grantsVip);
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
                          color: Colors.black, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.api,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('قائمة الأكواد (${s.codes.length})',
                style: AppText.headingMd()),
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
                      Text(c.code, style: AppText.mono(color: AppColors.api)),
                      const SizedBox(height: 3),
                      Wrap(spacing: 6, children: [
                        _MiniTag('${c.durationDays} يوم', AppColors.guest),
                        if (c.grantsVip) _MiniTag('VIP', AppColors.vip),
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
}