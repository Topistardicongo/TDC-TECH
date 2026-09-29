<?php
declare(strict_types=1);

$configFile = dirname(__DIR__) . '/config.local.php';
if (is_file($configFile)) require $configFile;

function text_len(string $value): int { return function_exists('mb_strlen') ? mb_strlen($value, 'UTF-8') : strlen($value); }
function text_cut(string $value, int $start, int $length): string { return function_exists('mb_substr') ? mb_substr($value, $start, $length, 'UTF-8') : substr($value, $start, $length); }
function app_encryption_key(): string {
    $secret = defined('TDC_APP_KEY') ? TDC_APP_KEY : envv('TDC_APP_KEY');
    if (!$secret || text_len((string)$secret) < 32) throw new RuntimeException('Application encryption key is not configured.');
    return hash('sha256', (string)$secret, true);
}
function encrypt_private_note(string $plain): string {
    $iv=random_bytes(12); $tag='';
    $cipher=openssl_encrypt($plain,'aes-256-gcm',app_encryption_key(),OPENSSL_RAW_DATA,$iv,$tag);
    if($cipher===false) throw new RuntimeException('Unable to encrypt private data.');
    return 'gcm1:'.base64_encode($iv.$tag.$cipher);
}
function decrypt_private_note(?string $stored): ?string {
    if($stored===null||$stored==='')return $stored;
    if(!str_starts_with($stored,'gcm1:'))return $stored;
    $raw=base64_decode(substr($stored,5),true);if($raw===false||strlen($raw)<29)throw new RuntimeException('Invalid encrypted value.');
    $plain=openssl_decrypt(substr($raw,28),'aes-256-gcm',app_encryption_key(),OPENSSL_RAW_DATA,substr($raw,0,12),substr($raw,12,16));
    if($plain===false)throw new RuntimeException('Unable to decrypt private data.');
    return $plain;
}
function envv(string $name, ?string $default = null): ?string {
    $value = getenv($name);
    return $value === false ? $default : $value;
}
function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $host = defined('TDC_DB_HOST') ? TDC_DB_HOST : envv('TDC_DB_HOST');
    $name = defined('TDC_DB_NAME') ? TDC_DB_NAME : envv('TDC_DB_NAME');
    $user = defined('TDC_DB_USER') ? TDC_DB_USER : envv('TDC_DB_USER');
    $pass = defined('TDC_DB_PASS') ? TDC_DB_PASS : envv('TDC_DB_PASS');
    if (!$host || !$name || !$user) throw new RuntimeException('Database is not configured.');
    $pdo = new PDO("mysql:host={$host};dbname={$name};charset=utf8mb4", $user, (string)$pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    return $pdo;
}
function secure_session(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    $secure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (defined('TDC_FORCE_HTTPS') && TDC_FORCE_HTTPS === true);
    session_name('tdc_session');
    session_set_cookie_params(['lifetime'=>0,'path'=>'/','secure'=>$secure,'httponly'=>true,'samesite'=>'Lax']);
    ini_set('session.use_strict_mode','1');
    ini_set('session.use_only_cookies','1');
    session_start();
}
secure_session();
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('X-Frame-Options: SAMEORIGIN');
ini_set('display_errors','0');
set_exception_handler(static function(Throwable $e): void { error_log('TDC Tech exception: '.$e->getMessage()); http_response_code(500); if(str_contains((string)($_SERVER['REQUEST_URI']??''),'/api/')) { header('Content-Type: application/json; charset=utf-8'); echo '{"error":"A server error occurred."}'; } else { header('Content-Type: text/plain; charset=utf-8'); echo 'A server error occurred. Please try again later.'; } });
function json_out(array $data, int $status=200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store, private');
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}
function json_body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw ?: '', true);
    if (!is_array($data)) json_out(['error'=>'Invalid request body.'],400);
    return $data;
}
function csrf_token(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}
function require_csrf(): void {
    $provided = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    if (!$provided || !hash_equals(csrf_token(), $provided)) json_out(['error'=>'Session expired. Refresh and try again.'],419);
}
function current_user(): ?array {
    if (empty($_SESSION['uid'])) return null;
    $q = db()->prepare('SELECT id,name,email,role,status FROM users WHERE id=?');
    $q->execute([(int)$_SESSION['uid']]);
    $u = $q->fetch();
    if (!$u || $u['status'] !== 'active') { $_SESSION = []; session_destroy(); return null; }
    return $u;
}
function require_user(): array {
    $u = current_user();
    if (!$u) json_out(['error'=>'Authentication required.'],401);
    return $u;
}
function require_admin(): array {
    $u = require_user();
    if ($u['role'] !== 'admin') json_out(['error'=>'Administrator access required.'],403);
    return $u;
}
function require_method(string $method): void {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $method) json_out(['error'=>'Method not allowed.'],405);
}
function audit(string $event, ?int $userId=null, array $meta=[]): void {
    $stmt=db()->prepare('INSERT INTO audit_log(actor_user_id,event,ip_address,metadata,created_at) VALUES(?,?,?,?,UTC_TIMESTAMP())');
    $stmt->execute([$userId,$event,substr($_SERVER['REMOTE_ADDR'] ?? '',0,45),json_encode($meta)]);
}
