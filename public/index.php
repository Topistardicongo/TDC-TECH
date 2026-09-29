<?php
require dirname(__DIR__).'/app/bootstrap.php';
$tpl=file_get_contents(dirname(__DIR__).'/app/templates/app-shell.html');
$tpl=str_replace('<body>','<body data-page="landing">',$tpl);
header('Content-Type: text/html; charset=utf-8'); header('X-Content-Type-Options: nosniff');
echo $tpl;
