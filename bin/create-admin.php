<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require dirname(__DIR__).'/app/bootstrap.php';
$email=strtolower(trim((string)($argv[1]??'')));
$name=trim((string)($argv[2]??'TDC Administrator'));
echo "Admin email: "; $fromStdin=trim((string)fgets(STDIN)); if(filter_var($fromStdin,FILTER_VALIDATE_EMAIL))$email=strtolower($fromStdin);
echo "Admin password (12+ characters): "; $password=trim((string)fgets(STDIN));
if(!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($password)<12){fwrite(STDERR,"Invalid email or password length.\n");exit(1);}
$q=db()->prepare("INSERT INTO users(name,email,password_hash,role) VALUES(?,?,?,'admin') ON DUPLICATE KEY UPDATE role='admin',status='active',password_hash=VALUES(password_hash),name=VALUES(name)");
$q->execute([$name,$email,password_hash($password,PASSWORD_DEFAULT)]);
echo "Administrator created/updated: {$email}\n";
