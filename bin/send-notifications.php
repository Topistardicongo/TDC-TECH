<?php
require dirname(__DIR__).'/app/notifications.php';
try{$sent=send_notification_batch((int)($argv[1]??30));fwrite(STDOUT,"Sent {$sent} notification email(s).\n");}
catch(Throwable $e){fwrite(STDERR,'Notification worker failed: '.$e->getMessage()."\n");exit(1);}
