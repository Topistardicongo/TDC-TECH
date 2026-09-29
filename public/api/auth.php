<?php
require dirname(__DIR__,2).'/app/bootstrap.php';
require_method('POST');
require_csrf();
$data=json_body();
$action=(string)($data['action']??'');
if ($action==='register') {
    $name=trim((string)($data['name']??''));
    $email=strtolower(trim((string)($data['email']??'')));
    $password=(string)($data['password']??'');
    if (text_len($name)<2 || text_len($name)>120 || !filter_var($email,FILTER_VALIDATE_EMAIL) || strlen($password)<12 || strlen($password)>200) json_out(['error'=>'Enter a valid name and email. Password must be at least 12 characters.'],422);
    try {
        $q=db()->prepare("INSERT INTO users(name,email,password_hash) VALUES(?,?,?)");
        $q->execute([$name,$email,password_hash($password,PASSWORD_DEFAULT)]);
        $uid=(int)db()->lastInsertId();
    } catch (PDOException $e) {
        if ((string)$e->getCode()==='23000') json_out(['error'=>'An account with this email already exists.'],409);
        throw $e;
    }
    session_regenerate_id(true); $_SESSION['uid']=$uid; $_SESSION['csrf']=bin2hex(random_bytes(32));
    audit('account.registered',$uid);
    json_out(['ok'=>true,'redirect'=>'/dashboard.php','csrf'=>csrf_token()]);
}
if ($action==='login') {
    $email=strtolower(trim((string)($data['email']??'')));
    $password=(string)($data['password']??'');
    if (!filter_var($email,FILTER_VALIDATE_EMAIL) || $password==='') json_out(['error'=>'Invalid email or password.'],422);
    $ip=hash('sha256',(string)($_SERVER['REMOTE_ADDR']??'')); $eh=hash('sha256',$email);
    db()->prepare('INSERT INTO login_attempt_limits(email_hash,ip_hash,attempt_count,window_started) VALUES(?,?,1,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE attempt_count=IF(window_started<UTC_TIMESTAMP()-INTERVAL 15 MINUTE,1,attempt_count+1),window_started=IF(window_started<UTC_TIMESTAMP()-INTERVAL 15 MINUTE,UTC_TIMESTAMP(),window_started)')->execute([$eh,$ip]);
    $q=db()->prepare('SELECT attempt_count FROM login_attempt_limits WHERE email_hash=? AND ip_hash=?');$q->execute([$eh,$ip]);
    if((int)$q->fetchColumn()>8)json_out(['error'=>'Too many attempts. Wait 15 minutes and try again.'],429);
    $q=db()->prepare('SELECT id,password_hash,status FROM users WHERE email=?'); $q->execute([$email]); $u=$q->fetch();
    if (!$u || $u['status']!=='active' || !password_verify($password,$u['password_hash'])) json_out(['error'=>'Invalid email or password.'],401);
    db()->prepare('DELETE FROM login_attempt_limits WHERE email_hash=? AND ip_hash=?')->execute([$eh,$ip]);
    if (password_needs_rehash($u['password_hash'],PASSWORD_DEFAULT)) db()->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash($password,PASSWORD_DEFAULT),$u['id']]);
    session_regenerate_id(true); $_SESSION['uid']=(int)$u['id']; $_SESSION['csrf']=bin2hex(random_bytes(32));
    audit('account.login',(int)$u['id']);
    json_out(['ok'=>true,'redirect'=>$u['role']==='admin'?'/admin/':'/dashboard.php','csrf'=>csrf_token()]);
}
if ($action==='logout') {
    $uid=(int)($_SESSION['uid']??0); if($uid) audit('account.logout',$uid);
    $_SESSION=[]; if(ini_get('session.use_cookies')) { $p=session_get_cookie_params(); setcookie(session_name(),'',time()-42000,$p['path'],$p['domain']??'',(bool)$p['secure'],(bool)$p['httponly']); }
    session_destroy(); json_out(['ok'=>true,'redirect'=>'/']);
}
json_out(['error'=>'Unknown action.'],400);
