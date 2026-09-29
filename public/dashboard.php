<?php
require dirname(__DIR__).'/app/bootstrap.php';
if(!current_user()){header('Location: /login.php');exit;}
$tpl=file_get_contents(dirname(__DIR__).'/app/templates/app-shell.html');
$tpl=str_replace('<body>','<body data-page="dashboard" data-service="home">',$tpl);
header('Content-Type: text/html; charset=utf-8'); header('Cache-Control: no-store, private');
echo $tpl;
