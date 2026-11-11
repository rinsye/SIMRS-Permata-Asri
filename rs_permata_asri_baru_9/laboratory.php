<?php
require_once __DIR__.'/includes/functions.php';$user=require_login();require_permission($user,'lab.manage');$pageTitle='Laboratorium';$pdo=db();$labStaff=$user['role_code']==='lab';
/** Parameter dan nilai rujukan selalu dibaca dari tabel master laboratorium. */
function lab_panel(string $test, PDO $pdo): array {
    $sql = "SELECT lp.id FROM lab_test_panels lp
            JOIN lab_panel_keywords lk ON lk.panel_id=lp.id
            WHERE LOWER(?) LIKE CONCAT('%', LOWER(lk.keyword), '%') AND lp.is_active=1
            ORDER BY LENGTH(lk.keyword) DESC, lp.id LIMIT 1";
    $stmt=$pdo->prepare($sql); $stmt->execute([$test]); $id=$stmt->fetchColumn();
    if(!$id) return [];
    $q=$pdo->prepare('SELECT parameter_name,result_unit,reference_range FROM lab_panel_parameters WHERE panel_id=? ORDER BY sort_order,id');
    $q->execute([$id]); $out=[];
    foreach($q->fetchAll() as $r) $out[$r['parameter_name']]=[$r['result_unit'],$r['reference_range']];
    return $out;
}
if($_SERVER['REQUEST_METHOD']==='POST'){
 if(!$labStaff){http_response_code(403);exit('Administrator hanya dapat melihat hasil laboratorium.');}check_csrf();$id=(int)($_POST['lab_id']??0);$action=$_POST['action']??'';
 $q=$pdo->prepare('SELECT l.id,l.status,l.test_name FROM lab_orders l WHERE l.id=?');$q->execute([$id]);$lab=$q->fetch();if(!$lab){http_response_code(404);exit('Order tidak ditemukan.');}
 if($action==='receive' && $lab['status']==='Menunggu'){$pdo->prepare("UPDATE lab_orders SET status='In Process',specimen=? WHERE id=?")->execute([trim($_POST['specimen']??''),$id]);flash('success','Spesimen diterima.');}
 elseif($action==='verify' && $lab['status']==='In Process'){
  $panel=lab_panel($lab['test_name'],$pdo);$values=$_POST['value']??[]; $valid=(bool)$panel;foreach($panel as $name=>$info)if(!isset($values[$name])||trim((string)$values[$name])==='')$valid=false;
  if(!$valid)flash('error',!$panel?'Panel pemeriksaan belum tersedia di master MariaDB. Tambahkan panel dan parameter terlebih dahulu.':'Seluruh parameter pemeriksaan harus diisi.');else{
   try{$pdo->beginTransaction();$pdo->prepare('DELETE FROM laboratory_values WHERE lab_order_id=?')->execute([$id]);$stmt=$pdo->prepare('INSERT INTO laboratory_values(lab_order_id,parameter_name,result_value,result_unit,reference_range) VALUES(?,?,?,?,?)');$summary=[];foreach($panel as $name=>$info){$val=trim((string)$values[$name]);$stmt->execute([$id,$name,$val,$info[0],$info[1]]);$summary[]=$name.': '.$val.' '.$info[0];}
   $pdo->prepare("UPDATE lab_orders SET status='Tervalidasi',result=?,verified_by=?,verified_at=NOW() WHERE id=?")->execute([implode("\n",$summary),$user['employee_id'],$id]);$pdo->prepare("UPDATE orders o JOIN lab_orders l ON l.order_id=o.id SET o.status='Completed' WHERE l.id=?")->execute([$id]);$pdo->commit();flash('success','Seluruh parameter berhasil divalidasi.');}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();flash('error','Gagal memvalidasi hasil.');}
  }
 }redirect('laboratory.php');
}
$rows=$pdo->query("SELECT l.id,l.test_name,l.specimen,l.status,l.result,o.order_no,o.priority,o.created_at,p.full_name patient_name,p.medical_record_no,d.full_name doctor_name FROM lab_orders l JOIN orders o ON o.id=l.order_id JOIN registrations r ON r.id=o.registration_id JOIN patients p ON p.id=r.patient_id JOIN employees d ON d.id=o.ordering_employee_id ORDER BY l.id DESC")->fetchAll();
require __DIR__.'/includes/header.php';?>
<h1 class="page-title">Laboratorium</h1><p class="page-subtitle">Penerimaan spesimen, pengisian hasil per parameter dan validasi. Parameter dan rentang rujukan bersumber dari master laboratorium di MariaDB; validasi klinis sesuai kebijakan laboratorium.</p>
<div class="card no-print"><h2 class="section-title">Cetak Hasil Per Pasien</h2><p class="note">Hanya petugas laboratorium dapat mencetak gabungan seluruh hasil tervalidasi satu pasien.</p><?php if($labStaff):?><form action="lab_print.php" method="get" target="_blank" class="actions"><select class="input" style="max-width:420px" name="patient_id" required><option value="">Pilih pasien</option><?php $patients=$pdo->query("SELECT DISTINCT p.id,p.full_name,p.medical_record_no FROM patients p JOIN registrations r ON r.patient_id=p.id JOIN orders o ON o.registration_id=r.id JOIN lab_orders l ON l.order_id=o.id WHERE l.status='Tervalidasi' ORDER BY p.full_name")->fetchAll();foreach($patients as $person):?><option value="<?=$person['id']?>"><?=e($person['full_name'].' · '.$person['medical_record_no'])?></option><?php endforeach;?></select><button class="btn btn-primary">Buka Lembar Hasil Gabungan</button></form><?php endif;?></div>
<div class="card" style="margin-top:18px"><h2 class="section-title">Daftar Perintah Laboratorium</h2><div class="table-wrap"><table><thead><tr><th>Nomor Perintah</th><th>Pasien</th><th>Pemeriksaan</th><th>Status dan Hasil</th></tr></thead><tbody><?php foreach($rows as $r):$panel=lab_panel($r['test_name'],$pdo);?><tr><td><b><?=e($r['order_no'])?></b><small><?=e($r['doctor_name'])?></small></td><td><b><?=e($r['patient_name'])?></b><small><?=e($r['medical_record_no'])?></small></td><td><?=e($r['test_name'])?><small>Spesimen: <?=e($r['specimen']?:'Belum diterima')?></small></td><td><span class="badge <?=status_badge_class($r['status'])?>"><?=e(status_label($r['status']))?></span>
<?php if($labStaff && $r['status']==='Menunggu'):?><form method="post" style="margin-top:12px"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="lab_id" value="<?=$r['id']?>"><input type="hidden" name="action" value="receive"><input class="input" name="specimen" placeholder="Jenis spesimen" required><button class="btn btn-primary" style="margin-top:9px">Terima Spesimen</button></form>
<?php elseif($labStaff && $r['status']==='In Process'):?><form method="post" style="margin-top:12px"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="lab_id" value="<?=$r['id']?>"><input type="hidden" name="action" value="verify"><div class="table-wrap"><table><thead><tr><th>Parameter</th><th>Hasil</th><th>Satuan</th><th>Rentang rujukan</th></tr></thead><tbody><?php if(!$panel):?><tr><td colspan="4">Panel pemeriksaan belum dikonfigurasi di master laboratorium; hubungi administrator laboratorium.</td></tr><?php endif; foreach($panel as $name=>$info):?><tr><td><?=e($name)?></td><td><input class="input" name="value[<?=e($name)?>]" required></td><td><?=e($info[0])?></td><td><?=e($info[1])?></td></tr><?php endforeach;?></tbody></table></div><button class="btn btn-success" style="margin-top:10px">Simpan dan Validasi Semua Hasil</button></form>
<?php elseif($r['status']==='Tervalidasi'):?><div class="note" style="white-space:pre-line;margin-top:10px"><?=e($r['result'])?></div><?php endif;?></td></tr><?php endforeach;?><?php if(!$rows):?><tr><td colspan="4">Belum ada permintaan laboratorium.</td></tr><?php endif;?></tbody></table></div></div>
<?php require __DIR__.'/includes/footer.php';?>
