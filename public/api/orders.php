<?php
require dirname(__DIR__,2).'/app/bootstrap.php';
$u=require_user();
if ($_SERVER['REQUEST_METHOD']==='GET') {
    $q=db()->prepare('SELECT o.id,s.name service,o.description,o.details,o.admin_note,o.amount,o.status,o.created_at FROM orders o JOIN services s ON s.id=o.service_id WHERE o.user_id=? ORDER BY o.id DESC LIMIT 100'); $q->execute([$u['id']]); $orders=$q->fetchAll(); foreach($orders as &$order){$order['admin_note']=decrypt_private_note($order['admin_note']);} unset($order);
    $q=db()->prepare('SELECT id,amount,kind,status,note,created_at FROM wallet_ledger WHERE user_id=? ORDER BY id DESC LIMIT 100'); $q->execute([$u['id']]);
    json_out(['orders'=>$orders,'transactions'=>$q->fetchAll()]);
}
require_method('POST'); require_csrf(); $data=json_body(); $action=$data['action']??'order';
$slug=preg_replace('/[^a-z0-9-]/','',(string)($data['service_slug']??''));
$q=db()->prepare('SELECT id,name,price,pricing_mode FROM services WHERE slug=? AND active=1'); $q->execute([$slug]); $service=$q->fetch();
if(!$service) json_out(['error'=>'This service is currently unavailable.'],404);
$desc=trim((string)($data['description']??$service['name'])); $desc=text_cut($desc,0,255);
$details=$data['details']??[]; if(!is_array($details)) $details=[]; if(strlen(json_encode($details)?:'')>5000) json_out(['error'=>'Order details are too long.'],422);
// SMM prices are computed on the server from the configured per-1,000 rate.
$amount=(float)$service['price'];
if($service['pricing_mode']==='per_1000') { $qty=filter_var($details['quantity']??0,FILTER_VALIDATE_INT); if(!$qty||$qty<100||$qty>1000000) json_out(['error'=>'Quantity must be from 100 to 1,000,000.'],422); $amount=round(($qty/1000)*(float)$service['price'],2); }
if($service['pricing_mode']==='per_gb') { $qty=filter_var($details['gb']??0,FILTER_VALIDATE_INT); if(!$qty||$qty<1||$qty>100) json_out(['error'=>'Proxy amount must be from 1 to 100 GB.'],422); $amount=round($qty*(float)$service['price'],2); }
if(isset($details['quantity'])) $details['quantity']=(int)$details['quantity'];
if(isset($details['gb'])) $details['gb']=(int)$details['gb'];
if($amount<0 || $amount>100000) json_out(['error'=>'Invalid order amount.'],422);
if(($data['action']??'')==='quote') json_out(['amount'=>$amount,'currency'=>'GBP']);
$pdo=db(); $pdo->beginTransaction();
try {
    $lock=$pdo->prepare('SELECT id FROM users WHERE id=? FOR UPDATE'); $lock->execute([$u['id']]);
    $bal=$pdo->prepare("SELECT COALESCE(SUM(CASE WHEN status='posted' THEN amount ELSE 0 END),0) FROM wallet_ledger WHERE user_id=?"); $bal->execute([$u['id']]);
    if((float)$bal->fetchColumn()<$amount) { $pdo->rollBack(); json_out(['error'=>'Insufficient wallet balance. Request a top-up and wait for confirmation.'],402); }
    $q=$pdo->prepare('INSERT INTO orders(user_id,service_id,description,details,amount,status,created_at) VALUES(?,?,?,?,?,\'pending\',UTC_TIMESTAMP())'); $q->execute([$u['id'],$service['id'],$desc,json_encode($details),$amount]); $orderId=(int)$pdo->lastInsertId();
    if($amount>0) { $q=$pdo->prepare("INSERT INTO wallet_ledger(user_id,amount,kind,status,reference,note,created_at) VALUES(?,?,'debit','posted',?,?,UTC_TIMESTAMP())"); $q->execute([$u['id'],-$amount,'order:'.$orderId,$desc]); }
    $pdo->commit(); audit('order.created',(int)$u['id'],['order_id'=>$orderId,'amount'=>$amount]);
    json_out(['ok'=>true,'order_id'=>$orderId,'amount'=>$amount,'message'=>'Order submitted.']);
} catch(Throwable $e) { if($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
