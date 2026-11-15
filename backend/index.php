<?php
/**
 * ===================================================================================
 * YOSSEF VID - النظام الكامل v5.0 (Ultra Pro Security & Animation Edition)
 * DOViD - Smart Video Downloader System v5.0
 * ===================================================================================
 * المطور: YOSSEF JOO (ثابت - غير قابل للتعديل)
 * الواتساب: 01029892573 (ثابت - غير قابل للتعديل)
 * ===================================================================================
 */

ob_start();
ini_set('session.cookie_httponly', 1);
ini_set('session.use_strict_mode', 1);
ini_set('session.cookie_samesite', 'Lax');
session_start();

// ============================================================================
// القيم الثابتة غير القابلة للتعديل
// ============================================================================
define('DEV_NAME', 'YOSSEF JOO');
define('DEV_WHATSAPP', '01029892573');
define('APP_NAME', 'DOViD');
define('APP_VERSION', '5.0 Pro');
define('API_ENDPOINT', 'https://zecora0.serv00.net/download/download.php');
define('API_PRICE', '100'); // سعر الاشتراك الشهري
define('ADMIN_EMAIL', 'guhfyuggu7@gmail.com');

// ============================================================================
// ترويسات الحماية المتقدمة (Security Headers)
// ============================================================================
header('X-Frame-Options: SAMEORIGIN');
header('X-Content-Type-Options: nosniff');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// ============================================================================
// توليد والتحقق من رمز CSRF
// ============================================================================
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
$csrfToken = $_SESSION['csrf_token'];

function verifyCsrfToken($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], (string)$token);
}

// ============================================================================
// تحديد الصفحة الحالية أولاً
// ============================================================================
$page = isset($_GET['page']) ? preg_replace('/[^a-zA-Z0-9_]/', '', $_GET['page']) : 'home';
$publicPages = ['login', 'register'];
$isPublicPage = in_array($page, $publicPages);

// ============================================================================
// المسارات وقاعدة البيانات SQLite3 (مع تفعيل WAL للأداء العالي)
// ============================================================================
$dbFile = __DIR__ . '/downloader_data.sqlite';
$db = new SQLite3($dbFile);
$db->busyTimeout(5000);
$db->exec('PRAGMA journal_mode = WAL;');
$db->exec('PRAGMA foreign_keys = ON;');

// ============================================================================
// إنشاء الجداول
// ============================================================================
$db->exec("CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    email TEXT,
    is_admin INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
)");

$db->exec("CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

$db->exec("CREATE TABLE IF NOT EXISTS downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    url TEXT NOT NULL,
    title TEXT,
    platform TEXT,
    download_link TEXT,
    quality TEXT DEFAULT 'auto',
    status TEXT DEFAULT 'pending',
    strategy_used TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
)");

$db->exec("CREATE TABLE IF NOT EXISTS bypass_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    url TEXT,
    strategy TEXT,
    status TEXT,
    response_time INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

$db->exec("CREATE TABLE IF NOT EXISTS login_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT NOT NULL,
    username TEXT,
    success INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

$db->exec("CREATE TABLE IF NOT EXISTS blocked_ips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT UNIQUE NOT NULL,
    reason TEXT,
    blocked_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

$db->exec("CREATE TABLE IF NOT EXISTS api_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    api_key TEXT UNIQUE NOT NULL,
    api_secret TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    subscription_start DATETIME,
    subscription_end DATETIME,
    total_requests INTEGER DEFAULT 0,
    monthly_requests INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

$db->exec("CREATE TABLE IF NOT EXISTS subscription_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    duration_days INTEGER DEFAULT 30,
    status TEXT DEFAULT 'active',
    used_by INTEGER,
    used_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER
)");

$db->exec("CREATE TABLE IF NOT EXISTS api_usage_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    api_key_id INTEGER,
    endpoint TEXT,
    ip TEXT,
    status TEXT,
    response_time INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)");

// ============================================================================
// إنشاء حساب المدير إذا لم يكن موجوداً
// ============================================================================
$adminStmt = $db->prepare("SELECT id FROM users WHERE username = :username");
$adminStmt->bindValue(':username', 'admin', SQLITE3_TEXT);
$adminResult = $adminStmt->execute();
if (!$adminResult->fetchArray(SQLITE3_ASSOC)) {
    $createAdmin = $db->prepare("INSERT INTO users (username, password, email, is_admin, created_at) VALUES (:username, :password, :email, 1, datetime('now'))");
    $createAdmin->bindValue(':username', 'admin', SQLITE3_TEXT);
    $createAdmin->bindValue(':password', password_hash('guhfyuggu7@855A', PASSWORD_DEFAULT), SQLITE3_TEXT);
    $createAdmin->bindValue(':email', ADMIN_EMAIL, SQLITE3_TEXT);
    $createAdmin->execute();
}

// ============================================================================
// نظام الحماية المتقدم - WAF & Rate Limiting & IP Blocking
// ============================================================================
function getClientIP() {
    $headers = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_REAL_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
    foreach ($headers as $header) {
        if (!empty($_SERVER[$header])) {
            $ips = explode(',', $_SERVER[$header]);
            $ip = trim($ips[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

$clientIP = getClientIP();

// فحص WAF ضد محاولات الحقن المشبوهة في روابط GET
$rawQuery = urldecode($_SERVER['QUERY_STRING'] ?? '');
if (preg_match('/(union\s+select|information_schema|<script|javascript:|onerror=|onload=|\.\.\/)/i', $rawQuery)) {
    $wafBlock = $db->prepare("INSERT OR IGNORE INTO blocked_ips (ip, reason) VALUES (:ip, 'WAF: Malicious query pattern detected')");
    $wafBlock->bindValue(':ip', $clientIP, SQLITE3_TEXT);
    $wafBlock->execute();
}

// التحقق من IP المحظور
if (!$isPublicPage) {
    $blockStmt = $db->prepare("SELECT * FROM blocked_ips WHERE ip = :ip");
    $blockStmt->bindValue(':ip', $clientIP, SQLITE3_TEXT);
    $blockResult = $blockStmt->execute();
    if ($blockRow = $blockResult->fetchArray(SQLITE3_ASSOC)) {
        http_response_code(403);
        die('<!DOCTYPE html><html dir="rtl" lang="ar"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>تم حظر الوصول - DOViD</title><link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@500;800;900&display=swap" rel="stylesheet"><style>body{background:#050508;color:#f8fafc;font-family:Tajawal,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;padding:20px}.box{background:#0f0f1a;border:1px solid rgba(239,68,68,0.3);border-radius:24px;padding:36px 28px;max-width:420px;box-shadow:0 20px 60px rgba(239,68,68,0.15)}h1{color:#ef4444;margin:0 0 12px;font-size:24px}p{color:#94a3b8;font-size:14px;line-height:1.7;margin:0}.ip{margin-top:16px;display:inline-block;background:#1a1a2e;padding:6px 14px;border-radius:10px;font-family:monospace;color:#f87171;font-size:12px}</style></head><body><div class="box"><h1>🚫 تم حظر الوصول للنظام</h1><p>تم اكتشاف نشاط غير مصرح به من عنوان الشبكة الخاص بك بواسطة جدار الحماية الذكي DOViD Shield.</p><div class="ip">IP: ' . htmlspecialchars($clientIP) . '</div></div></body></html>');
    }
}

// Rate limiting - 10 محاولات فاشلة خلال 15 دقيقة
$fifteenMinAgo = date('Y-m-d H:i:s', strtotime('-15 minutes'));
$rateStmt = $db->prepare("SELECT COUNT(*) as count FROM login_attempts WHERE ip = :ip AND success = 0 AND created_at > :time");
$rateStmt->bindValue(':ip', $clientIP, SQLITE3_TEXT);
$rateStmt->bindValue(':time', $fifteenMinAgo, SQLITE3_TEXT);
$rateResult = $rateStmt->execute();
$rateData = $rateResult->fetchArray(SQLITE3_ASSOC);
if ($rateData && $rateData['count'] >= 10) {
    $autoBlock = $db->prepare("INSERT OR IGNORE INTO blocked_ips (ip, reason) VALUES (:ip, 'Too many failed login attempts (Brute-force protection)')");
    $autoBlock->bindValue(':ip', $clientIP, SQLITE3_TEXT);
    $autoBlock->execute();
    http_response_code(429);
    die('<!DOCTYPE html><html dir="rtl" lang="ar"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>تجاوز الحد المسموح - DOViD</title><link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@500;800;900&display=swap" rel="stylesheet"><style>body{background:#050508;color:#f8fafc;font-family:Tajawal,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;padding:20px}.box{background:#0f0f1a;border:1px solid rgba(245,158,11,0.3);border-radius:24px;padding:36px 28px;max-width:420px;box-shadow:0 20px 60px rgba(245,158,11,0.15)}h1{color:#f59e0b;margin:0 0 12px;font-size:24px}p{color:#94a3b8;font-size:14px;line-height:1.7;margin:0}</style></head><body><div class="box"><h1>⏳ تجاوزت الحد المسموح</h1><p>تم إيقاف عنوان IP الخاص بك مؤقتاً بسبب تكرار محاولات تسجيل الدخول الفاشلة.</p></div></body></html>');
}

// ============================================================================
// تحميل الإعدادات مبكراً لاستخدامها في كل الأنظمة
// ============================================================================
$settings = [];
$settingsResult = $db->query("SELECT key, value FROM settings");
while ($row = $settingsResult->fetchArray(SQLITE3_ASSOC)) {
    $settings[$row['key']] = $row['value'];
}
$settings['developer_name'] = DEV_NAME;
$settings['developer_whatsapp'] = DEV_WHATSAPP;
$settings['app_name'] = APP_NAME;
$settings['api_endpoint'] = API_ENDPOINT;

$themeColor = $settings['theme_color'] ?? '#f97316';
if (!preg_match('/^#[0-9a-fA-F]{6}$/', $themeColor)) {
    $themeColor = '#f97316';
}
$defaultQuality = $settings['default_quality'] ?? 'auto';
$adsEnabled = ($settings['ads_enabled'] ?? '0') === '1';

// ============================================================================
// الدوال الأساسية ومعالجة الروابط الذكية (Smart Download Engine v5.0)
// ============================================================================
function detectPlatform($url) {
    $patterns = [
        'youtube'     => '/(youtube\.com|youtu\.be)/i',
        'instagram'   => '/instagram\.com/i',
        'tiktok'      => '/tiktok\.com/i',
        'facebook'    => '/(facebook\.com|fb\.watch|fb\.gg)/i',
        'twitter'     => '/(twitter\.com|x\.com|t\.co)/i',
        'snapchat'    => '/snapchat\.com/i',
        'pinterest'   => '/(pinterest\.com|pin\.it)/i',
        'vimeo'       => '/vimeo\.com/i',
        'dailymotion' => '/(dailymotion\.com|dai\.ly)/i',
        'threads'     => '/threads\.net/i',
    ];
    foreach ($patterns as $name => $pattern) {
        if (preg_match($pattern, $url)) return $name;
    }
    return 'unknown';
}

function resolveShortUrl($url) {
    if (!preg_match('/(vt\.tiktok\.com|vm\.tiktok\.com|fb\.watch|pin\.it|t\.co|youtu\.be)/i', $url)) {
        return $url;
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER         => true,
        CURLOPT_NOBODY         => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS      => 5,
        CURLOPT_TIMEOUT        => 8,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
        CURLOPT_USERAGENT      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
    ]);
    curl_exec($ch);
    $effectiveUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    curl_close($ch);
    return (!empty($effectiveUrl) && filter_var($effectiveUrl, FILTER_VALIDATE_URL)) ? $effectiveUrl : $url;
}

function smartDownload($rawUrl, $settings, $db, $userId, $quality = 'auto') {
    $url = resolveShortUrl($rawUrl);
    $apiEndpoint = $settings['api_endpoint'] ?? API_ENDPOINT;
    $timeout = (int)($settings['timeout'] ?? 25);

    $strategies = [
        // 1. الإرسال المباشر JSON إلى الخادم الأساسي
        'direct_post_json' => function($url, $api) use ($timeout, $quality) {
            $ch = curl_init($api);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => json_encode(['text' => $url, 'quality' => $quality]),
                CURLOPT_HTTPHEADER     => [
                    'Content-Type: application/json',
                    'Accept: application/json, text/plain, */*',
                    'Origin: https://zecora0.serv00.net',
                    'Referer: ' . $url
                ],
                CURLOPT_TIMEOUT        => $timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => 0,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36'
            ]);
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($httpCode === 200 && $response) {
                $data = json_decode($response, true);
                if (isset($data['status']) && $data['status'] === 'success' && !empty($data['answer'])) {
                    return ['success' => true, 'data' => $data];
                }
            }
            return ['success' => false];
        },
        // 2. الإرسال المباشر Form URL-Encoded
        'direct_post_form' => function($url, $api) use ($timeout, $quality) {
            $ch = curl_init($api);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => http_build_query(['text' => $url, 'quality' => $quality]),
                CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
                CURLOPT_TIMEOUT        => $timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => 0,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0.0.0 Safari/537.36'
            ]);
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($httpCode === 200 && $response) {
                $data = json_decode($response, true);
                if (isset($data['status']) && $data['status'] === 'success' && !empty($data['answer'])) {
                    return ['success' => true, 'data' => $data];
                }
            }
            return ['success' => false];
        },
        // 3. محرك TikWM الاحتياطي السريع لروابط TikTok بدون علامة مائية
        'tikwm_engine' => function($url, $api) use ($timeout, $quality) {
            if (stripos($url, 'tiktok.com') === false) return ['success' => false];
            $ch = curl_init('https://www.tikwm.com/api/');
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => http_build_query(['url' => $url, 'hd' => 1]),
                CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded', 'Accept: application/json'],
                CURLOPT_TIMEOUT        => 15,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            ]);
            $response = curl_exec($ch);
            curl_close($ch);
            if ($response) {
                $json = json_decode($response, true);
                if (isset($json['code']) && $json['code'] === 0 && !empty($json['data'])) {
                    $d = $json['data'];
                    $dlLink = ($quality === 'audio' && !empty($d['music']))
                        ? $d['music']
                        : ($d['hdplay'] ?? $d['play'] ?? $d['wmplay'] ?? '');
                    if (!empty($dlLink)) {
                        return [
                            'success' => true,
                            'data' => [
                                'status'    => 'success',
                                'answer'    => $dlLink,
                                'title'     => $d['title'] ?? 'فيديو TikTok بدون علامة مائية',
                                'thumbnail' => $d['cover'] ?? '',
                                'quality'   => ($quality === 'audio') ? 'MP3 Audio' : 'HD No-Watermark'
                            ]
                        ];
                    }
                }
            }
            return ['success' => false];
        },
        // 4. AllOrigins Raw Proxy POST
        'allorigins_post' => function($url, $api) use ($timeout) {
            $proxyUrl = 'https://api.allorigins.win/raw?url=' . urlencode($api);
            $ch = curl_init($proxyUrl);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => json_encode(['text' => $url]),
                CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
                CURLOPT_TIMEOUT        => $timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126.0.0.0 Mobile Safari/537.36'
            ]);
            $response = curl_exec($ch);
            curl_close($ch);
            if ($response) {
                $data = json_decode($response, true);
                if (isset($data['status']) && $data['status'] === 'success' && !empty($data['answer'])) {
                    return ['success' => true, 'data' => $data];
                }
            }
            return ['success' => false];
        },
        // 5. AllOrigins GET Wrapper
        'allorigins_get' => function($url, $api) use ($timeout) {
            $getUrl = $api . '?text=' . urlencode($url);
            $proxyUrl = 'https://api.allorigins.win/get?url=' . urlencode($getUrl) . '&timestamp=' . time();
            $ch = curl_init($proxyUrl);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => $timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15'
            ]);
            $response = curl_exec($ch);
            curl_close($ch);
            if ($response) {
                $wrapper = json_decode($response, true);
                if (isset($wrapper['contents'])) {
                    $data = json_decode($wrapper['contents'], true);
                    if (isset($data['status']) && $data['status'] === 'success' && !empty($data['answer'])) {
                        return ['success' => true, 'data' => $data];
                    }
                }
            }
            return ['success' => false];
        },
        // 6. CorsProxy Tunnel
        'corsproxy_post' => function($url, $api) use ($timeout) {
            $proxyUrl = 'https://corsproxy.io/?' . urlencode($api);
            $ch = curl_init($proxyUrl);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => json_encode(['text' => $url]),
                CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
                CURLOPT_TIMEOUT        => $timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36'
            ]);
            $response = curl_exec($ch);
            curl_close($ch);
            if ($response) {
                $data = json_decode($response, true);
                if (isset($data['status']) && $data['status'] === 'success' && !empty($data['answer'])) {
                    return ['success' => true, 'data' => $data];
                }
            }
            return ['success' => false];
        }
    ];

    foreach ($strategies as $name => $strategy) {
        $startTime = microtime(true);
        $result = $strategy($url, $apiEndpoint);
        $responseTime = round((microtime(true) - $startTime) * 1000);

        $stmt = $db->prepare("INSERT INTO bypass_logs (user_id, url, strategy, status, response_time) VALUES (:uid, :url, :strategy, :status, :time)");
        $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
        $stmt->bindValue(':url', $url, SQLITE3_TEXT);
        $stmt->bindValue(':strategy', $name, SQLITE3_TEXT);
        $stmt->bindValue(':status', $result['success'] ? 'success' : 'failed', SQLITE3_TEXT);
        $stmt->bindValue(':time', $responseTime, SQLITE3_INTEGER);
        $stmt->execute();

        if ($result['success']) {
            $result['strategy'] = $name;
            $result['resolved_url'] = $url;
            return $result;
        }
    }

    return ['success' => false, 'message' => 'فشلت جميع استراتيجيات التخطي. تأكد من صحة الرابط وأن الفيديو عام.'];
}

