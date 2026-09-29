<?php
require dirname(__DIR__,2).'/app/bootstrap.php';
if(!current_user()){header('Location: /login.php');exit;}
$slug=basename($_SERVER['SCRIPT_NAME'],'.php');
$allowed=['social-ads','music','verification','web-dev','account-mgmt','press','smm','numbers','bots','proxies'];
if(!in_array($slug,$allowed,true)){http_response_code(404);exit('Service page not found.');}
$tpl=file_get_contents(dirname(__DIR__,2).'/app/templates/app-shell.html');
$tpl=str_replace('<body>','<body data-page="service" data-service="'.htmlspecialchars($slug,ENT_QUOTES).'">',$tpl);
header('Content-Type: text/html; charset=utf-8'); header('Cache-Control: no-store, private');
echo $tpl;
