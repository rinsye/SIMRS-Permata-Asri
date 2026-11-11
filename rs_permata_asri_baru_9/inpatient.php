<?php
require_once __DIR__.'/includes/functions.php';
$user=require_login(); require_permission($user,'inpatient.manage'); $pageTitle='Rawat Inap'; $pdo=db();
[$scope,$params]=patient_scope($user,'active');
$st=$pdo->prepare("SELECT r.id,r.registration_no,p.full_name,p.medical_record_no FROM registrations r JOIN patients p ON p.id=r.patient_id WHERE ($scope) ORDER BY r.id DESC LIMIT 70");$st->execute($params);$registrations=$st->fetchAll();
if($_SERVER['REQUEST_METHOD']==='POST'){
 check_csrf(); if(is_nurse($user)){http_response_code(403);exit('Akses ditolak.');}
 $reg=(int)($_POST['registration_id']??0); require_patient_registration($user,$reg,'active'); $bedId=(int)($_POST['bed_id']??0);
 try{
  $pdo->beginTransaction();
  $q=$pdo->prepare('SELECT room,bed_code FROM hospital_beds WHERE id=? AND is_active=1 FOR UPDATE');$q->execute([$bedId]);$bed=$q->fetch();
  if(!$bed)throw new RuntimeException('Tempat tidur tidak ditemukan.');
  $q=$pdo->prepare("SELECT id FROM inpatient_admissions WHERE room=? AND bed=? AND status='Dirawat' LIMIT 1");$q->execute([$bed['room'],$bed['bed_code']]);
  if($q->fetchColumn())throw new RuntimeException('Tempat tidur sudah ditempati pasien lain.');
  $q=$pdo->prepare("SELECT id FROM inpatient_admissions WHERE registration_id=? AND status='Dirawat' LIMIT 1");$q->execute([$reg]);
  if($q->fetchColumn())throw new RuntimeException('Pasien sudah memiliki rawat inap aktif.');
  $pdo->prepare("INSERT INTO inpatient_admissions(registration_id,ordered_by,room,bed,status,admitted_at) VALUES (?,?,?,?,'Dirawat',NOW())")->execute([$reg,$user['employee_id'],$bed['room'],$bed['bed_code']]);
  $pdo->prepare("UPDATE registrations SET status='Rawat Inap' WHERE id=?")->execute([$reg]);
  $pdo->commit();flash('success','Penempatan pasien berhasil disimpan.');
 }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();flash('error',$e instanceof RuntimeException?$e->getMessage():'Gagal mengalokasikan tempat tidur.');}
 redirect('inpatient.php');
}
$st=$pdo->prepare("SELECT ia.*,p.full_name,p.medical_record_no,e.employee_code FROM inpatient_admissions ia JOIN registrations r ON r.id=ia.registration_id JOIN patients p ON p.id=r.patient_id JOIN employees e ON e.id=ia.ordered_by WHERE ($scope) ORDER BY ia.id DESC");$st->execute($params);$rows=$st->fetchAll();
// Peta kapasitas ditampilkan hanya kepada pengguna dengan izin modul rawat inap.
$beds=$pdo->query("SELECT b.*,ia.id AS admission_id,p.full_name AS patient_name FROM hospital_beds b LEFT JOIN inpatient_admissions ia ON ia.room=b.room AND ia.bed=b.bed_code AND ia.status='Dirawat' LEFT JOIN registrations r ON r.id=ia.registration_id LEFT JOIN patients p ON p.id=r.patient_id WHERE b.is_active=1 ORDER BY b.room,b.bed_code")->fetchAll();
require __DIR__.'/includes/header.php';
?>
<h1 class="page-title">Rawat Inap</h1><p class="page-subtitle">Penempatan pasien dan ketersediaan tempat tidur berdasarkan data rawat inap aktif.</p>
<div class="grid grid-2"><div class="card"><h2 class="section-title">Penempatan Pasien</h2>
<?php if(!is_nurse($user)):?><form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><div class="field"><label>Pasien / Kunjungan</label><select name="registration_id" class="input" required><option value="">Pilih kunjungan</option><?php foreach($registrations as $r):?><option value="<?=$r['id']?>"><?=e($r['registration_no'].' · '.$r['medical_record_no'].' · '.$r['full_name'])?></option><?php endforeach;?></select></div><div class="field"><label>Tempat Tidur Tersedia</label><select class="input" name="bed_id" required><option value="">Pilih kamar dan nomor tempat tidur</option><?php foreach($beds as $b):if(!$b['admission_id']):?><option value="<?=$b['id']?>"><?=e($b['room'].' · '.$b['bed_code'].' · '.$b['room_class'])?></option><?php endif;endforeach;?></select></div><button class="btn btn-primary">Tempatkan Pasien</button></form><?php else:?><p class="note">Perawat dapat memantau pasien yang sedang dirawat sesuai pembagian unitnya.</p><?php endif;?></div>
<div class="table-wrap"><table><thead><tr><th>Pasien</th><th>Kamar / Tempat Tidur</th><th>Status</th></tr></thead><tbody><?php foreach($rows as $r):?><tr><td><b><?=e($r['full_name'])?></b><small><?=e($r['medical_record_no'])?></small></td><td><?=e($r['room'].' / '.$r['bed'])?></td><td><span class="badge <?=($r['status']==='Dirawat'?'badge-yellow':'badge-green')?>"><?=e($r['status'])?></span></td></tr><?php endforeach;?><?php if(!$rows):?><tr><td colspan="3">Belum ada penempatan aktif dalam cakupan akses Anda.</td></tr><?php endif;?></tbody></table></div></div>
<div class="card" style="margin-top:20px"><h2 class="section-title">Peta Seluruh Tempat Tidur</h2><p class="note">Hijau berarti tersedia, merah berarti sedang digunakan. Nama pasien hanya terlihat pada daftar pasien yang diizinkan di atas.</p><div class="bed-grid" style="margin-top:16px"><?php foreach($beds as $b):?><div class="bed-tile <?=$b['admission_id']?'occupied':'available'?>"><small><?=e($b['room'])?> · <?=e($b['room_class'])?></small><b><?=e($b['bed_code'])?></b><span class="badge <?=$b['admission_id']?'badge-red':'badge-green'?>"><?=$b['admission_id']?'Terisi':'Tersedia'?></span></div><?php endforeach;?></div></div>
<?php require __DIR__.'/includes/footer.php';?>