// ============================================================================
// بوابة Developer API المدمجة (تعمل عبر ?action=developer_api أو Authorization Bearer)
// ============================================================================
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
if ((isset($_GET['action']) && $_GET['action'] === 'developer_api') || preg_match('/Bearer\s+(dv_[a-f0-9]+)/i', $authHeader)) {
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Allow-Methods: POST, GET, OPTIONS');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit;
    }

    $startTime = microtime(true);
    $providedKey = '';
    if (preg_match('/Bearer\s+(dv_[a-f0-9]+)/i', $authHeader, $m)) {
        $providedKey = trim($m[1]);
    } elseif (!empty($_REQUEST['api_key'])) {
        $providedKey = trim($_REQUEST['api_key']);
    }

    if (empty($providedKey)) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Missing API Key. Pass Authorization: Bearer dv_...']);
        exit;
    }

    $keyStmt = $db->prepare("SELECT * FROM api_keys WHERE api_key = :key LIMIT 1");
    $keyStmt->bindValue(':key', $providedKey, SQLITE3_TEXT);
    $keyRes = $keyStmt->execute();
    $keyRow = $keyRes->fetchArray(SQLITE3_ASSOC);

    if (!$keyRow || $keyRow['status'] !== 'active') {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Invalid or inactive API Key']);
        exit;
    }

    if (!empty($keyRow['subscription_end']) && strtotime($keyRow['subscription_end']) < time()) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'API subscription has expired']);
        exit;
    }

    $rawInput = file_get_contents('php://input');
    $jsonBody = json_decode($rawInput, true) ?: [];
    $targetUrl = trim($jsonBody['url'] ?? $_POST['url'] ?? $_GET['url'] ?? '');
    $reqQuality = trim($jsonBody['quality'] ?? $_POST['quality'] ?? $_GET['quality'] ?? 'auto');

    if (empty($targetUrl) || !filter_var($targetUrl, FILTER_VALIDATE_URL)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Valid video "url" parameter is required']);
        exit;
    }

    $dlRes = smartDownload($targetUrl, $settings, $db, (int)$keyRow['user_id'], $reqQuality);
    $elapsed = round((microtime(true) - $startTime) * 1000);

    // تحديث عداد الطلبات وسجل API
    $updKey = $db->prepare("UPDATE api_keys SET total_requests = total_requests + 1, monthly_requests = monthly_requests + 1, updated_at = datetime('now') WHERE id = :id");
    $updKey->bindValue(':id', (int)$keyRow['id'], SQLITE3_INTEGER);
    $updKey->execute();

    $logApi = $db->prepare("INSERT INTO api_usage_logs (api_key_id, endpoint, ip, status, response_time) VALUES (:kid, :ep, :ip, :st, :rt)");
    $logApi->bindValue(':kid', (int)$keyRow['id'], SQLITE3_INTEGER);
    $logApi->bindValue(':ep', $targetUrl, SQLITE3_TEXT);
    $logApi->bindValue(':ip', $clientIP, SQLITE3_TEXT);
    $logApi->bindValue(':st', $dlRes['success'] ? 'success' : 'failed', SQLITE3_TEXT);
    $logApi->bindValue(':rt', $elapsed, SQLITE3_INTEGER);
    $logApi->execute();

    if ($dlRes['success']) {
        $platform = detectPlatform($targetUrl);
        $link = $dlRes['data']['answer'] ?? $dlRes['data']['url'] ?? '';
        $title = $dlRes['data']['title'] ?? 'فيديو ' . ucfirst($platform);
        echo json_encode([
            'status'       => 'success',
            'title'        => $title,
            'download_url' => $link,
            'platform'     => $platform,
            'quality'      => $dlRes['data']['quality'] ?? $reqQuality,
            'strategy'     => $dlRes['strategy'] ?? 'direct',
            'format'       => ($reqQuality === 'audio') ? 'mp3' : 'mp4',
            'response_ms'  => $elapsed
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(422);
        echo json_encode([
            'status'  => 'error',
            'message' => $dlRes['message'] ?? 'Failed to extract video link'
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// ============================================================================
// تعريف المتغيرات الأساسية للمستخدم
// ============================================================================
$userId = isset($_SESSION['user_id']) ? (int)$_SESSION['user_id'] : 0;
$isAdmin = isset($_SESSION['is_admin']) ? (int)$_SESSION['is_admin'] : 0;
$isGuest = !empty($_SESSION['guest_mode']);

// إجبار التوجيه إلى صفحة تسجيل الدخول إذا لم يكن مسجلاً أو زائراً
if ($userId === 0 && !$isGuest && !$isPublicPage && !isset($_GET['action'])) {
    header('Location: ?page=login');
    exit;
}

// ============================================================================
// نظام تسجيل الدخول / التسجيل / دخول كزائر
// ============================================================================
$loginError = '';
$registerError = '';

if (isset($_POST['register'])) {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $email = trim($_POST['email'] ?? '');
    if (strlen($username) < 3 || strlen($password) < 4) {
        $registerError = 'اسم المستخدم 3 أحرف على الأقل وكلمة المرور 4 أحرف على الأقل';
    } else {
        $hash = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $db->prepare("INSERT INTO users (username, password, email, created_at) VALUES (:username, :password, :email, datetime('now'))");
        $stmt->bindValue(':username', $username, SQLITE3_TEXT);
        $stmt->bindValue(':password', $hash, SQLITE3_TEXT);
        $stmt->bindValue(':email', $email, SQLITE3_TEXT);
        if (@$stmt->execute()) {
            session_regenerate_id(true);
            $_SESSION['user_id'] = $db->lastInsertRowID();
            $_SESSION['username'] = $username;
            $_SESSION['is_admin'] = 0;
            unset($_SESSION['guest_mode']);
            header('Location: ?page=home');
            exit;
        } else {
            $registerError = 'اسم المستخدم مستخدم بالفعل، جرب اسماً آخر';
        }
    }
}

if (isset($_POST['login'])) {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';

    $logAttempt = $db->prepare("INSERT INTO login_attempts (ip, username, success, created_at) VALUES (:ip, :username, 0, datetime('now'))");
    $logAttempt->bindValue(':ip', $clientIP, SQLITE3_TEXT);
    $logAttempt->bindValue(':username', $username, SQLITE3_TEXT);
    $logAttempt->execute();
    $lastAttemptId = $db->lastInsertRowID();

    $stmt = $db->prepare("SELECT id, password, is_admin, email FROM users WHERE username = :username");
    $stmt->bindValue(':username', $username, SQLITE3_TEXT);
    $result = $stmt->execute();
    $user = $result->fetchArray(SQLITE3_ASSOC);

    if ($user && password_verify($password, $user['password'])) {
        $updAttempt = $db->prepare("UPDATE login_attempts SET success = 1 WHERE id = :id");
        $updAttempt->bindValue(':id', $lastAttemptId, SQLITE3_INTEGER);
        $updAttempt->execute();

        $updateLogin = $db->prepare("UPDATE users SET last_login = datetime('now') WHERE id = :id");
        $updateLogin->bindValue(':id', $user['id'], SQLITE3_INTEGER);
        $updateLogin->execute();

        session_regenerate_id(true);
        $_SESSION['user_id'] = (int)$user['id'];
        $_SESSION['username'] = $username;
        $_SESSION['is_admin'] = (int)$user['is_admin'];
        unset($_SESSION['guest_mode']);
        header('Location: ?page=home');
        exit;
    } else {
        $loginError = 'اسم المستخدم أو كلمة المرور غير صحيحة';
    }
}

// دخول بدون تسجيل (Guest Mode)
if (isset($_POST['guest_login'])) {
    session_regenerate_id(true);
    $_SESSION['guest_mode'] = true;
    $_SESSION['username'] = 'زائر_' . substr(md5($clientIP . time()), 0, 5);
    $_SESSION['user_id'] = 0;
    $_SESSION['is_admin'] = 0;
    header('Location: ?page=home');
    exit;
}

if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: ?page=login');
    exit;
}

// ============================================================================
// تفعيل كود الاشتراك (للمستخدم العادي)
// ============================================================================
$codeError = '';
$codeSuccess = '';
if (isset($_POST['activate_code']) && !empty($_POST['subscription_code'])) {
    $code = strtoupper(trim($_POST['subscription_code']));
    $userId = $_SESSION['user_id'] ?? 0;

    if ($userId > 0 && !$isGuest) {
        $stmt = $db->prepare("SELECT * FROM subscription_codes WHERE UPPER(code) = :code AND status = 'active'");
        $stmt->bindValue(':code', $code, SQLITE3_TEXT);
        $result = $stmt->execute();
        $codeData = $result->fetchArray(SQLITE3_ASSOC);

        if ($codeData) {
            $now = date('Y-m-d H:i:s');
            $endDate = date('Y-m-d H:i:s', strtotime("+{$codeData['duration_days']} days"));

            $updateCode = $db->prepare("UPDATE subscription_codes SET status = 'used', used_by = :uid, used_at = datetime('now') WHERE id = :id");
            $updateCode->bindValue(':uid', $userId, SQLITE3_INTEGER);
            $updateCode->bindValue(':id', $codeData['id'], SQLITE3_INTEGER);
            $updateCode->execute();

            $apiKey = 'dv_' . bin2hex(random_bytes(16));
            $apiSecret = bin2hex(random_bytes(32));

            $stmt = $db->prepare("INSERT INTO api_keys (user_id, api_key, api_secret, status, subscription_start, subscription_end, created_at) VALUES (:uid, :key, :secret, 'active', :start, :end, datetime('now'))");
            $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
            $stmt->bindValue(':key', $apiKey, SQLITE3_TEXT);
            $stmt->bindValue(':secret', $apiSecret, SQLITE3_TEXT);
            $stmt->bindValue(':start', $now, SQLITE3_TEXT);
            $stmt->bindValue(':end', $endDate, SQLITE3_TEXT);
            $stmt->execute();

            $codeSuccess = "تم تفعيل الاشتراك بنجاح! مدة الاشتراك: {$codeData['duration_days']} يوم. ينتهي في: " . date('Y-m-d', strtotime($endDate));
        } else {
            $codeError = 'كود الاشتراك غير صالح أو مستخدم بالفعل';
        }
    } else {
        $codeError = 'يجب تسجيل الدخول بحساب رسمي أولاً لتفعيل الاشتراك';
    }
}

// ============================================================================
// إنشاء كود اشتراك جديد (للمدير فقط)
// ============================================================================
if ($isAdmin && isset($_POST['generate_code'])) {
    $duration = max(1, (int)($_POST['duration_days'] ?? 30));
    $count = max(1, min(100, (int)($_POST['code_count'] ?? 1)));
    $generatedCodes = [];

    for ($i = 0; $i < $count; $i++) {
        $newCode = 'DOViD-' . strtoupper(bin2hex(random_bytes(6)));
        $stmt = $db->prepare("INSERT INTO subscription_codes (code, duration_days, created_by) VALUES (:code, :duration, :admin)");
        $stmt->bindValue(':code', $newCode, SQLITE3_TEXT);
        $stmt->bindValue(':duration', $duration, SQLITE3_INTEGER);
        $stmt->bindValue(':admin', $userId, SQLITE3_INTEGER);
        if ($stmt->execute()) {
            $generatedCodes[] = $newCode;
        }
    }

    if (!empty($generatedCodes)) {
        $_SESSION['generated_codes'] = $generatedCodes;
        $_SESSION['code_duration'] = $duration;
    }
    header('Location: ?page=admin&tab=api_codes&generated=1');
    exit;
}

// ============================================================================
// تحديث الإعدادات
// ============================================================================
if (isset($_POST['update_settings'])) {
    if ($isAdmin) {
        $adsVal = isset($_POST['ads_enabled']) ? '1' : '0';
        $stmtAds = $db->prepare("INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ads_enabled', :val, datetime('now'))");
        $stmtAds->bindValue(':val', $adsVal, SQLITE3_TEXT);
        $stmtAds->execute();
    }

    $allowed = ['theme_color', 'default_quality', 'auto_clear', 'adsense_publisher_id', 'adsense_display_slot', 'adsense_inarticle_slot', 'adsense_anchor_slot'];
    foreach ($allowed as $key) {
        if (isset($_POST[$key])) {
            if (strpos($key, 'adsense_') === 0 && !$isAdmin) continue;
            $stmt = $db->prepare("INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (:key, :value, datetime('now'))");
            $stmt->bindValue(':key', $key, SQLITE3_TEXT);
            $stmt->bindValue(':value', trim($_POST[$key]), SQLITE3_TEXT);
            $stmt->execute();
        }
    }
    header('Location: ?page=settings&saved=1');
    exit;
}

// ============================================================================
// مسح السجل الخاص بالمستخدم فقط
// ============================================================================
if (isset($_GET['clear_history']) && $_GET['clear_history'] === '1' && $userId > 0) {
    $stmt = $db->prepare("DELETE FROM downloads WHERE user_id = :uid");
    $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
    $stmt->execute();
    $stmt = $db->prepare("DELETE FROM bypass_logs WHERE user_id = :uid");
    $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
    $stmt->execute();
    header('Location: ?page=history&cleared=1');
    exit;
}

// ============================================================================
// بيانات API Key للمستخدم الحالي (شاملة الدقائق والثواني للعداد الحي)
// ============================================================================
$userApiKey = null;
$subscriptionDaysLeft = 0;
$subscriptionHoursLeft = 0;
$subscriptionMinutesLeft = 0;
$subscriptionSecondsLeft = 0;
$subscriptionExpired = true;

if ($userId > 0 && !$isGuest) {
    $stmt = $db->prepare("SELECT * FROM api_keys WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1");
    $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
    $result = $stmt->execute();
    $userApiKey = $result->fetchArray(SQLITE3_ASSOC);

    if ($userApiKey && $userApiKey['status'] === 'active' && $userApiKey['subscription_end']) {
        $endTime = strtotime($userApiKey['subscription_end']);
        $now = time();
        $diff = $endTime - $now;

        if ($diff > 0) {
            $subscriptionExpired = false;
            $subscriptionDaysLeft = floor($diff / 86400);
            $subscriptionHoursLeft = floor(($diff % 86400) / 3600);
            $subscriptionMinutesLeft = floor(($diff % 3600) / 60);
            $subscriptionSecondsLeft = $diff % 60;
        }
    }
}

// ============================================================================
// PROXY تحميل مباشر وتخطي حظر المتصفح (يدعم MP4 و MP3 و Range Requests)
// ============================================================================
function sanitizeFilename($name, $ext = 'mp4') {
    $name = preg_replace('/[^a-zA-Z0-9\x{0600}-\x{06FF}\s\-_]/u', '', (string)$name);
    $name = preg_replace('/\s+/', '_', trim($name));
    if (empty($name)) $name = 'DOViD_' . time();
    $ext = ($ext === 'mp3' || $ext === 'audio') ? 'mp3' : 'mp4';
    return substr($name, 0, 80) . '.' . $ext;
}

if (isset($_GET['action']) && $_GET['action'] === 'proxy_download') {
    $downloadUrl = isset($_GET['url']) ? urldecode($_GET['url']) : '';
    $format = isset($_GET['format']) ? strtolower($_GET['format']) : 'mp4';
    $filename = isset($_GET['filename']) ? sanitizeFilename($_GET['filename'], $format) : 'DOViD_video.mp4';
    $platform = isset($_GET['platform']) ? strtolower($_GET['platform']) : 'unknown';

    if (empty($downloadUrl) || !filter_var($downloadUrl, FILTER_VALIDATE_URL)) {
        http_response_code(400);
        die('رابط التحميل غير صالح');
    }

    // منع SSRF (السماح فقط ببروتوكول http/https ومنع الشبكات المحلية)
    $parsedUrl = parse_url($downloadUrl);
    $scheme = strtolower($parsedUrl['scheme'] ?? '');
    $host = strtolower($parsedUrl['host'] ?? '');
    if (!in_array($scheme, ['http', 'https']) || in_array($host, ['localhost', '127.0.0.1', '0.0.0.0'])) {
        http_response_code(403);
        die('غير مصرح بالوصول إلى هذا المضيف');
    }

    $referers = [
        'youtube'     => 'https://www.youtube.com/',
        'instagram'   => 'https://www.instagram.com/',
        'tiktok'      => 'https://www.tiktok.com/',
        'facebook'    => 'https://www.facebook.com/',
        'twitter'     => 'https://x.com/',
        'x'           => 'https://x.com/',
        'vimeo'       => 'https://vimeo.com/',
        'dailymotion' => 'https://www.dailymotion.com/',
    ];
    $referer = $referers[$platform] ?? '';

    while (ob_get_level() > 0) {
        ob_end_clean();
    }
    set_time_limit(0);

    $ch = curl_init($downloadUrl);
    $rangeHeader = $_SERVER['HTTP_RANGE'] ?? '';
    $headers = [
        'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Accept: */*',
        'Accept-Language: en-US,en;q=0.9',
        'Connection: keep-alive',
    ];
    if (!empty($referer)) $headers[] = 'Referer: ' . $referer;
    if (!empty($rangeHeader)) $headers[] = 'Range: ' . $rangeHeader;

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => false,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
        CURLOPT_TIMEOUT        => 0,
        CURLOPT_CONNECTTIMEOUT => 30,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_HEADER         => false,
    ]);

    curl_setopt($ch, CURLOPT_HEADERFUNCTION, function($ch, $header) {
        $len = strlen($header);
        $headerTrim = trim($header);
        if (stripos($headerTrim, 'HTTP/') === 0) {
            $code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
            if ($code == 206) {
                header('HTTP/1.1 206 Partial Content');
            } else {
                header('HTTP/1.1 200 OK');
            }
            return $len;
        }
        $passHeaders = ['content-type', 'content-length', 'accept-ranges', 'content-range', 'etag', 'last-modified', 'cache-control'];
        $headerLower = strtolower($headerTrim);
        foreach ($passHeaders as $ph) {
            if (stripos($headerLower, $ph . ':') === 0) {
                header($headerTrim);
                break;
            }
        }
        return $len;
    });

    curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($ch, $data) {
        echo $data;
        flush();
        return strlen($data);
    });

    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('X-Content-Type-Options: nosniff');

    curl_exec($ch);
    curl_close($ch);
    exit;
}

// ============================================================================
// API التحميل الداخلي للواجهة
// ============================================================================
if (isset($_GET['action']) && $_GET['action'] === 'download') {
    header('Content-Type: application/json; charset=utf-8');

    $videoUrl = isset($_POST['url']) ? trim($_POST['url']) : '';
    $quality = isset($_POST['quality']) ? trim($_POST['quality']) : 'auto';

    if (empty($videoUrl) || !filter_var($videoUrl, FILTER_VALIDATE_URL)) {
        echo json_encode(['status' => 'error', 'message' => 'يرجى إدخال رابط فيديو صحيح يبدأ بـ http أو https']);
        exit;
    }

    $platform = detectPlatform($videoUrl);
    $userId = $_SESSION['user_id'] ?? 0;
    $isGuest = !empty($_SESSION['guest_mode']);

    if (!$isGuest && $userId > 0) {
        $stmt = $db->prepare("INSERT INTO downloads (user_id, url, platform, quality, status) VALUES (:uid, :url, :platform, :quality, 'processing')");
        $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
        $stmt->bindValue(':url', $videoUrl, SQLITE3_TEXT);
        $stmt->bindValue(':platform', $platform, SQLITE3_TEXT);
        $stmt->bindValue(':quality', $quality, SQLITE3_TEXT);
        $stmt->execute();
        $downloadId = $db->lastInsertRowID();
    } else {
        $downloadId = 0;
    }

    $result = smartDownload($videoUrl, $settings, $db, $userId, $quality);

    if ($result['success']) {
        $link = $result['data']['answer'] ?? $result['data']['url'] ?? '';
        $title = $result['data']['title'] ?? 'فيديو ' . ucfirst($platform);
        $thumb = $result['data']['thumbnail'] ?? '';

        if (!$isGuest && $userId > 0 && $downloadId > 0) {
            $stmt = $db->prepare("UPDATE downloads SET status = 'success', download_link = :link, title = :title, strategy_used = :strategy, completed_at = datetime('now') WHERE id = :id AND user_id = :uid");
            $stmt->bindValue(':link', $link, SQLITE3_TEXT);
            $stmt->bindValue(':title', $title, SQLITE3_TEXT);
            $stmt->bindValue(':strategy', $result['strategy'] ?? 'unknown', SQLITE3_TEXT);
            $stmt->bindValue(':id', $downloadId, SQLITE3_INTEGER);
            $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
            $stmt->execute();
        }

        echo json_encode([
            'status'    => 'success',
            'answer'    => $link,
            'title'     => $title,
            'thumbnail' => $thumb,
            'platform'  => $platform,
            'quality'   => $result['data']['quality'] ?? ($quality === 'audio' ? 'MP3' : 'HD'),
            'format'    => ($quality === 'audio') ? 'mp3' : 'mp4',
            'strategy'  => $result['strategy'] ?? 'direct',
            'guest'     => $isGuest
        ], JSON_UNESCAPED_UNICODE);
    } else {
        if (!$isGuest && $userId > 0 && $downloadId > 0) {
            $stmt = $db->prepare("UPDATE downloads SET status = 'failed', completed_at = datetime('now') WHERE id = :id AND user_id = :uid");
            $stmt->bindValue(':id', $downloadId, SQLITE3_INTEGER);
            $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
            $stmt->execute();
        }

        echo json_encode([
            'status'  => 'error',
            'message' => $result['message'] ?? 'فشل في معالجة الرابط. تأكد من صحة الرابط وأن المنصة مدعومة.'
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// ============================================================================
// إجراءات المدير (حظر/فك حظر IP، حذف مستخدم، إدارة الأكواد و API)
// ============================================================================
if ($isAdmin && (isset($_GET['admin_action']) || isset($_POST['admin_action']))) {
    $action = $_POST['admin_action'] ?? $_GET['admin_action'];

    if ($action === 'manual_block_ip' && !empty($_POST['ip_to_block'])) {
        $ipToBlock = trim($_POST['ip_to_block']);
        $reason = trim($_POST['block_reason'] ?? 'حظر يدوي بواسطة المدير');
        if (filter_var($ipToBlock, FILTER_VALIDATE_IP)) {
            $blockIp = $db->prepare("INSERT OR IGNORE INTO blocked_ips (ip, reason) VALUES (:ip, :reason)");
            $blockIp->bindValue(':ip', $ipToBlock, SQLITE3_TEXT);
            $blockIp->bindValue(':reason', $reason, SQLITE3_TEXT);
            $blockIp->execute();
        }
        header('Location: ?page=admin&tab=security');
        exit;
    }
    if ($action === 'block_ip' && isset($_GET['ip'])) {
        $blockIp = $db->prepare("INSERT OR IGNORE INTO blocked_ips (ip, reason) VALUES (:ip, 'Blocked by admin')");
        $blockIp->bindValue(':ip', $_GET['ip'], SQLITE3_TEXT);
        $blockIp->execute();
        header('Location: ?page=admin&tab=security');
        exit;
    }
    if ($action === 'unblock_ip' && isset($_GET['id'])) {
        $unblock = $db->prepare("DELETE FROM blocked_ips WHERE id = :id");
        $unblock->bindValue(':id', (int)$_GET['id'], SQLITE3_INTEGER);
        $unblock->execute();
        header('Location: ?page=admin&tab=security');
        exit;
    }
    if ($action === 'delete_code' && isset($_GET['code_id'])) {
        $stmt = $db->prepare("DELETE FROM subscription_codes WHERE id = :id");
        $stmt->bindValue(':id', (int)$_GET['code_id'], SQLITE3_INTEGER);
        $stmt->execute();
        header('Location: ?page=admin&tab=api_codes');
        exit;
    }
    if ($action === 'delete_user' && isset($_GET['user_id'])) {
        $targetId = (int)$_GET['user_id'];
        if ($targetId !== $userId) {
            $delUser = $db->prepare("DELETE FROM users WHERE id = :id AND is_admin = 0");
            $delUser->bindValue(':id', $targetId, SQLITE3_INTEGER);
            $delUser->execute();

            $delDl = $db->prepare("DELETE FROM downloads WHERE user_id = :id");
            $delDl->bindValue(':id', $targetId, SQLITE3_INTEGER);
            $delDl->execute();

            $delBp = $db->prepare("DELETE FROM bypass_logs WHERE user_id = :id");
            $delBp->bindValue(':id', $targetId, SQLITE3_INTEGER);
            $delBp->execute();

            $delAk = $db->prepare("DELETE FROM api_keys WHERE user_id = :id");
            $delAk->bindValue(':id', $targetId, SQLITE3_INTEGER);
            $delAk->execute();
        }
        header('Location: ?page=admin&tab=users');
        exit;
    }
    if ($action === 'deactivate_api' && isset($_GET['api_id'])) {
        $stmt = $db->prepare("UPDATE api_keys SET status = 'inactive' WHERE id = :id");
        $stmt->bindValue(':id', (int)$_GET['api_id'], SQLITE3_INTEGER);
        $stmt->execute();
        header('Location: ?page=admin&tab=api_codes');
        exit;
    }
}

// ============================================================================
// بيانات السجل الخاصة بالمستخدم المسجل دخوله فقط
// ============================================================================
$recentDownloads = [];
$stats = ['total' => 0, 'success' => 0, 'failed' => 0, 'processing' => 0];

if ($userId > 0 && !$isGuest) {
    $stmt = $db->prepare("SELECT * FROM downloads WHERE user_id = :uid ORDER BY created_at DESC LIMIT 50");
    $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
    $result = $stmt->execute();
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        $recentDownloads[] = $row;
    }

    $stmt = $db->prepare("SELECT status, COUNT(*) as count FROM downloads WHERE user_id = :uid GROUP BY status");
    $stmt->bindValue(':uid', $userId, SQLITE3_INTEGER);
    $statResult = $stmt->execute();
    while ($row = $statResult->fetchArray(SQLITE3_ASSOC)) {
        $stats[$row['status']] = $row['count'];
        $stats['total'] += $row['count'];
    }
}

// ============================================================================
// بيانات المدير - كل المستخدمين والنشاطات
// ============================================================================
$allUsers = [];
$allDownloads = [];
$allBypassLogs = [];
$allLoginAttempts = [];
$allApiKeys = [];
$allSubscriptionCodes = [];
$adminStats = [
    'total_users'       => 0,
    'total_downloads'   => 0,
    'total_bypass'      => 0,
    'total_logins'      => 0,
    'blocked_ips_count' => 0,
    'total_api_keys'    => 0,
    'active_api_keys'   => 0,
    'total_codes'       => 0,
    'used_codes'        => 0,
    'available_codes'   => 0
];

if ($isAdmin) {
    $usersResult = $db->query("SELECT * FROM users ORDER BY created_at DESC");
    while ($row = $usersResult->fetchArray(SQLITE3_ASSOC)) $allUsers[] = $row;

    $dlResult = $db->query("SELECT d.*, u.username FROM downloads d LEFT JOIN users u ON d.user_id = u.id ORDER BY d.created_at DESC LIMIT 100");
    while ($row = $dlResult->fetchArray(SQLITE3_ASSOC)) $allDownloads[] = $row;

    $bpResult = $db->query("SELECT b.*, u.username FROM bypass_logs b LEFT JOIN users u ON b.user_id = u.id ORDER BY b.created_at DESC LIMIT 100");
    while ($row = $bpResult->fetchArray(SQLITE3_ASSOC)) $allBypassLogs[] = $row;

    $loginResult = $db->query("SELECT * FROM login_attempts ORDER BY created_at DESC LIMIT 100");
    while ($row = $loginResult->fetchArray(SQLITE3_ASSOC)) $allLoginAttempts[] = $row;

    $apiResult = $db->query("SELECT a.*, u.username FROM api_keys a LEFT JOIN users u ON a.user_id = u.id ORDER BY a.created_at DESC");
    while ($row = $apiResult->fetchArray(SQLITE3_ASSOC)) $allApiKeys[] = $row;

    $codesResult = $db->query("SELECT c.*, u.username as used_by_name FROM subscription_codes c LEFT JOIN users u ON c.used_by = u.id ORDER BY c.created_at DESC");
    while ($row = $codesResult->fetchArray(SQLITE3_ASSOC)) $allSubscriptionCodes[] = $row;

    $adminStats['total_users'] = count($allUsers);
    $adminStats['total_downloads'] = (int)$db->querySingle("SELECT COUNT(*) FROM downloads");
    $adminStats['total_bypass'] = (int)$db->querySingle("SELECT COUNT(*) FROM bypass_logs");
    $adminStats['total_logins'] = (int)$db->querySingle("SELECT COUNT(*) FROM login_attempts");
    $adminStats['blocked_ips_count'] = (int)$db->querySingle("SELECT COUNT(*) FROM blocked_ips");
    $adminStats['total_api_keys'] = (int)$db->querySingle("SELECT COUNT(*) FROM api_keys");
    $adminStats['active_api_keys'] = (int)$db->querySingle("SELECT COUNT(*) FROM api_keys WHERE status = 'active'");
    $adminStats['total_codes'] = (int)$db->querySingle("SELECT COUNT(*) FROM subscription_codes");
    $adminStats['used_codes'] = (int)$db->querySingle("SELECT COUNT(*) FROM subscription_codes WHERE status = 'used'");
    $adminStats['available_codes'] = (int)$db->querySingle("SELECT COUNT(*) FROM subscription_codes WHERE status = 'active'");
}

// ============================================================================
// دوال المساعدة للواجهة
// ============================================================================
function getPlatformIcon($platform) {
    return match($platform) {
        'youtube'     => 'fa-brands fa-youtube',
        'instagram'   => 'fa-brands fa-instagram',
        'tiktok'      => 'fa-brands fa-tiktok',
        'facebook'    => 'fa-brands fa-facebook',
        'twitter'     => 'fa-brands fa-x-twitter',
        'snapchat'    => 'fa-brands fa-snapchat',
        'pinterest'   => 'fa-brands fa-pinterest',
        'vimeo'       => 'fa-brands fa-vimeo',
        'dailymotion' => 'fa-solid fa-play',
        default       => 'fa-solid fa-video'
    };
}

function getPlatformColor($platform) {
    return match($platform) {
        'youtube'     => '#ff0000',
        'instagram'   => '#e4405f',
        'tiktok'      => '#00f2fe',
        'facebook'    => '#1877f2',
        'twitter'     => '#1da1f2',
        'snapchat'    => '#fffc00',
        'pinterest'   => '#e60023',
        'vimeo'       => '#1ab7ea',
        'dailymotion' => '#00aaff',
        default       => '#f97316'
    };
}

function getStatusLabel($status) {
    return match($status) {
        'success'    => '<span style="color:#22c55e;font-weight:700;">✓ ناجح</span>',
        'failed'     => '<span style="color:#ef4444;font-weight:700;">✗ فاشل</span>',
        'processing' => '<span style="color:#f97316;font-weight:700;">⟳ معالجة</span>',
        default      => '<span style="color:#94a3b8;">غير معروف</span>'
    };
}

function timeAgo($datetime) {
    $time = strtotime($datetime);
    $now = time();
    $diff = max(0, $now - $time);
    if ($diff < 60) return 'الآن';
    if ($diff < 3600) return floor($diff / 60) . ' دقيقة';
    if ($diff < 86400) return floor($diff / 3600) . ' ساعة';
    if ($diff < 604800) return floor($diff / 86400) . ' يوم';
    return date('Y-m-d', $time);
}

function generateAdSenseCode($settings, $type = 'display') {
    $publisherId = $settings['adsense_publisher_id'] ?? '';
    if (empty($publisherId)) return '';

    $slot = '';
    if ($type === 'display') $slot = $settings['adsense_display_slot'] ?? '';
    elseif ($type === 'inarticle') $slot = $settings['adsense_inarticle_slot'] ?? '';
    elseif ($type === 'anchor') $slot = $settings['adsense_anchor_slot'] ?? '';

    if (empty($slot)) return '';
    $adClient = (strpos($publisherId, 'ca-') === 0) ? $publisherId : 'ca-' . $publisherId;

    if ($type === 'inarticle') {
        return '<ins class="adsbygoogle" style="display:block; text-align:center;" data-ad-layout="in-article" data-ad-format="fluid" data-ad-client="' . htmlspecialchars($adClient) . '" data-ad-slot="' . htmlspecialchars($slot) . '"></ins><script>(adsbygoogle = window.adsbygoogle || []).push({});</script>';
    }
    return '<ins class="adsbygoogle" style="display:block" data-ad-client="' . htmlspecialchars($adClient) . '" data-ad-slot="' . htmlspecialchars($slot) . '" data-ad-format="auto" data-full-width-responsive="true"></ins><script>(adsbygoogle = window.adsbygoogle || []).push({});</script>';
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="theme-color" content="#050508">
    <title>DOViD v5.0 - YOSSEF VID</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <?php if ($adsEnabled && !empty($settings['adsense_publisher_id'])): ?>
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=<?php echo htmlspecialchars((strpos($settings['adsense_publisher_id'], 'ca-') === 0 ? '' : 'ca-') . $settings['adsense_publisher_id']); ?>" crossorigin="anonymous"></script>
    <?php endif; ?>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@300;400;500;700;800;900&display=swap');

        :root {
            --primary: <?php echo htmlspecialchars($themeColor); ?>;
            --primary-dark: #ea580c;
            --primary-glow: <?php echo htmlspecialchars($themeColor); ?>66;
            --secondary: #ef4444;
            --bg: #050508;
            --surface: rgba(15, 15, 26, 0.88);
            --surface-hover: #16162a;
            --surface-light: #1a1a2e;
            --surface-lighter: #252540;
            --border: rgba(255,255,255,0.06);
            --border-hover: rgba(249,115,22,0.3);
            --text: #f8fafc;
            --text-muted: #94a3b8;
            --text-dim: #64748b;
            --success: #22c55e;
            --success-glow: rgba(34,197,94,0.3);
            --error: #ef4444;
            --error-glow: rgba(239,68,68,0.3);
            --warning: #f59e0b;
            --admin: #8b5cf6;
            --admin-glow: rgba(139,92,246,0.3);
            --guest: #06b6d4;
            --guest-glow: rgba(6,182,212,0.3);
            --api: #f59e0b;
            --api-glow: rgba(245,158,11,0.3);
            --radius: 22px;
            --radius-sm: 15px;
            --radius-xs: 11px;
            --shadow: 0 12px 40px rgba(0,0,0,0.5);
            --shadow-glow: 0 0 45px rgba(249,115,22,0.16);
            --transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            --transition-fast: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }

        body {
            font-family: 'Tajawal', sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            min-height: 100dvh;
            overflow-x: hidden;
            font-size: 14px;
            line-height: 1.6;
        }

        .bg-animated {
            position: fixed;
            inset: 0;
            z-index: -2;
            background: radial-gradient(circle at 50% 0%, rgba(249,115,22,0.08), transparent 60%), var(--bg);
            overflow: hidden;
        }

        .bg-animated::before {
            content: '';
            position: absolute;
            width: 650px;
            height: 650px;
            background: radial-gradient(circle, rgba(249,115,22,0.13) 0%, transparent 70%);
            top: -220px;
            right: -200px;
            animation: float-orb 18s ease-in-out infinite;
        }

        .bg-animated::after {
            content: '';
            position: absolute;
            width: 550px;
            height: 550px;
            background: radial-gradient(circle, rgba(139,92,246,0.09) 0%, transparent 70%);
            bottom: -180px;
            left: -150px;
            animation: float-orb 22s ease-in-out infinite reverse;
        }

        @keyframes float-orb {
            0%, 100% { transform: translate(0, 0) scale(1); }
            33% { transform: translate(40px, -35px) scale(1.12); }
            66% { transform: translate(-25px, 25px) scale(0.92); }
        }

        .bg-grid {
            position: fixed;
            inset: 0;
            z-index: -1;
            background-image: 
                linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px);
            background-size: 45px 45px;
            mask-image: radial-gradient(ellipse at center, black 45%, transparent 85%);
            -webkit-mask-image: radial-gradient(ellipse at center, black 45%, transparent 85%);
        }

        .app-container {
            max-width: 500px;
            margin: 0 auto;
            padding: 14px;
            min-height: 100dvh;
            display: flex;
            flex-direction: column;
            position: relative;
        }

        .app-container-wide {
            max-width: 960px;
            margin: 0 auto;
            padding: 14px;
            min-height: 100dvh;
            display: flex;
            flex-direction: column;
            position: relative;
        }

        .bottom-nav {
            position: fixed;
            bottom: 14px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(15,15,26,0.88);
            backdrop-filter: blur(28px) saturate(1.8);
            -webkit-backdrop-filter: blur(28px) saturate(1.8);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 26px;
            padding: 8px 14px;
            display: flex;
            gap: 6px;
            z-index: 100;
            box-shadow: 0 12px 40px rgba(0,0,0,0.65), 0 0 20px rgba(249,115,22,0.08);
            max-width: calc(100% - 24px);
        }

        .nav-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 4px;
            padding: 8px 20px;
            border-radius: 18px;
            color: var(--text-muted);
            text-decoration: none;
            font-size: 10.5px;
            font-weight: 700;
            transition: var(--transition-fast);
            position: relative;
            cursor: pointer;
        }

        .nav-item i { font-size: 18px; transition: var(--transition); }
        .nav-item:hover { color: var(--text); background: rgba(255,255,255,0.04); }
        .nav-item.active { color: var(--primary); background: linear-gradient(135deg, rgba(249,115,22,0.18), rgba(239,68,68,0.08)); }
        .nav-item.active i { transform: translateY(-3px) scale(1.08); filter: drop-shadow(0 0 10px var(--primary-glow)); }
        .nav-item.admin-nav { color: var(--admin); }
        .nav-item.admin-nav.active { color: var(--admin); background: linear-gradient(135deg, rgba(139,92,246,0.18), rgba(139,92,246,0.08)); }
        .nav-item.admin-nav.active i { filter: drop-shadow(0 0 10px var(--admin-glow)); }

        .nav-indicator {
            position: absolute;
            bottom: 4px;
            width: 14px;
            height: 3px;
            border-radius: 4px;
            background: var(--primary);
            opacity: 0;
            transition: var(--transition-fast);
        }
        .nav-item.active .nav-indicator { opacity: 1; }

        .page-content {
            flex: 1;
            padding-bottom: 95px;
            animation: fadeInUp 0.55s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes fadeInUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes scaleIn { from { opacity: 0; transform: scale(0.92); } to { opacity: 1; transform: scale(1); } }
        @keyframes slideInRight { from { opacity: 0; transform: translateX(-20px); } to { opacity: 1; transform: translateX(0); } }
        @keyframes pulse-glow { 0%, 100% { box-shadow: 0 0 20px rgba(249,115,22,0.25); } 50% { box-shadow: 0 0 45px rgba(249,115,22,0.5); } }
        @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
        @keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-7px); } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        @keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-6px); } 75% { transform: translateX(6px); } }

        .app-header { text-align: center; padding: 18px 0 14px; position: relative; }

        .logo-container {
            position: relative;
            width: 88px;
            height: 88px;
            margin: 0 auto 14px;
        }

        .logo-glow {
            position: absolute;
            inset: -12px;
            border-radius: 30px;
            background: linear-gradient(135deg, var(--secondary), var(--primary), #ff6b35);
            opacity: 0.45;
            filter: blur(22px);
            animation: pulse-glow 3s ease-in-out infinite;
        }

        .logo-ring {
            width: 88px;
            height: 88px;
            border-radius: 26px;
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            box-shadow: 0 12px 40px rgba(249,115,22,0.4), inset 0 2px 4px rgba(255,255,255,0.2);
            animation: float 4s ease-in-out infinite;
            overflow: hidden;
        }

        .logo-text {
            font-size: 30px;
            font-weight: 900;
            color: white;
            letter-spacing: -1.5px;
            z-index: 2;
            text-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }

        .app-title {
            font-size: 25px;
            font-weight: 900;
            margin-bottom: 4px;
            background: linear-gradient(135deg, #fff 20%, var(--primary) 85%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .app-subtitle {
            font-size: 11px;
            color: var(--text-muted);
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .app-subtitle::before, .app-subtitle::after {
            content: '';
            width: 24px;
            height: 1px;
            background: linear-gradient(90deg, transparent, var(--border-hover));
        }
        .app-subtitle::after { background: linear-gradient(90deg, var(--border-hover), transparent); }

        .card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 18px;
            margin-bottom: 14px;
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            box-shadow: var(--shadow);
            transition: var(--transition-fast);
            position: relative;
            overflow: hidden;
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.12), transparent);
        }

        .card:hover {
            border-color: var(--border-hover);
            box-shadow: var(--shadow), var(--shadow-glow);
        }

        .card-header { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
        .card-icon {
            width: 38px;
            height: 38px;
            border-radius: 12px;
            background: linear-gradient(135deg, rgba(249,115,22,0.18), rgba(239,68,68,0.1));
            border: 1px solid rgba(249,115,22,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
            font-size: 15px;
        }
        .card-title { font-size: 15px; font-weight: 800; color: var(--text); }

        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 14px; }
        .stats-grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 14px; }
        .stats-grid-5 { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin-bottom: 14px; }

        .stat-box {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 14px 8px;
            text-align: center;
            position: relative;
            overflow: hidden;
            transition: var(--transition-fast);
        }
        .stat-box:hover { border-color: var(--border-hover); transform: translateY(-3px); }
        .stat-value {
            font-size: 22px;
            font-weight: 900;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .stat-label { font-size: 10.5px; color: var(--text-muted); margin-top: 3px; font-weight: 600; }

        .smart-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: linear-gradient(135deg, rgba(249,115,22,0.15), rgba(239,68,68,0.08));
            border: 1px solid rgba(249,115,22,0.22);
            color: var(--primary);
            padding: 5px 14px;
            border-radius: 24px;
            font-size: 11px;
            font-weight: 800;
        }
        .smart-badge i { font-size: 11px; animation: blink 1.8s infinite; }

        .input-group { position: relative; margin-bottom: 14px; display: flex; gap: 8px; }
        .input-wrapper { position: relative; flex: 1; }
        .input-wrapper i.prefix-icon {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-dim);
            font-size: 15px;
            pointer-events: none;
            transition: var(--transition-fast);
        }

        .url-input {
            width: 100%;
            padding: 15px 44px 15px 14px;
            background: var(--surface-light);
            border: 1.5px solid var(--border);
            border-radius: var(--radius-sm);
            color: var(--text);
            font-family: inherit;
            font-size: 13px;
            text-align: right;
            transition: var(--transition-fast);
            outline: none;
        }
        .url-input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 4px rgba(249,115,22,0.1);
            background: var(--surface-lighter);
        }
        .url-input:focus ~ i.prefix-icon { color: var(--primary); }

        .paste-btn {
            padding: 0 15px;
            border-radius: var(--radius-sm);
            background: var(--surface-light);
            border: 1.5px solid var(--border);
            color: var(--primary);
            font-family: inherit;
            font-size: 12px;
            font-weight: 800;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: var(--transition-fast);
            flex-shrink: 0;
        }
        .paste-btn:hover {
            border-color: var(--primary);
            background: rgba(249,115,22,0.12);
            transform: translateY(-1px);
        }

        .quality-scroll {
            display: flex;
            gap: 8px;
            margin-bottom: 14px;
            overflow-x: auto;
            padding-bottom: 4px;
            scrollbar-width: none;
        }
        .quality-scroll::-webkit-scrollbar { display: none; }

        .quality-chip {
            flex-shrink: 0;
            padding: 8px 15px;
            border-radius: 24px;
            border: 1.5px solid var(--border);
            background: var(--surface-light);
            color: var(--text-muted);
            font-size: 11px;
            font-weight: 700;
            cursor: pointer;
            transition: var(--transition-fast);
            display: flex;
            align-items: center;
            gap: 6px;
            position: relative;
            overflow: hidden;
        }
        .quality-chip::before {
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            opacity: 0;
            transition: opacity 0.25s;
            z-index: 0;
        }
        .quality-chip span, .quality-chip i { position: relative; z-index: 1; }
        .quality-chip:hover { border-color: rgba(249,115,22,0.35); color: var(--text); }
        .quality-chip.active { border-color: transparent; color: white; box-shadow: 0 4px 18px rgba(249,115,22,0.35); transform: scale(1.03); }
        .quality-chip.active::before { opacity: 1; }

        .dl-btn {
            width: 100%;
            padding: 16px;
            border: none;
            border-radius: var(--radius-sm);
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            color: white;
            font-family: inherit;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            position: relative;
            overflow: hidden;
            transition: var(--transition-fast);
            box-shadow: 0 6px 26px rgba(249,115,22,0.3);
        }
        .dl-btn:hover { transform: translateY(-2px); box-shadow: 0 10px 34px rgba(249,115,22,0.45); }
        .dl-btn:active { transform: scale(0.98); }
        .dl-btn:disabled { opacity: 0.65; cursor: not-allowed; transform: none; }

        .loading-state {
            display: none;
            flex-direction: column;
            align-items: center;
            padding: 22px 0 10px;
            gap: 12px;
            animation: fadeIn 0.3s ease-out;
        }
        .loading-state.show { display: flex; }

        .spinner-ring {
            width: 44px;
            height: 44px;
            position: relative;
        }
        .spinner-ring::before, .spinner-ring::after {
            content: '';
            position: absolute;
            inset: 0;
            border-radius: 50%;
            border: 3px solid transparent;
        }
        .spinner-ring::before {
            border-top-color: var(--primary);
            border-right-color: rgba(249,115,22,0.3);
            animation: spin 0.9s linear infinite;
        }
        .spinner-ring::after {
            inset: 6px;
            border-bottom-color: var(--secondary);
            border-left-color: rgba(239,68,68,0.3);
            animation: spin 1.3s linear infinite reverse;
        }

        .loading-text { font-size: 13px; color: var(--primary); font-weight: 700; }
        .strategy-pill {
            font-size: 10px;
            color: var(--text-muted);
            background: var(--surface-light);
            padding: 4px 12px;
            border-radius: 12px;
            border: 1px solid var(--border);
        }

        .result-box {
            display: none;
            margin-top: 16px;
            padding: 18px;
            background: linear-gradient(135deg, rgba(34,197,94,0.08), rgba(34,197,94,0.02));
            border: 1px solid rgba(34,197,94,0.22);
            border-radius: var(--radius-sm);
            animation: scaleIn 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .result-box.show { display: block; }

        .result-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
        .result-icon {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: var(--success);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            box-shadow: 0 0 16px var(--success-glow);
        }
        .result-icon i { color: white; font-size: 13px; }
        .result-title { font-size: 14px; font-weight: 800; color: var(--success); }
        .result-video-title { font-size: 13px; font-weight: 700; color: var(--text); margin-bottom: 10px; }
        .result-meta {
            font-size: 11px;
            color: var(--text-muted);
            margin-bottom: 14px;
            display: flex;
            gap: 14px;
            flex-wrap: wrap;
        }
        .result-meta span { display: flex; align-items: center; gap: 5px; }
        .result-actions { display: flex; gap: 10px; }

        .btn-action {
            flex: 1;
            padding: 12px;
            border-radius: var(--radius-xs);
            font-family: inherit;
            font-size: 12px;
            font-weight: 800;
            cursor: pointer;
            border: none;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            transition: var(--transition-fast);
            text-decoration: none;
        }
        .btn-primary { background: white; color: #0f172a; box-shadow: 0 4px 14px rgba(255,255,255,0.12); }
        .btn-primary:hover { background: #f1f5f9; transform: translateY(-2px); }
        .btn-secondary { background: var(--surface-light); color: var(--text); border: 1px solid var(--border); }
        .btn-secondary:hover { border-color: var(--border-hover); background: var(--surface-lighter); }

        .error-box {
            display: none;
            margin-top: 14px;
            padding: 14px 16px;
            background: linear-gradient(135deg, rgba(239,68,68,0.08), rgba(239,68,68,0.02));
            border: 1px solid rgba(239,68,68,0.2);
            border-radius: var(--radius-sm);
            align-items: center;
            gap: 10px;
            animation: shake 0.4s ease-out;
        }
        .error-box.show { display: flex; }
        .error-box i { color: var(--error); font-size: 18px; flex-shrink: 0; }
        .error-text { font-size: 12px; color: #fca5a5; }

        .platforms-section { padding: 14px 0; }
        .platforms-grid { display: flex; justify-content: center; gap: 18px; flex-wrap: wrap; }
        .platform-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
            opacity: 0.45;
            transition: var(--transition-fast);
        }
        .platform-item:hover, .platform-item.active { opacity: 1; transform: translateY(-4px); }
        .platform-item i { font-size: 24px; transition: var(--transition-fast); }
        .platform-item.active i { filter: drop-shadow(0 0 10px currentColor); transform: scale(1.15); }
        .platform-item span { font-size: 9.5px; color: var(--text-muted); font-weight: 700; }

        .history-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
        .history-title { font-size: 14px; font-weight: 800; display: flex; align-items: center; gap: 8px; }
        .history-title i { color: var(--primary); }
        .history-count {
            font-size: 10px;
            color: var(--text-muted);
            background: var(--surface-light);
            padding: 3px 10px;
            border-radius: 12px;
            border: 1px solid var(--border);
        }
        .history-list { display: flex; flex-direction: column; gap: 8px; }
        .history-item {
            background: var(--surface-light);
            border: 1px solid var(--border);
            border-radius: var(--radius-xs);
            padding: 14px;
            display: flex;
            align-items: flex-start;
            gap: 12px;
            transition: var(--transition-fast);
        }
        .history-item:hover { border-color: var(--border-hover); background: var(--surface-hover); transform: translateX(-4px); }

        .history-platform {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            background: var(--surface);
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            font-size: 16px;
        }
        .history-content { flex: 1; min-width: 0; }
        .history-title-text {
            font-size: 12.5px;
            font-weight: 700;
            color: var(--text);
            margin-bottom: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .history-url {
            font-size: 10px;
            color: var(--text-dim);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            direction: ltr;
            text-align: left;
            margin-bottom: 6px;
        }
        .history-footer { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .history-tag {
            font-size: 9.5px;
            padding: 2px 8px;
            border-radius: 8px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .tag-platform { background: rgba(249,115,22,0.12); color: var(--primary); border: 1px solid rgba(249,115,22,0.2); }
        .tag-quality { background: rgba(34,197,94,0.12); color: var(--success); border: 1px solid rgba(34,197,94,0.2); }
        .tag-time { background: var(--surface); color: var(--text-dim); border: 1px solid var(--border); }
        .history-status { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
        .history-status.success { background: var(--success); box-shadow: 0 0 8px var(--success-glow); }
        .history-status.failed { background: var(--error); box-shadow: 0 0 8px var(--error-glow); }
        .history-status.processing { background: var(--primary); animation: blink 1s infinite; }

        .history-actions { display: flex; gap: 6px; margin-top: 8px; }
        .history-btn {
            padding: 6px 12px;
            border-radius: 8px;
            font-size: 10.5px;
            font-weight: 700;
            border: none;
            cursor: pointer;
            font-family: inherit;
            transition: var(--transition-fast);
            display: inline-flex;
            align-items: center;
            gap: 4px;
            text-decoration: none;
        }
        .history-btn-primary { background: linear-gradient(135deg, var(--secondary), var(--primary)); color: white; }
        .history-btn-secondary { background: var(--surface); color: var(--text-muted); border: 1px solid var(--border); }
        .history-btn-danger { background: rgba(239,68,68,0.12); color: var(--error); border: 1px solid rgba(239,68,68,0.25); }

        .empty-state { text-align: center; padding: 38px 20px; color: var(--text-dim); }
        .empty-state i { font-size: 38px; margin-bottom: 10px; opacity: 0.35; }

        .settings-group { margin-bottom: 18px; }
        .settings-label {
            font-size: 12px;
            font-weight: 700;
            color: var(--text-muted);
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .settings-input {
            width: 100%;
            padding: 13px 15px;
            background: var(--surface-light);
            border: 1.5px solid var(--border);
            border-radius: var(--radius-xs);
            color: var(--text);
            font-family: inherit;
            font-size: 13px;
            outline: none;
        }
        .settings-input:focus { border-color: var(--primary); }
        .settings-hint { font-size: 10px; color: var(--text-dim); margin-top: 5px; }

        .dev-profile {
            background: linear-gradient(135deg, var(--surface), var(--surface-light));
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 22px;
            text-align: center;
            margin-bottom: 18px;
            position: relative;
            overflow: hidden;
        }
        .dev-profile::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: linear-gradient(90deg, var(--secondary), var(--primary), var(--secondary));
            background-size: 200% 100%;
            animation: shimmer 3s linear infinite;
        }
        .dev-avatar-large {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 900;
            font-size: 24px;
            color: white;
            margin: 0 auto 12px;
            box-shadow: 0 8px 30px rgba(249,115,22,0.35);
            animation: float 4s ease-in-out infinite;
        }
        .dev-name-large { font-size: 18px; font-weight: 900; margin-bottom: 4px; }
        .dev-role { font-size: 11px; color: var(--primary); font-weight: 700; margin-bottom: 12px; }
        .dev-contact-row {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-size: 13px;
            color: var(--text-muted);
            margin-bottom: 14px;
        }
        .dev-contact-row i { color: #25d366; font-size: 16px; }
        .dev-social { display: flex; justify-content: center; gap: 10px; }
        .social-btn {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            background: var(--surface-light);
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
            font-size: 16px;
            transition: var(--transition-fast);
            text-decoration: none;
        }
        .social-btn:hover { background: var(--primary); color: white; transform: translateY(-3px); }

        .save-btn {
            width: 100%;
            padding: 15px;
            border: none;
            border-radius: var(--radius-sm);
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            color: white;
            font-family: inherit;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
            transition: var(--transition-fast);
            box-shadow: 0 4px 24px rgba(249,115,22,0.25);
        }

        .alert {
            padding: 12px 16px;
            border-radius: var(--radius-xs);
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .alert-success { background: rgba(34,197,94,0.12); border: 1px solid rgba(34,197,94,0.25); color: var(--success); }
        .alert-error { background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.25); color: var(--error); }
        .alert-warning { background: rgba(245,158,11,0.12); border: 1px solid rgba(245,158,11,0.25); color: var(--warning); }
        .alert-guest { background: rgba(6,182,212,0.12); border: 1px solid rgba(6,182,212,0.25); color: var(--guest); }

        .toast-container {
            position: fixed;
            bottom: 92px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 1000;
            pointer-events: none;
        }
        .toast {
            background: var(--surface-light);
            border: 1px solid var(--border-hover);
            color: var(--text);
            padding: 12px 22px;
            border-radius: var(--radius-sm);
            font-size: 13px;
            font-weight: 700;
            opacity: 0;
            transform: translateY(20px) scale(0.9);
            transition: all 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            display: flex;
            align-items: center;
            gap: 10px;
            box-shadow: 0 10px 35px rgba(0,0,0,0.6);
            white-space: nowrap;
        }
        .toast.show { opacity: 1; transform: translateY(0) scale(1); }
        .toast i { color: var(--success); font-size: 16px; }

        .clear-btn {
            padding: 9px 18px;
            border-radius: var(--radius-xs);
            border: 1px solid rgba(239,68,68,0.3);
            background: rgba(239,68,68,0.1);
            color: var(--error);
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            text-decoration: none;
        }

        /* Auth Styles */
        .auth-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100dvh;
            padding: 20px;
        }
        .auth-box {
            width: 100%;
            max-width: 410px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 32px 24px;
            box-shadow: var(--shadow);
            position: relative;
            overflow: hidden;
        }
        .auth-box::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: linear-gradient(90deg, var(--secondary), var(--primary));
        }
        .auth-title {
            font-size: 23px;
            font-weight: 900;
            text-align: center;
            margin-bottom: 6px;
            background: linear-gradient(135deg, #fff 20%, var(--primary) 80%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .auth-subtitle { font-size: 12px; color: var(--text-muted); text-align: center; margin-bottom: 22px; }
        .auth-input {
            width: 100%;
            padding: 14px 16px;
            background: var(--surface-light);
            border: 1.5px solid var(--border);
            border-radius: var(--radius-xs);
            color: var(--text);
            font-family: inherit;
            font-size: 14px;
            margin-bottom: 12px;
            outline: none;
        }
        .auth-input:focus { border-color: var(--primary); }
        .auth-btn {
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: var(--radius-xs);
            background: linear-gradient(135deg, var(--secondary), var(--primary));
            color: white;
            font-family: inherit;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
            box-shadow: 0 4px 24px rgba(249,115,22,0.28);
            margin-bottom: 14px;
        }
        .auth-switch { text-align: center; font-size: 12px; color: var(--text-muted); }
        .auth-switch a { color: var(--primary); font-weight: 700; text-decoration: none; }

        .guest-btn {
            width: 100%;
            padding: 13px;
            border: 1.5px dashed var(--guest);
            border-radius: var(--radius-xs);
            background: rgba(6,182,212,0.06);
            color: var(--guest);
            font-family: inherit;
            font-size: 14px;
            font-weight: 800;
            cursor: pointer;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .divider {
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 14px 0;
            color: var(--text-dim);
            font-size: 11px;
        }
        .divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: var(--border); }

        .user-badge, .admin-user-badge, .guest-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 14px;
            border-radius: 24px;
            font-size: 11px;
            font-weight: 700;
        }
        .user-badge { background: rgba(249,115,22,0.12); border: 1px solid rgba(249,115,22,0.2); color: var(--primary); }
        .admin-user-badge { background: rgba(139,92,246,0.12); border: 1px solid rgba(139,92,246,0.25); color: var(--admin); }
        .guest-badge { background: rgba(6,182,212,0.12); border: 1px solid rgba(6,182,212,0.25); color: var(--guest); }

        .logout-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(239,68,68,0.1);
            border: 1px solid rgba(239,68,68,0.25);
            color: var(--error);
            padding: 9px 18px;
            border-radius: var(--radius-xs);
            font-size: 12px;
            font-weight: 700;
            text-decoration: none;
        }

        /* Admin Styles */
        .admin-tabs { display: flex; gap: 8px; margin-bottom: 18px; overflow-x: auto; scrollbar-width: none; padding-bottom: 4px; }
        .admin-tabs::-webkit-scrollbar { display: none; }
        .admin-tab {
            padding: 10px 16px;
            border-radius: 12px;
            border: 1px solid var(--border);
            background: var(--surface-light);
            color: var(--text-muted);
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .admin-tab.active {
            background: linear-gradient(135deg, var(--admin), #7c3aed);
            color: white;
            border-color: transparent;
            box-shadow: 0 4px 18px rgba(139,92,246,0.35);
        }

        .data-table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .data-table th {
            text-align: right;
            padding: 12px 10px;
            color: var(--text-muted);
            font-weight: 700;
            font-size: 11px;
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
        }
        .data-table td {
            padding: 12px 10px;
            border-bottom: 1px solid var(--border);
            color: var(--text);
            vertical-align: middle;
        }
        .table-scroll { overflow-x: auto; border-radius: var(--radius-xs); border: 1px solid var(--border); background: var(--surface-light); }

        .admin-stat-box {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 15px 10px;
            text-align: center;
        }
        .admin-stat-value {
            font-size: 22px;
            font-weight: 900;
            background: linear-gradient(135deg, var(--admin), #a78bfa);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .admin-stat-label { font-size: 10px; color: var(--text-muted); margin-top: 4px; }
        .admin-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 18px; margin-bottom: 14px; }
        .admin-card-header { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; padding-bottom: 12px; border-bottom: 1px solid var(--border); }
        .admin-card-icon {
            width: 36px; height: 36px; border-radius: 12px;
            background: rgba(139,92,246,0.15); border: 1px solid rgba(139,92,246,0.2);
            display: flex; align-items: center; justify-content: center; color: var(--admin);
        }
        .admin-card-title { font-size: 15px; font-weight: 800; }
        .ip-badge { font-family: monospace; font-size: 11px; background: var(--surface); padding: 3px 8px; border-radius: 6px; border: 1px solid var(--border); color: var(--text-muted); }
        .truncate { max-width: 160px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: inline-block; }

        /* Toggle Switch */
        .toggle-switch { position: relative; display: inline-block; width: 50px; height: 26px; }
        .toggle-switch input { opacity: 0; width: 0; height: 0; }
        .toggle-slider { position: absolute; cursor: pointer; inset: 0; background: var(--surface-lighter); border-radius: 26px; transition: 0.3s; border: 1px solid var(--border); }
        .toggle-slider::before { position: absolute; content: ''; height: 20px; width: 20px; left: 3px; bottom: 2px; background: white; border-radius: 50%; transition: 0.3s; }
        .toggle-switch input:checked + .toggle-slider { background: var(--success); border-color: var(--success); }
        .toggle-switch input:checked + .toggle-slider::before { transform: translateX(24px); }

        /* API Box */
        .api-key-box {
            background: linear-gradient(135deg, rgba(245,158,11,0.08), rgba(245,158,11,0.02));
            border: 1.5px solid rgba(245,158,11,0.22);
            border-radius: var(--radius-sm);
            padding: 16px;
            margin-bottom: 14px;
        }
        .api-key-display {
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 12px 14px;
            font-family: monospace;
            font-size: 12px;
            color: var(--api);
            direction: ltr;
            text-align: left;
            margin-bottom: 10px;
            word-break: break-all;
            position: relative;
        }
        .api-key-display .copy-icon {
            position: absolute; top: 8px; right: 8px;
            background: var(--surface-light); border: 1px solid var(--border);
            border-radius: 6px; padding: 4px 8px; font-size: 10px; cursor: pointer; color: var(--text-muted);
        }
        .subscription-timer {
            display: flex; align-items: center; gap: 8px;
            background: var(--bg); border: 1px solid var(--border);
            border-radius: 10px; padding: 12px 14px; margin-bottom: 12px;
        }
        .timer-item { text-align: center; flex: 1; }
        .timer-value { font-size: 20px; font-weight: 900; color: var(--api); }
        .timer-label { font-size: 9px; color: var(--text-muted); }
        .timer-separator { font-size: 18px; font-weight: 900; color: var(--text-dim); }
        .code-input {
            width: 100%; padding: 15px; background: var(--surface-light);
            border: 2px dashed var(--border); border-radius: var(--radius-xs);
            color: var(--text); font-family: monospace; font-size: 15px;
            text-align: center; letter-spacing: 2px; text-transform: uppercase; outline: none;
        }
        .price-tag {
            display: inline-flex; align-items: center; gap: 6px;
            background: rgba(245,158,11,0.12); border: 1px solid rgba(245,158,11,0.25);
            color: var(--api); padding: 8px 16px; border-radius: 24px; font-size: 14px; font-weight: 800; margin-bottom: 14px;
        }
        .cash-number {
            background: var(--bg); border: 1px solid var(--border); border-radius: 10px;
            padding: 12px 16px; display: flex; align-items: center; gap: 10px; margin-bottom: 14px;
        }
        .api-docs { background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius-xs); padding: 15px; margin-top: 14px; }
        .api-docs pre { background: var(--surface); border-radius: 8px; padding: 12px; overflow-x: auto; font-size: 11px; direction: ltr; text-align: left; color: var(--text-muted); }
        .api-docs h4 { color: var(--text); font-size: 13px; margin: 12px 0 8px; }
        .api-docs h4:first-child { margin-top: 0; }
        .generated-codes-box { background: var(--bg); border: 1.5px solid var(--border); border-radius: var(--radius-xs); padding: 16px; margin-top: 14px; }
        .generated-code-item {
            background: var(--surface-light); border: 1px solid var(--border); border-radius: 8px;
            padding: 10px 14px; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between;
            font-family: monospace; font-size: 13px; color: var(--api); direction: ltr;
        }
    </style>
</head>
<body>
    <div class="bg-animated"></div>
    <div class="bg-grid"></div>

    <?php if ($isPublicPage): ?>
    <!-- ==================== صفحة تسجيل الدخول / التسجيل ==================== -->
    <div class="auth-container">
        <div class="auth-box">
            <div class="logo-container" style="margin-bottom:18px;">
                <div class="logo-glow"></div>
                <div class="logo-ring">
                    <span class="logo-text">DV</span>
                </div>
            </div>
            <h1 class="auth-title">DOViD</h1>
            <p class="auth-subtitle">نظام التحميل الذكي فائق السرعة v5.0</p>

            <?php if ($page === 'register'): ?>
            <form method="POST" action="?page=register">
                <?php if ($registerError): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo htmlspecialchars($registerError); ?>
                </div>
                <?php endif; ?>
                <input type="text" name="username" class="auth-input" placeholder="اسم المستخدم (3 أحرف على الأقل)" required minlength="3" autocomplete="off">
                <input type="email" name="email" class="auth-input" placeholder="البريد الإلكتروني (اختياري)" autocomplete="off">
                <input type="password" name="password" class="auth-input" placeholder="كلمة المرور (4 أحرف على الأقل)" required minlength="4">
                <button type="submit" name="register" class="auth-btn">
                    <i class="fas fa-user-plus"></i> إنشاء حساب جديد
                </button>
                <div class="auth-switch">
                    لديك حساب بالفعل؟ <a href="?page=login">تسجيل الدخول</a>
                </div>
            </form>
            <?php else: ?>
            <form method="POST" action="?page=login">
                <?php if ($loginError): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo htmlspecialchars($loginError); ?>
                </div>
                <?php endif; ?>
                <input type="text" name="username" class="auth-input" placeholder="اسم المستخدم" required autocomplete="off">
                <input type="password" name="password" class="auth-input" placeholder="كلمة المرور" required>
                <button type="submit" name="login" class="auth-btn">
                    <i class="fas fa-sign-in-alt"></i> تسجيل الدخول
                </button>
            </form>

            <div class="divider">أو</div>

            <form method="POST" action="?page=login">
                <button type="submit" name="guest_login" class="guest-btn">
                    <i class="fas fa-user-secret"></i> متابعة كزائر بدون حساب
                </button>
            </form>

            <div class="auth-switch">
                ليس لديك حساب؟ <a href="?page=register">إنشاء حساب جديد</a>
            </div>
            <?php endif; ?>

            <div style="text-align:center; margin-top:22px; padding-top:14px; border-top:1px solid var(--border);">
                <p style="font-size:11px; color:var(--text-dim);">
                    <i class="fas fa-code" style="color:var(--primary); margin-left:4px;"></i>
                    DOViD Platform - Powered by <?php echo htmlspecialchars(DEV_NAME); ?>
                </p>
                <p style="font-size:10px; color:var(--text-dim); margin-top:4px;">
                    <i class="fab fa-whatsapp" style="color:#25d366; margin-left:4px;"></i>
                    <?php echo htmlspecialchars(DEV_WHATSAPP); ?>
                </p>
            </div>
        </div>
    </div>

    <?php else: ?>
    <!-- ==================== التطبيق الرئيسي ==================== -->
    <div class="<?php echo ($page === 'admin') ? 'app-container-wide' : 'app-container'; ?>">
        <div class="page-content">
            <?php if ($page === 'home'): ?>
            <!-- ==================== الصفحة الرئيسية ==================== -->
            <header class="app-header">
                <div style="display:flex; align-items:center; justify-content:center; gap:10px; margin-bottom:10px;">
                    <?php if ($isAdmin): ?>
                    <span class="admin-user-badge">
                        <i class="fas fa-shield-alt"></i>
                        <?php echo htmlspecialchars($_SESSION['username'] ?? 'مدير'); ?> (Admin)
                    </span>
                    <?php elseif ($isGuest): ?>
                    <span class="guest-badge">
                        <i class="fas fa-user-secret"></i>
                        <?php echo htmlspecialchars($_SESSION['username'] ?? 'زائر'); ?> (Guest)
                    </span>
                    <?php else: ?>
                    <span class="user-badge">
                        <i class="fas fa-user"></i>
                        <?php echo htmlspecialchars($_SESSION['username'] ?? 'مستخدم'); ?>
                    </span>
                    <?php endif; ?>
                </div>
                <div class="logo-container">
                    <div class="logo-glow"></div>
                    <div class="logo-ring">
                        <span class="logo-text">DV</span>
                    </div>
                </div>
                <h1 class="app-title">DOViD</h1>
                <p class="app-subtitle">YOSSEF VID</p>
            </header>

            <?php if ($adsEnabled && !empty($settings['adsense_display_slot'])): ?>
            <div class="card" style="padding:8px; margin-bottom:10px;">
                <?php echo generateAdSenseCode($settings, 'display'); ?>
            </div>
            <?php endif; ?>

            <div class="stats-grid">
                <div class="stat-box">
                    <div class="stat-value" id="homeStatTotal"><?php echo $stats['total']; ?></div>
                    <div class="stat-label">الإجمالي</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="homeStatSuccess" style="background: linear-gradient(135deg, var(--success), #4ade80); -webkit-background-clip: text;"><?php echo $stats['success']; ?></div>
                    <div class="stat-label">ناجح</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="homeStatFailed" style="background: linear-gradient(135deg, var(--error), #f87171); -webkit-background-clip: text;"><?php echo $stats['failed']; ?></div>
                    <div class="stat-label">فاشل</div>
                </div>
            </div>

            <div class="card">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
                    <div class="smart-badge">
                        <i class="fas fa-bolt"></i> DOViD Pro v5.0
                    </div>
                    <span style="font-size:10px; color:var(--text-dim);"><i class="fas fa-shield-halved" style="color:var(--success);"></i> 6 محركات تخطي نشطة</span>
                </div>

                <div class="input-group">
                    <div class="input-wrapper">
                        <input type="text" id="videoUrl" class="url-input" 
                            placeholder="الصق رابط الفيديو (YouTube, TikTok, Instagram...)" 
                            autocomplete="off" dir="ltr">
                        <i class="fas fa-link prefix-icon"></i>
                    </div>
                    <button type="button" class="paste-btn" onclick="pasteFromClipboard()" title="لصق من الحافظة">
                        <i class="fas fa-paste"></i> لصق
                    </button>
                </div>

                <div class="quality-scroll">
                    <div class="quality-chip <?php echo $defaultQuality === 'auto' ? 'active' : ''; ?>" data-quality="auto">
                        <i class="fas fa-magic"></i> <span>تلقائي</span>
                    </div>
                    <div class="quality-chip <?php echo $defaultQuality === '4k' ? 'active' : ''; ?>" data-quality="4k">
                        <i class="fas fa-star"></i> <span>4K Ultra</span>
                    </div>
                    <div class="quality-chip <?php echo $defaultQuality === '1080' ? 'active' : ''; ?>" data-quality="1080">
                        <i class="fas fa-tv"></i> <span>FHD 1080p</span>
                    </div>
                    <div class="quality-chip <?php echo $defaultQuality === '720' ? 'active' : ''; ?>" data-quality="720">
                        <i class="fas fa-mobile-alt"></i> <span>HD 720p</span>
                    </div>
                    <div class="quality-chip <?php echo $defaultQuality === 'audio' ? 'active' : ''; ?>" data-quality="audio">
                        <i class="fas fa-music"></i> <span>صوت MP3</span>
                    </div>
                </div>

                <button id="downloadBtn" class="dl-btn" onclick="handleDownload()">
                    <span id="btnText">تحميل الفيديو الآن</span>
                    <i class="fas fa-download"></i>
                </button>

                <!-- Loading -->
                <div id="loadingBox" class="loading-state">
                    <div class="spinner-ring"></div>
                    <p class="loading-text" id="loadingText">جاري الاتصال بالسيرفر الذكي...</p>
                    <span class="strategy-pill" id="strategyTag">محرك التخطي النشط: Multi-Bypass Engine</span>
                </div>

                <!-- Result -->
                <div id="resultBox" class="result-box">
                    <div class="result-header">
                        <div class="result-icon"><i class="fas fa-check"></i></div>
                        <span class="result-title">تم استخراج الرابط بنجاح!</span>
                    </div>
                    <div id="resTitle" class="result-video-title"></div>
                    <div class="result-meta">
                        <span><i class="fas fa-video"></i> <span id="resPlatform">YouTube</span></span>
                        <span><i class="fas fa-gem"></i> <span id="resQuality">HD</span></span>
                        <span><i class="fas fa-route"></i> <span id="resStrategy">Direct</span></span>
                    </div>
                    <div class="result-actions">
                        <a id="finalDownloadLink" href="#" class="btn-action btn-primary">
                            <i class="fas fa-download"></i> تنزيل مباشر للجهاز
                        </a>
                        <button onclick="copyLink()" class="btn-action btn-secondary">
                            <i class="far fa-copy"></i> نسخ الرابط
                        </button>
                    </div>
                </div>

                <!-- Error -->
                <div id="errorBox" class="error-box">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span class="error-text" id="errorText"></span>
                </div>
            </div>

            <?php if ($adsEnabled && !empty($settings['adsense_inarticle_slot'])): ?>
            <div class="card" style="padding:8px; margin-bottom:10px;">
                <?php echo generateAdSenseCode($settings, 'inarticle'); ?>
            </div>
            <?php endif; ?>

            <div class="platforms-section">
                <div class="platforms-grid">
                    <div class="platform-item" data-platform="youtube">
                        <i class="fab fa-youtube" style="color:#ff0000"></i>
                        <span>YouTube</span>
                    </div>
                    <div class="platform-item" data-platform="tiktok">
                        <i class="fab fa-tiktok" style="color:#00f2fe"></i>
                        <span>TikTok</span>
                    </div>
                    <div class="platform-item" data-platform="instagram">
                        <i class="fab fa-instagram" style="color:#e4405f"></i>
                        <span>Instagram</span>
                    </div>
                    <div class="platform-item" data-platform="facebook">
                        <i class="fab fa-facebook" style="color:#1877f2"></i>
                        <span>Facebook</span>
                    </div>
                    <div class="platform-item" data-platform="twitter">
                        <i class="fab fa-x-twitter" style="color:#1da1f2"></i>
                        <span>X / Twitter</span>
                    </div>
                    <div class="platform-item" data-platform="snapchat">
                        <i class="fab fa-snapchat" style="color:#fffc00"></i>
                        <span>Snapchat</span>
                    </div>
                </div>
            </div>

            <?php if (!empty($recentDownloads)): ?>
            <div class="card history-section">
                <div class="history-header">
                    <div class="history-title">
                        <i class="fas fa-clock-rotate-left"></i> آخر التحميلات
                    </div>
                    <span class="history-count"><?php echo count($recentDownloads); ?> عنصر</span>
                </div>
                <div class="history-list">
                    <?php foreach (array_slice($recentDownloads, 0, 5) as $dl): 
                        $platformColor = getPlatformColor($dl['platform']);
                    ?>
                    <div class="history-item">
                        <div class="history-platform" style="color: <?php echo $platformColor; ?>; border-color: <?php echo $platformColor; ?>30;">
                            <i class="<?php echo getPlatformIcon($dl['platform']); ?>"></i>
                        </div>
                        <div class="history-content">
                            <div class="history-title-text"><?php echo htmlspecialchars($dl['title'] ?: 'فيديو ' . ucfirst($dl['platform'])); ?></div>
                            <div class="history-url"><?php echo htmlspecialchars(substr($dl['url'], 0, 45) . (strlen($dl['url']) > 45 ? '...' : '')); ?></div>
                            <div class="history-footer">
                                <span class="history-tag tag-platform"><?php echo htmlspecialchars($dl['platform']); ?></span>
                                <span class="history-tag tag-quality"><?php echo htmlspecialchars($dl['quality']); ?></span>
                                <span class="history-tag tag-time"><i class="far fa-clock"></i> <?php echo timeAgo($dl['created_at']); ?></span>
                            </div>
                        </div>
                        <div class="history-status <?php echo htmlspecialchars($dl['status']); ?>"></div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endif; ?>

            <?php elseif ($page === 'history'): ?>
            <!-- ==================== صفحة السجل ==================== -->
            <header class="app-header">
                <h1 class="app-title">سجل التنزيلات</h1>
                <p class="app-subtitle">سجلك الخاص المحفوظ بأمان</p>
            </header>

            <?php if (isset($_GET['cleared'])): ?>
            <div class="alert alert-success">
                <i class="fas fa-check-circle"></i> تم مسح السجل بنجاح!
            </div>
            <?php endif; ?>

            <?php if ($isGuest): ?>
            <div class="alert alert-guest">
                <i class="fas fa-info-circle"></i> أنت تتصفح كزائر. سجل التحميلات محفوظ محلياً على متصفحك.
            </div>
            <?php endif; ?>

            <div class="stats-grid">
                <div class="stat-box">
                    <div class="stat-value" id="guestTotal"><?php echo $stats['total']; ?></div>
                    <div class="stat-label">الكل</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="guestSuccess" style="background: linear-gradient(135deg, var(--success), #4ade80); -webkit-background-clip: text;"><?php echo $stats['success']; ?></div>
                    <div class="stat-label">ناجح</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="guestFailed" style="background: linear-gradient(135deg, var(--error), #f87171); -webkit-background-clip: text;"><?php echo $stats['failed']; ?></div>
                    <div class="stat-label">فاشل</div>
                </div>
            </div>

            <?php if (!$isGuest && !empty($recentDownloads)): ?>
            <div style="text-align:left; margin-bottom:10px;">
                <a href="?clear_history=1" class="clear-btn" onclick="return confirm('هل أنت متأكد من مسح سجلك بالكامل؟')">
                    <i class="fas fa-trash-alt"></i> مسح سجلي
                </a>
            </div>
            <?php endif; ?>

            <div id="guestHistoryContainer">
                <?php if (!$isGuest && !empty($recentDownloads)): ?>
                <div class="card" style="padding:14px;">
                    <div class="history-list">
                        <?php foreach ($recentDownloads as $dl): 
                            $platformColor = getPlatformColor($dl['platform']);
                            $extFormat = ($dl['quality'] === 'audio') ? 'mp3' : 'mp4';
                        ?>
                        <div class="history-item">
                            <div class="history-platform" style="color: <?php echo $platformColor; ?>; border-color: <?php echo $platformColor; ?>30;">
                                <i class="<?php echo getPlatformIcon($dl['platform']); ?>"></i>
                            </div>
                            <div class="history-content">
                                <div class="history-title-text"><?php echo htmlspecialchars($dl['title'] ?: 'فيديو ' . ucfirst($dl['platform'])); ?></div>
                                <div class="history-url"><?php echo htmlspecialchars(substr($dl['url'], 0, 50) . (strlen($dl['url']) > 50 ? '...' : '')); ?></div>
                                <div class="history-footer">
                                    <span class="history-tag tag-platform"><?php echo htmlspecialchars($dl['platform']); ?></span>
                                    <span class="history-tag tag-quality"><?php echo htmlspecialchars($dl['quality']); ?></span>
                                    <?php if ($dl['strategy_used']): ?>
                                    <span class="history-tag tag-time"><i class="fas fa-route"></i> <?php echo htmlspecialchars($dl['strategy_used']); ?></span>
                                    <?php endif; ?>
                                    <span class="history-tag tag-time"><i class="far fa-clock"></i> <?php echo date('Y-m-d H:i', strtotime($dl['created_at'])); ?></span>
                                </div>
                                <?php if ($dl['download_link']): ?>
                                <div class="history-actions">
                                    <a href="?action=proxy_download&url=<?php echo urlencode($dl['download_link']); ?>&filename=<?php echo urlencode($dl['title'] ?: 'video'); ?>&platform=<?php echo urlencode($dl['platform']); ?>&format=<?php echo $extFormat; ?>" class="history-btn history-btn-primary">
                                        <i class="fas fa-download"></i> تنزيل
                                    </a>
                                    <button onclick="copyText('<?php echo htmlspecialchars($dl['download_link'], ENT_QUOTES); ?>')" class="history-btn history-btn-secondary">
                                        <i class="far fa-copy"></i> نسخ
                                    </button>
                                </div>
                                <?php endif; ?>
                            </div>
                            <div class="history-status <?php echo htmlspecialchars($dl['status']); ?>"></div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
                <?php else: ?>
                <div class="card empty-state" id="emptyGuestHistory">
                    <i class="fas fa-inbox"></i>
                    <p>لا توجد تحميلات سابقة في سجلك</p>
                </div>
                <?php endif; ?>
            </div>

            <?php elseif ($page === 'settings'): ?>
            <!-- ==================== صفحة الإعدادات ==================== -->
            <header class="app-header">
                <h1 class="app-title">الإعدادات</h1>
                <p class="app-subtitle">تخصيص التطبيق وبوابة المطورين</p>
            </header>

            <?php if (isset($_GET['saved'])): ?>
            <div class="alert alert-success">
                <i class="fas fa-check-circle"></i> تم حفظ الإعدادات بنجاح!
            </div>
            <?php endif; ?>

            <div class="dev-profile">
                <div class="dev-avatar-large">YJ</div>
                <div class="dev-name-large"><?php echo htmlspecialchars(DEV_NAME); ?></div>
                <div class="dev-role">المطور الرئيسي للنظام</div>
                <div class="dev-contact-row">
                    <i class="fab fa-whatsapp"></i>
                    <span><?php echo htmlspecialchars(DEV_WHATSAPP); ?></span>
                </div>
                <div class="dev-social">
                    <a href="https://wa.me/2<?php echo preg_replace('/[^0-9]/', '', DEV_WHATSAPP); ?>" target="_blank" class="social-btn" title="واتساب">
                        <i class="fab fa-whatsapp"></i>
                    </a>
                    <a href="mailto:<?php echo htmlspecialchars(ADMIN_EMAIL); ?>" class="social-btn" title="البريد">
                        <i class="fas fa-envelope"></i>
                    </a>
                </div>
            </div>

            <form method="POST" action="?page=settings">
                <input type="hidden" name="update_settings" value="1">

                <div class="card">
                    <div class="card-header">
                        <div class="card-icon"><i class="fas fa-sliders-h"></i></div>
                        <div class="card-title">إعدادات المظهر والجودة</div>
                    </div>

                    <div class="settings-group">
                        <label class="settings-label"><i class="fas fa-palette"></i> لون الثيم المفضل</label>
                        <input type="color" name="theme_color" class="settings-input" 
                            value="<?php echo htmlspecialchars($themeColor); ?>" 
                            style="height:48px; padding:4px; cursor:pointer;">
                    </div>

                    <div class="settings-group">
                        <label class="settings-label"><i class="fas fa-star"></i> الجودة الافتراضية</label>
                        <select name="default_quality" class="settings-input" style="cursor:pointer;">
                            <option value="auto" <?php echo $defaultQuality === 'auto' ? 'selected' : ''; ?>>تلقائي (أفضل جودة متاحة)</option>
                            <option value="4k" <?php echo $defaultQuality === '4k' ? 'selected' : ''; ?>>4K Ultra HD</option>
                            <option value="1080" <?php echo $defaultQuality === '1080' ? 'selected' : ''; ?>>FHD 1080p</option>
                            <option value="720" <?php echo $defaultQuality === '720' ? 'selected' : ''; ?>>HD 720p</option>
                            <option value="audio" <?php echo $defaultQuality === 'audio' ? 'selected' : ''; ?>>صوت فقط MP3</option>
                        </select>
                    </div>
                </div>

                <?php if ($isAdmin): ?>
                <div class="card">
                    <div class="card-header">
                        <div class="card-icon" style="color:#4285f4;"><i class="fab fa-google"></i></div>
                        <div class="card-title">إعدادات Google AdSense (للمدير)</div>
                    </div>

                    <div class="settings-group" style="display:flex; align-items:center; justify-content:space-between;">
                        <label class="settings-label" style="margin:0;"><i class="fas fa-power-off"></i> تفعيل الإعلانات في التطبيق</label>
                        <label class="toggle-switch">
                            <input type="checkbox" name="ads_enabled" value="1" <?php echo $adsEnabled ? 'checked' : ''; ?>>
                            <span class="toggle-slider"></span>
                        </label>
                    </div>

                    <div class="settings-group">
                        <label class="settings-label">Publisher ID</label>
                        <input type="text" name="adsense_publisher_id" class="settings-input" dir="ltr"
                            placeholder="pub-xxxxxxxxxxxxxxxx"
                            value="<?php echo htmlspecialchars($settings['adsense_publisher_id'] ?? ''); ?>">
                    </div>

                    <div class="settings-group">
                        <label class="settings-label">Display Ad Slot</label>
                        <input type="text" name="adsense_display_slot" class="settings-input" dir="ltr"
                            value="<?php echo htmlspecialchars($settings['adsense_display_slot'] ?? ''); ?>">
                    </div>

                    <div class="settings-group">
                        <label class="settings-label">In-Article Ad Slot</label>
                        <input type="text" name="adsense_inarticle_slot" class="settings-input" dir="ltr"
                            value="<?php echo htmlspecialchars($settings['adsense_inarticle_slot'] ?? ''); ?>">
                    </div>

                    <div class="settings-group">
                        <label class="settings-label">Anchor Ad Slot</label>
                        <input type="text" name="adsense_anchor_slot" class="settings-input" dir="ltr"
                            value="<?php echo htmlspecialchars($settings['adsense_anchor_slot'] ?? ''); ?>">
                    </div>
                </div>
                <?php endif; ?>

                <button type="submit" class="save-btn">
                    <i class="fas fa-save"></i> حفظ الإعدادات
                </button>
            </form>

            <!-- ====== قسم API للمطورين ====== -->
            <?php if (!$isGuest && $userId > 0): ?>
            <div class="card" style="margin-top:20px;">
                <div class="card-header">
                    <div class="card-icon" style="color:var(--api);"><i class="fas fa-code"></i></div>
                    <div class="card-title">بوابة API للمطورين</div>
                </div>

                <?php if ($codeError): ?>
                <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <?php echo htmlspecialchars($codeError); ?></div>
                <?php endif; ?>

                <?php if ($codeSuccess): ?>
                <div class="alert alert-success"><i class="fas fa-check-circle"></i> <?php echo htmlspecialchars($codeSuccess); ?></div>
                <?php endif; ?>

                <?php if ($userApiKey && !$subscriptionExpired): ?>
                <div class="api-key-box">
                    <div style="margin-bottom:10px; color:var(--success); font-weight:800; font-size:12px;">
                        <i class="fas fa-check-circle"></i> اشتراك API نشط ويعمل
                    </div>

                    <div class="subscription-timer">
                        <div class="timer-item">
                            <div class="timer-value" id="timerDays"><?php echo $subscriptionDaysLeft; ?></div>
                            <div class="timer-label">يوم</div>
                        </div>
                        <div class="timer-separator">:</div>
                        <div class="timer-item">
                            <div class="timer-value" id="timerHours"><?php echo str_pad($subscriptionHoursLeft, 2, '0', STR_PAD_LEFT); ?></div>
                            <div class="timer-label">ساعة</div>
                        </div>
                        <div class="timer-separator">:</div>
                        <div class="timer-item">
                            <div class="timer-value" id="timerMinutes"><?php echo str_pad($subscriptionMinutesLeft, 2, '0', STR_PAD_LEFT); ?></div>
                            <div class="timer-label">دقيقة</div>
                        </div>
                    </div>

                    <div style="font-size:11px; color:var(--text-muted); margin-bottom:10px;">
                        إجمالي الطلبات: <strong><?php echo (int)$userApiKey['total_requests']; ?></strong> | هذا الشهر: <strong><?php echo (int)$userApiKey['monthly_requests']; ?></strong>
                    </div>

                    <div class="api-key-display">
                        <?php echo htmlspecialchars($userApiKey['api_key']); ?>
                        <span class="copy-icon" onclick="copyText('<?php echo htmlspecialchars($userApiKey['api_key']); ?>')">
                            <i class="far fa-copy"></i> نسخ
                        </span>
                    </div>
                </div>

                <div class="api-docs">
                    <h4><i class="fas fa-book"></i> طريقة الربط البرمجي (REST API)</h4>
                    <pre>POST <?php echo htmlspecialchars((isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . $_SERVER['PHP_SELF'] . '?action=developer_api'); ?>

Authorization: Bearer <?php echo htmlspecialchars($userApiKey['api_key']); ?>

Content-Type: application/json

{"url": "https://www.tiktok.com/...", "quality": "auto"}</pre>
                </div>
                <?php else: ?>
                <div style="text-align:center;">
                    <div class="price-tag">
                        <i class="fas fa-tag"></i> سعر الاشتراك: <?php echo API_PRICE; ?> جنيه شهرياً
                    </div>
                </div>
                <div class="cash-number">
                    <i class="fas fa-wallet" style="font-size:20px; color:#25d366;"></i>
                    <div>
                        <div style="font-family:monospace; font-size:16px; font-weight:800;"><?php echo htmlspecialchars(DEV_WHATSAPP); ?></div>
                        <div style="font-size:10px; color:var(--text-muted);">تحويل فودافون كاش / إنستا باي - <?php echo htmlspecialchars(DEV_NAME); ?></div>
                    </div>
                </div>
                <form method="POST" action="?page=settings">
                    <div class="settings-group">
                        <input type="text" name="subscription_code" class="code-input" placeholder="DOViD-XXXXXXXXXXXX" maxlength="25" required>
                    </div>
                    <button type="submit" name="activate_code" class="save-btn" style="background: linear-gradient(135deg, var(--api), #fbbf24); color:#000;">
                        <i class="fas fa-rocket"></i> تفعيل كود الاشتراك الآن
                    </button>
                </form>
                <?php endif; ?>
            </div>
            <?php endif; ?>

            <div style="text-align:center; padding: 20px 0;">
                <a href="?logout=1" class="logout-btn" onclick="return confirm('هل تريد تسجيل الخروج؟')">
                    <i class="fas fa-sign-out-alt"></i> تسجيل الخروج
                </a>
            </div>

            <?php elseif ($page === 'admin' && $isAdmin): ?>
            <!-- ==================== لوحة تحكم المدير ==================== -->
            <?php $adminTab = $_GET['tab'] ?? 'dashboard'; ?>
            <header class="app-header">
                <h1 class="app-title" style="background: linear-gradient(135deg, #fff 20%, var(--admin) 80%); -webkit-background-clip: text;">لوحة تحكم المدير</h1>
                <p class="app-subtitle">إدارة شاملة للمستخدمين والحماية والأكواد</p>
            </header>

            <div class="admin-tabs">
                <a href="?page=admin&tab=dashboard" class="admin-tab <?php echo $adminTab === 'dashboard' ? 'active' : ''; ?>"><i class="fas fa-chart-pie"></i> الإحصائيات</a>
                <a href="?page=admin&tab=users" class="admin-tab <?php echo $adminTab === 'users' ? 'active' : ''; ?>"><i class="fas fa-users"></i> المستخدمين</a>
                <a href="?page=admin&tab=downloads" class="admin-tab <?php echo $adminTab === 'downloads' ? 'active' : ''; ?>"><i class="fas fa-download"></i> التحميلات</a>
                <a href="?page=admin&tab=bypass" class="admin-tab <?php echo $adminTab === 'bypass' ? 'active' : ''; ?>"><i class="fas fa-route"></i> سجل التخطي</a>
                <a href="?page=admin&tab=logins" class="admin-tab <?php echo $adminTab === 'logins' ? 'active' : ''; ?>"><i class="fas fa-key"></i> محاولات الدخول</a>
                <a href="?page=admin&tab=security" class="admin-tab <?php echo $adminTab === 'security' ? 'active' : ''; ?>"><i class="fas fa-shield-halved"></i> جدار الحماية</a>
                <a href="?page=admin&tab=api_codes" class="admin-tab <?php echo $adminTab === 'api_codes' ? 'active' : ''; ?>"><i class="fas fa-code"></i> أكواد API</a>
            </div>

            <?php if ($adminTab === 'dashboard'): ?>
            <div class="stats-grid-4">
                <div class="admin-stat-box">
                    <div class="admin-stat-value"><?php echo $adminStats['total_users']; ?></div>
                    <div class="admin-stat-label">المستخدمين</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value"><?php echo $adminStats['total_downloads']; ?></div>
                    <div class="admin-stat-label">التحميلات</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value"><?php echo $adminStats['total_bypass']; ?></div>
                    <div class="admin-stat-label">عمليات التخطي</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value"><?php echo $adminStats['blocked_ips_count']; ?></div>
                    <div class="admin-stat-label">IP محظور</div>
                </div>
            </div>

            <div class="stats-grid-5">
                <div class="admin-stat-box">
                    <div class="admin-stat-value" style="font-size:18px;"><?php echo $adminStats['total_api_keys']; ?></div>
                    <div class="admin-stat-label">مفاتيح API</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value" style="font-size:18px;"><?php echo $adminStats['active_api_keys']; ?></div>
                    <div class="admin-stat-label">مفاتيح نشطة</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value" style="font-size:18px;"><?php echo $adminStats['total_codes']; ?></div>
                    <div class="admin-stat-label">إجمالي الأكواد</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value" style="font-size:18px;"><?php echo $adminStats['available_codes']; ?></div>
                    <div class="admin-stat-label">أكواد متاحة</div>
                </div>
                <div class="admin-stat-box">
                    <div class="admin-stat-value" style="font-size:18px;"><?php echo $adminStats['used_codes']; ?></div>
                    <div class="admin-stat-label">أكواد مستخدمة</div>
                </div>
            </div>

            <?php elseif ($adminTab === 'users'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-users"></i></div>
                    <div class="admin-card-title">المستخدمين المسجلين (<?php echo count($allUsers); ?>)</div>
                </div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>ID</th><th>المستخدم</th><th>البريد</th><th>الرتبة</th><th>التسجيل</th><th>آخر دخول</th><th>إجراء</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allUsers as $u): ?>
                            <tr>
                                <td><?php echo $u['id']; ?></td>
                                <td><strong><?php echo htmlspecialchars($u['username']); ?></strong></td>
                                <td><?php echo htmlspecialchars($u['email'] ?: '-'); ?></td>
                                <td><?php echo $u['is_admin'] ? '<span style="color:var(--admin);font-weight:800;">👑 مدير</span>' : 'مستخدم'; ?></td>
                                <td><?php echo timeAgo($u['created_at']); ?></td>
                                <td><?php echo $u['last_login'] ? timeAgo($u['last_login']) : '-'; ?></td>
                                <td>
                                    <?php if (!$u['is_admin']): ?>
                                    <a href="?page=admin&tab=users&admin_action=delete_user&user_id=<?php echo $u['id']; ?>" class="history-btn history-btn-danger" onclick="return confirm('حذف المستخدم؟')"><i class="fas fa-trash"></i> حذف</a>
                                    <?php else: ?>-<?php endif; ?>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <?php elseif ($adminTab === 'downloads'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-download"></i></div>
                    <div class="admin-card-title">سجل التحميلات العام</div>
                </div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>ID</th><th>المستخدم</th><th>المنصة</th><th>الجودة</th><th>الحالة</th><th>الاستراتيجية</th><th>الوقت</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allDownloads as $dl): ?>
                            <tr>
                                <td><?php echo $dl['id']; ?></td>
                                <td><strong><?php echo htmlspecialchars($dl['username'] ?? 'زائر'); ?></strong></td>
                                <td><span class="history-tag tag-platform"><?php echo htmlspecialchars($dl['platform']); ?></span></td>
                                <td><?php echo htmlspecialchars($dl['quality']); ?></td>
                                <td><?php echo getStatusLabel($dl['status']); ?></td>
                                <td><?php echo htmlspecialchars($dl['strategy_used'] ?: '-'); ?></td>
                                <td><?php echo timeAgo($dl['created_at']); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <?php elseif ($adminTab === 'bypass'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-route"></i></div>
                    <div class="admin-card-title">سجل استراتيجيات التخطي (Bypass Engine)</div>
                </div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>ID</th><th>المستخدم</th><th>الرابط</th><th>الاستراتيجية</th><th>الحالة</th><th>الاستجابة</th><th>الوقت</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allBypassLogs as $bp): ?>
                            <tr>
                                <td><?php echo $bp['id']; ?></td>
                                <td><?php echo htmlspecialchars($bp['username'] ?? 'زائر'); ?></td>
                                <td><span class="truncate"><?php echo htmlspecialchars($bp['url']); ?></span></td>
                                <td><?php echo htmlspecialchars($bp['strategy']); ?></td>
                                <td><?php echo getStatusLabel($bp['status']); ?></td>
                                <td><?php echo (int)$bp['response_time']; ?>ms</td>
                                <td><?php echo timeAgo($bp['created_at']); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <?php elseif ($adminTab === 'logins'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-key"></i></div>
                    <div class="admin-card-title">محاولات تسجيل الدخول</div>
                </div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>ID</th><th>IP</th><th>المستخدم</th><th>الحالة</th><th>التاريخ</th><th>إجراء</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allLoginAttempts as $log): ?>
                            <tr>
                                <td><?php echo $log['id']; ?></td>
                                <td><span class="ip-badge"><?php echo htmlspecialchars($log['ip']); ?></span></td>
                                <td><?php echo htmlspecialchars($log['username'] ?: '-'); ?></td>
                                <td><?php echo $log['success'] ? '<span style="color:var(--success);font-weight:700;">✓ ناجح</span>' : '<span style="color:var(--error);font-weight:700;">✗ فاشل</span>'; ?></td>
                                <td><?php echo timeAgo($log['created_at']); ?></td>
                                <td>
                                    <a href="?page=admin&tab=security&admin_action=block_ip&ip=<?php echo urlencode($log['ip']); ?>" class="history-btn history-btn-danger"><i class="fas fa-ban"></i> حظر IP</a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <?php elseif ($adminTab === 'security'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-ban"></i></div>
                    <div class="admin-card-title">حظر عنوان IP يدوياً</div>
                </div>
                <form method="POST" action="?page=admin&tab=security" style="display:flex; gap:8px; flex-wrap:wrap;">
                    <input type="hidden" name="admin_action" value="manual_block_ip">
                    <input type="text" name="ip_to_block" class="settings-input" placeholder="مثال: 192.168.1.50" style="flex:1; min-width:160px;" required dir="ltr">
                    <input type="text" name="block_reason" class="settings-input" placeholder="سبب الحظر" style="flex:2; min-width:180px;">
                    <button type="submit" class="save-btn" style="width:auto; padding:0 24px;">حظر الآن</button>
                </form>
            </div>

            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-shield-alt"></i></div>
                    <div class="admin-card-title">قائمة عناوين IP المحظورة</div>
                </div>
                <?php
                $blockedResult = $db->query("SELECT * FROM blocked_ips ORDER BY blocked_at DESC");
                $blockedIPs = [];
                while ($row = $blockedResult->fetchArray(SQLITE3_ASSOC)) $blockedIPs[] = $row;
                ?>
                <?php if (!empty($blockedIPs)): ?>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>ID</th><th>IP</th><th>السبب</th><th>التاريخ</th><th>إجراء</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($blockedIPs as $bip): ?>
                            <tr>
                                <td><?php echo $bip['id']; ?></td>
                                <td><span class="ip-badge"><?php echo htmlspecialchars($bip['ip']); ?></span></td>
                                <td><?php echo htmlspecialchars($bip['reason']); ?></td>
                                <td><?php echo timeAgo($bip['blocked_at']); ?></td>
                                <td>
                                    <a href="?page=admin&tab=security&admin_action=unblock_ip&id=<?php echo $bip['id']; ?>" class="history-btn history-btn-primary"><i class="fas fa-unlock"></i> فك الحظر</a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php else: ?>
                <div class="empty-state"><p>لا توجد عناوين IP محظورة</p></div>
                <?php endif; ?>
            </div>

            <?php elseif ($adminTab === 'api_codes'): ?>
            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon" style="color:var(--api);"><i class="fas fa-plus-circle"></i></div>
                    <div class="admin-card-title">توليد أكواد اشتراك API جديدة</div>
                </div>
                <form method="POST" action="?page=admin&tab=api_codes">
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:14px;">
                        <div>
                            <label class="settings-label">المدة (بالأيام)</label>
                            <select name="duration_days" class="settings-input">
                                <option value="7">7 أيام</option>
                                <option value="15">15 يوم</option>
                                <option value="30" selected>30 يوم (شهر)</option>
                                <option value="90">90 يوم</option>
                                <option value="365">365 يوم (سنة)</option>
                            </select>
                        </div>
                        <div>
                            <label class="settings-label">العدد</label>
                            <select name="code_count" class="settings-input">
                                <option value="1">1 كود</option>
                                <option value="5">5 أكواد</option>
                                <option value="10">10 أكواد</option>
                                <option value="25">25 كود</option>
                            </select>
                        </div>
                    </div>
                    <button type="submit" name="generate_code" class="save-btn" style="background:linear-gradient(135deg, var(--api), #fbbf24); color:#000;">
                        <i class="fas fa-magic"></i> توليد الأكواد
                    </button>
                </form>

                <?php if (isset($_GET['generated']) && !empty($_SESSION['generated_codes'])): ?>
                <div class="generated-codes-box">
                    <?php foreach ($_SESSION['generated_codes'] as $gcode): ?>
                    <div class="generated-code-item">
                        <span><?php echo htmlspecialchars($gcode); ?></span>
                        <button onclick="copyText('<?php echo htmlspecialchars($gcode); ?>')" class="history-btn history-btn-secondary">نسخ</button>
                    </div>
                    <?php endforeach; ?>
                </div>
                <?php unset($_SESSION['generated_codes'], $_SESSION['code_duration']); endif; ?>
            </div>

            <div class="admin-card">
                <div class="admin-card-header">
                    <div class="admin-card-icon"><i class="fas fa-list"></i></div>
                    <div class="admin-card-title">جميع أكواد الاشتراك (<?php echo count($allSubscriptionCodes); ?>)</div>
                </div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                            <tr><th>الكود</th><th>المدة</th><th>الحالة</th><th>المستخدم</th><th>إجراء</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allSubscriptionCodes as $sc): ?>
                            <tr>
                                <td style="font-family:monospace; color:var(--api); font-weight:700;"><?php echo htmlspecialchars($sc['code']); ?></td>
                                <td><?php echo $sc['duration_days']; ?> يوم</td>
                                <td><?php echo $sc['status'] === 'active' ? '<span style="color:var(--success);">متاح</span>' : '<span style="color:var(--text-dim);">مستخدم</span>'; ?></td>
                                <td><?php echo htmlspecialchars($sc['used_by_name'] ?: '-'); ?></td>
                                <td>
                                    <a href="?page=admin&tab=api_codes&admin_action=delete_code&code_id=<?php echo $sc['id']; ?>" class="history-btn history-btn-danger"><i class="fas fa-trash"></i></a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
            <?php endif; ?>
            <?php endif; ?>
        </div>
    </div>

    <nav class="bottom-nav">
        <a href="?page=home" class="nav-item <?php echo $page === 'home' ? 'active' : ''; ?>">
            <i class="fas fa-home"></i><span>الرئيسية</span><div class="nav-indicator"></div>
        </a>
        <a href="?page=history" class="nav-item <?php echo $page === 'history' ? 'active' : ''; ?>">
            <i class="fas fa-clock-rotate-left"></i><span>السجل</span><div class="nav-indicator"></div>
        </a>
        <a href="?page=settings" class="nav-item <?php echo $page === 'settings' ? 'active' : ''; ?>">
            <i class="fas fa-cog"></i><span>الإعدادات</span><div class="nav-indicator"></div>
        </a>
        <?php if ($isAdmin): ?>
        <a href="?page=admin" class="nav-item admin-nav <?php echo $page === 'admin' ? 'active' : ''; ?>">
            <i class="fas fa-shield-alt"></i><span>المدير</span><div class="nav-indicator" style="background:var(--admin);"></div>
        </a>
        <?php endif; ?>
    </nav>
    <?php endif; ?>

    <div class="toast-container">
        <div id="toast" class="toast">
            <i class="fas fa-check-circle"></i>
            <span id="toastText">تم النسخ!</span>
        </div>
    </div>

    <script>
        document.querySelectorAll('.quality-chip').forEach(chip => {
            chip.addEventListener('click', function() {
                document.querySelectorAll('.quality-chip').forEach(c => c.classList.remove('active'));
                this.classList.add('active');
            });
        });

        async function pasteFromClipboard() {
            const input = document.getElementById('videoUrl');
            try {
                const text = await navigator.clipboard.readText();
                if (text) {
                    input.value = text.trim();
                    input.dispatchEvent(new Event('input'));
                    showToast('تم لصق الرابط من الحافظة! 📋');
                }
            } catch (_) {
                input.focus();
                showToast('اضغط مطولاً داخل الحقل للصق الرابط');
            }
        }

        const GUEST_HISTORY_KEY = 'guest_download_history';
        const isGuest = <?php echo $isGuest ? 'true' : 'false'; ?>;

        function getGuestHistory() {
            try {
                const data = localStorage.getItem(GUEST_HISTORY_KEY);
                return data ? JSON.parse(data) : [];
            } catch(e) { return []; }
        }

        function saveGuestHistory(history) {
            try { localStorage.setItem(GUEST_HISTORY_KEY, JSON.stringify(history)); } catch(e) {}
        }

        function addGuestDownload(item) {
            const history = getGuestHistory();
            history.unshift(item);
            if (history.length > 50) history.pop();
            saveGuestHistory(history);
            renderGuestHistory();
        }

        function clearGuestHistory() {
            if (confirm('هل أنت متأكد من مسح سجلك بالكامل؟')) {
                localStorage.removeItem(GUEST_HISTORY_KEY);
                renderGuestHistory();
                showToast('تم مسح السجل بنجاح!');
            }
        }

        function renderGuestHistory() {
            if (!isGuest) return;
            const history = getGuestHistory();
            const total = history.length;
            const success = history.filter(h => h.status === 'success').length;
            const failed = history.filter(h => h.status === 'failed').length;

            ['guestTotal', 'homeStatTotal'].forEach(id => { const el = document.getElementById(id); if (el) el.textContent = total; });
            ['guestSuccess', 'homeStatSuccess'].forEach(id => { const el = document.getElementById(id); if (el) el.textContent = success; });
            ['guestFailed', 'homeStatFailed'].forEach(id => { const el = document.getElementById(id); if (el) el.textContent = failed; });

            const container = document.getElementById('guestHistoryContainer');
            if (!container) return;

            if (history.length === 0) {
                container.innerHTML = '<div class="card empty-state"><i class="fas fa-inbox"></i><p>لا توجد تحميلات سابقة في سجلك</p></div>';
                return;
            }

            let html = '<div style="text-align:left; margin-bottom:10px;"><button onclick="clearGuestHistory()" class="clear-btn"><i class="fas fa-trash-alt"></i> مسح سجلي</button></div><div class="card" style="padding:14px;"><div class="history-list">';
            history.forEach(dl => {
                const proxyUrl = dl.download_link ? '?action=proxy_download&url=' + encodeURIComponent(dl.download_link) + '&filename=' + encodeURIComponent(dl.title || 'video') + '&platform=' + encodeURIComponent(dl.platform || 'unknown') : '#';
                html += `<div class="history-item">
                    <div class="history-platform"><i class="fas fa-video" style="color:var(--primary)"></i></div>
                    <div class="history-content">
                        <div class="history-title-text">${dl.title || 'فيديو'}</div>
                        <div class="history-url">${(dl.url || '').substring(0,50)}</div>
                        <div class="history-footer">
                            <span class="history-tag tag-platform">${dl.platform || 'video'}</span>
                            <span class="history-tag tag-quality">${dl.quality || 'auto'}</span>
                        </div>
                        ${dl.download_link ? `<div class="history-actions">
                            <a href="${proxyUrl}" class="history-btn history-btn-primary"><i class="fas fa-download"></i> تنزيل</a>
                            <button onclick="copyText('${dl.download_link}')" class="history-btn history-btn-secondary"><i class="far fa-copy"></i> نسخ</button>
                        </div>` : ''}
                    </div>
                    <div class="history-status ${dl.status}"></div>
                </div>`;
            });
            html += '</div></div>';
            container.innerHTML = html;
        }

        if (isGuest) document.addEventListener('DOMContentLoaded', renderGuestHistory);

        async function handleDownload() {
            const urlInput = document.getElementById('videoUrl');
            const btn = document.getElementById('downloadBtn');
            const btnText = document.getElementById('btnText');
            const loadingBox = document.getElementById('loadingBox');
            const resultBox = document.getElementById('resultBox');
            const errorBox = document.getElementById('errorBox');
            const loadingText = document.getElementById('loadingText');

            const videoUrl = urlInput.value.trim();
            const quality = document.querySelector('.quality-chip.active')?.dataset.quality || 'auto';

            if (!videoUrl) {
                showError('يرجى إدخال رابط الفيديو أولاً');
                urlInput.focus();
                return;
            }

            btn.disabled = true;
            btnText.textContent = 'جاري المعالجة الذكية...';
            loadingBox.classList.add('show');
            resultBox.classList.remove('show');
            errorBox.classList.remove('show');

            try {
                const formData = new FormData();
                formData.append('url', videoUrl);
                formData.append('quality', quality);

                const response = await fetch('?action=download', { method: 'POST', body: formData });
                const data = await response.json();

                if (data.status === 'success') {
                    const proxyUrl = '?action=proxy_download&url=' + encodeURIComponent(data.answer) + '&filename=' + encodeURIComponent(data.title || 'video') + '&platform=' + encodeURIComponent(data.platform || 'unknown') + '&format=' + encodeURIComponent(data.format || 'mp4');

                    document.getElementById('finalDownloadLink').href = proxyUrl;
                    document.getElementById('resTitle').textContent = data.title || 'فيديو جاهز للتحميل';
                    document.getElementById('resPlatform').textContent = (data.platform || 'Video').toUpperCase();
                    document.getElementById('resQuality').textContent = data.quality || 'HD';
                    document.getElementById('resStrategy').textContent = data.strategy || 'Direct';

                    resultBox.classList.add('show');
                    showToast('تم استخراج الرابط بنجاح! 🎉');

                    if (isGuest || data.guest) {
                        addGuestDownload({
                            url: videoUrl,
                            title: data.title || 'فيديو',
                            platform: data.platform || 'unknown',
                            quality: quality,
                            status: 'success',
                            strategy: data.strategy || 'direct',
                            download_link: data.answer,
                            created_at: new Date().toISOString()
                        });
                    }
                } else {
                    showError(data.message || 'فشل في معالجة الرابط');
                }
            } catch (err) {
                showError('حدث خطأ في الاتصال بالسيرفر.');
            } finally {
                btn.disabled = false;
                btnText.textContent = 'تحميل الفيديو الآن';
                loadingBox.classList.remove('show');
            }
        }

        function showError(msg) {
            const errorBox = document.getElementById('errorBox');
            document.getElementById('errorText').textContent = msg;
            errorBox.classList.add('show');
        }

        function copyLink() {
            const link = document.getElementById('finalDownloadLink').href;
            copyText(link);
        }

        function copyText(text) {
            if (navigator.clipboard) {
                navigator.clipboard.writeText(text).then(() => showToast('تم النسخ إلى الحافظة! 📋'));
            } else {
                const el = document.createElement('textarea');
                el.value = text;
                document.body.appendChild(el);
                el.select();
                document.execCommand('copy');
                document.body.removeChild(el);
                showToast('تم النسخ إلى الحافظة! 📋');
            }
        }

        function showToast(text) {
            const toast = document.getElementById('toast');
            document.getElementById('toastText').textContent = text;
            toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), 3000);
        }

        document.getElementById('videoUrl')?.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') handleDownload();
        });

        document.getElementById('videoUrl')?.addEventListener('input', function() {
            const url = this.value.toLowerCase();
            document.querySelectorAll('.platform-item').forEach(p => p.classList.remove('active'));
            let activePlatform = null;
            if (url.includes('youtube') || url.includes('youtu.be')) activePlatform = 'youtube';
            else if (url.includes('instagram')) activePlatform = 'instagram';
            else if (url.includes('tiktok')) activePlatform = 'tiktok';
            else if (url.includes('facebook') || url.includes('fb.watch')) activePlatform = 'facebook';
            else if (url.includes('twitter') || url.includes('x.com')) activePlatform = 'twitter';
            else if (url.includes('snapchat')) activePlatform = 'snapchat';

            if (activePlatform) {
                document.querySelector(`.platform-item[data-platform="${activePlatform}"]`)?.classList.add('active');
            }
        });
    </script>
</body>
</html>
