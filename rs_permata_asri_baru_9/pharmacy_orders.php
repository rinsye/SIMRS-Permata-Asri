<?php
require_once __DIR__.'/includes/functions.php';$user=require_login();require_permission($user,'farmasi.manage');$pageTitle='Penyiapan dan Penyerahan Obat';$pdo=db();$staff=$user['role_code']==='farmasi';
if($_SERVER['REQUEST_METHOD']==='POST'){
 if(!$staff){http_response_code(403);exit('Administrator hanya dapat memantau order obat.');}check_csrf();$orderId=(int)($_POST['order_id']??0);$action=$_POST['action']??'';
 try{
  $pdo->beginTransaction();$q=$pdo->prepare("SELECT id,detail FROM orders WHERE id=? AND order_type='Obat' FOR UPDATE");$q->execute([$orderId]);$order=$q->fetch();if(!$order)throw new RuntimeException('Order tidak ditemukan.');
  $pdo->prepare('INSERT IGNORE INTO pharmacy_dispensing(order_id) VALUES(?)')->execute([$orderId]);
  $q=$pdo->prepare('SELECT * FROM pharmacy_dispensing WHERE order_id=? FOR UPDATE');$q->execute([$orderId]);$disp=$q->fetch();
  if($action==='start' && $disp['status']==='Menunggu'){
   $pdo->prepare("UPDATE pharmacy_dispensing SET status='Dalam Proses',started_by=?,started_at=NOW() WHERE id=?")->execute([$user['employee_id'],$disp['id']]);
   // Pemisahan item menggunakan setiap baris; untuk resep satu baris seluruhnya satu item.
   $names=preg_split('/\\r?\\n/',trim($order['detail']));$ins=$pdo->prepare('INSERT IGNORE INTO pharmacy_dispensing_items(dispensing_id,item_name) VALUES(?,?)');foreach($names as $name){if(trim($name)!=='')$ins->execute([$disp['id'],trim($name)]);}
  }elseif($action==='check' && $disp['status']==='Dalam Proses'){
   $id=(int)($_POST['item_id']??0);$pdo->prepare('UPDATE pharmacy_dispensing_items SET checked=? WHERE id=? AND dispensing_id=?')->execute([isset($_POST['checked'])?1:0,$id,$disp['id']]);
  }elseif($action==='handover' && $disp['status']==='Dalam Proses'){
   $q=$pdo->prepare('SELECT COUNT(*) FROM pharmacy_dispensing_items WHERE dispensing_id=? AND checked=0');$q->execute([$disp['id']]);if((int)$q->fetchColumn()>0)throw new RuntimeException('Seluruh item harus dicentang sebelum serah terima.');
   $q=$pdo->prepare('SELECT COUNT(*) FROM pharmacy_dispensing_items WHERE dispensing_id=?');$q->execute([$disp['id']]);if(!(int)$q->fetchColumn())throw new RuntimeException('Order belum memiliki item obat.');
   $pdo->prepare("UPDATE pharmacy_dispensing SET status='Diserahkan',handed_over_by=?,handed_over_at=NOW() WHERE id=?")->execute([$user['employee_id'],$disp['id']]);$pdo->prepare("UPDATE orders SET status='Completed' WHERE id=?")->execute([$orderId]);
  }else throw new RuntimeException('Tindakan tidak sesuai status order.');
  $pdo->commit();flash('success','Status penyiapan obat diperbarui.');
 }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();flash('error',$e->getMessage());}redirect('pharmacy_orders.php');
}
$rows=$pdo->query("SELECT o.id,o.order_no,o.detail,o.priority,o.created_at,p.full_name patient_name,p.medical_record_no,d.full_name doctor_name,dp.id dispensing_id,COALESCE(dp.status,'Menunggu') dispense_status,dp.handed_over_at FROM orders o JOIN registrations r ON r.id=o.registration_id JOIN patients p ON p.id=r.patient_id JOIN employees d ON d.id=o.ordering_employee_id LEFT JOIN pharmacy_dispensing dp ON dp.order_id=o.id WHERE o.order_type='Obat' ORDER BY o.id DESC")->fetchAll();
require __DIR__.'/includes/header.php';?>
<h1 class="page-title">Penyiapan dan Penyerahan Obat</h1><p class="page-subtitle">Pilih pasien, proses resep, periksa satu per satu obat, kemudian catat penyerahan. Administrator hanya dapat melihat.</p>
<div class="card"><div class="table-wrap"><table><thead><tr><th>No. Order dan Pasien</th><th>Perintah Obat</th><th>Dokter</th><th>Penyiapan</th></tr></thead><tbody>
<?php foreach($rows as $r):?><tr><td><b><?=e($r['patient_name'])?></b><small><?=e($r['medical_record_no'].' · '.$r['order_no'])?></small></td><td><?=nl2br(e($r['detail']))?><small><?=e($r['priority'])?></small></td><td><?=e($r['doctor_name'])?></td><td><span class="badge <?=($r['dispense_status']==='Diserahkan'?'badge-green':($r['dispense_status']==='Dalam Proses'?'badge-yellow':'badge-blue'))?>"><?=e($r['dispense_status'])?></span>
<?php if($staff && $r['dispense_status']==='Menunggu'):?><form method="post" style="margin-top:10px"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="order_id" value="<?=$r['id']?>"><input type="hidden" name="action" value="start"><button class="btn btn-primary">Mulai Proses</button></form><?php endif;?>
<?php if($r['dispense_status']==='Dalam Proses' && $r['dispensing_id']):?><?php $q=$pdo->prepare('SELECT id,item_name,checked FROM pharmacy_dispensing_items WHERE dispensing_id=? ORDER BY id');$q->execute([$r['dispensing_id']]);$meds=$q->fetchAll();?><div style="margin-top:12px"><?php foreach($meds as $med):?><form method="post" class="actions" style="margin-bottom:9px"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="order_id" value="<?=$r['id']?>"><input type="hidden" name="item_id" value="<?=$med['id']?>"><input type="hidden" name="action" value="check"><label><input type="checkbox" name="checked" value="1" <?=$med['checked']?'checked':''?> <?=$staff?'onchange="this.form.submit()"':'disabled'?>> <?=e($med['item_name'])?></label></form><?php endforeach;?><?php if($staff):?><form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="order_id" value="<?=$r['id']?>"><input type="hidden" name="action" value="handover"><button class="btn btn-success" onclick="return confirm('Pastikan obat sudah diperiksa dan benar-benar diserahkan kepada pasien/penerima.')">Serahkan Obat</button></form><?php endif;?></div><?php endif;?>
<?php if($r['handed_over_at']):?><small>Diserahkan pada <?=e($r['handed_over_at'])?></small><?php endif;?></td></tr><?php endforeach;?><?php if(!$rows):?><tr><td colspan="4">Belum ada resep. Dokter dapat membuat perintah Obat dari CPOE.</td></tr><?php endif;?></tbody></table></div></div>
<?php require __DIR__.'/includes/footer.php';?>
