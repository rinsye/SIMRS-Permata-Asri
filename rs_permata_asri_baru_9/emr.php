<?php
require_once __DIR__ . '/includes/functions.php';
$user = require_login();
require_permission($user, 'emr.manage');
$pageTitle = 'Rekam Medis Elektronik';

[$regFilter,$regParams]=patient_scope($user,'active');
$registrationSql = "SELECT DISTINCT r.id, r.registration_no, p.medical_record_no, p.full_name, un.name AS unit_name FROM registrations r JOIN patients p ON p.id=r.patient_id JOIN units un ON un.id=r.unit_id WHERE ($regFilter) ORDER BY r.id DESC LIMIT 50";
$registrationStmt=db()->prepare($registrationSql); $registrationStmt->execute($regParams); $registrations=$registrationStmt->fetchAll();
if (is_admin($user)) {
 $staff=db()->query("SELECT e.id,e.employee_code,e.full_name,e.profession,r.name role_name FROM employees e JOIN roles r ON r.id=e.role_id WHERE e.is_active=1 AND r.code IN ('dokter','dokter_umum','dokter_igd','perawat','igd') ORDER BY e.full_name")->fetchAll();
} else {
 $q=db()->prepare('SELECT e.id,e.employee_code,e.full_name,e.profession,r.name role_name FROM employees e JOIN roles r ON r.id=e.role_id WHERE e.id=?');
 $q->execute([(int)$user['employee_id']]);$staff=$q->fetchAll();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!is_doctor($user)) {http_response_code(403);exit('Hanya dokter/DPJP yang dapat mengisi atau mengubah catatan klinis EMR.');}
    $registrationId = (int) ($_POST['registration_id'] ?? 0);
    $examinerId = (int) ($_POST['examiner_id'] ?? 0);
    $activity = trim($_POST['activity'] ?? '');
    $subjective = trim($_POST['subjective'] ?? '');
    $objective = trim($_POST['objective'] ?? '');
    $assessment = trim($_POST['assessment'] ?? '');
    $plan = trim($_POST['plan'] ?? '');

    if (!$registrationId || !$examinerId || $activity === '') {
        flash('error', 'Pilih pasien dan pemeriksa, lalu isi aktivitas pemeriksaan.');
        redirect('emr.php');
    }

    $pdo = db();
    require_patient_registration($user,$registrationId,'write');
    if (!is_admin($user) && $examinerId !== (int)$user['employee_id']) deny_patient();
    $pdo->beginTransaction();
    try {
        $find = $pdo->prepare('SELECT id FROM emr WHERE registration_id=? LIMIT 1');
        $find->execute([$registrationId]);
        $emrId = $find->fetchColumn();
        if ($emrId) {
            $pdo->prepare('UPDATE emr SET subjective=?, objective=?, assessment=?, plan=?, updated_at=NOW() WHERE id=?')->execute([$subjective,$objective,$assessment,$plan,$emrId]);
        } else {
            $pdo->prepare('INSERT INTO emr (registration_id, subjective, objective, assessment, plan, created_at, updated_at) VALUES (?,?,?,?,?,NOW(),NOW())')->execute([$registrationId,$subjective,$objective,$assessment,$plan]);
            $emrId = (int) $pdo->lastInsertId();
        }
        $pdo->prepare('INSERT INTO emr_staff (emr_id, employee_id, activity, created_at) VALUES (?,?,?,NOW())')->execute([$emrId,$examinerId,$activity]);
        $pdo->commit();
        flash('success', 'Catatan EMR dan ID petugas pemeriksa berhasil disimpan.');
    } catch(Throwable $e) {
        $pdo->rollBack();
        flash('error', 'Gagal menyimpan EMR.');
    }
    redirect('emr.php');
}

// Dokter melihat seluruh riwayat EMR pasien yang pernah dirawatnya atau dirujuk kepadanya.
// Perawat hanya melihat EMR milik pasien yang sedang aktif dalam cakupan unitnya.
[$historyFilter,$historyParams]=patient_scope($user,'history');
if (is_nurse($user)) {
    // Tidak mengakses EMR kunjungan dokter/unit lain meski pasien yang sama.
    [$historyFilter,$historyParams]=patient_scope($user,'active');
}
$historySql = "SELECT em.id, em.assessment, em.plan, em.updated_at, p.full_name AS patient_name, p.medical_record_no, GROUP_CONCAT(CONCAT(e.employee_code,' - ',e.full_name,' [',es.activity,']') ORDER BY es.id SEPARATOR ' | ') AS examiners FROM emr em JOIN registrations r ON r.id=em.registration_id JOIN patients p ON p.id=r.patient_id LEFT JOIN emr_staff es ON es.emr_id=em.id LEFT JOIN employees e ON e.id=es.employee_id WHERE ($historyFilter) GROUP BY em.id ORDER BY em.id DESC LIMIT 30";
$historyStmt=db()->prepare($historySql); $historyStmt->execute($historyParams); $history=$historyStmt->fetchAll();

$labSql = "SELECT l.status AS lab_status, l.result, l.verified_at, l.test_name,
                  o.order_no, o.priority, o.created_at,
                  p.full_name AS patient_name, p.medical_record_no,
                  req.employee_code AS requester_code, req.full_name AS requester_name,
                  ver.employee_code AS verifier_code, ver.full_name AS verifier_name
           FROM lab_orders l
           JOIN orders o ON o.id=l.order_id
           JOIN registrations r ON r.id=o.registration_id
           JOIN patients p ON p.id=r.patient_id
           JOIN employees req ON req.id=o.ordering_employee_id
           LEFT JOIN employees ver ON ver.id=l.verified_by";
[$labFilter,$labParams]=patient_scope($user,'history');
if (is_nurse($user)) {
    [$labFilter,$labParams]=patient_scope($user,'active');
}
$labSql .= ' WHERE ('.$labFilter.') ORDER BY l.id DESC LIMIT 20';
$labStmt=db()->prepare($labSql); $labStmt->execute($labParams); $labResults=$labStmt->fetchAll();

$radSql="SELECT ro.id,ro.exam_name,ro.status,ro.result,ro.verified_at,o.order_no,r.id registration_id,r.registration_no,p.full_name patient_name,p.medical_record_no FROM radiology_orders ro JOIN orders o ON o.id=ro.order_id JOIN registrations r ON r.id=o.registration_id JOIN patients p ON p.id=r.patient_id";
[$radFilter,$radParams]=patient_scope($user,'history'); if(is_nurse($user)){[$radFilter,$radParams]=patient_scope($user,'active');}
$radSql.=' WHERE ('.$radFilter.') ORDER BY ro.id DESC LIMIT 30';$radStmt=db()->prepare($radSql);$radStmt->execute($radParams);$radiologyResults=$radStmt->fetchAll();
require __DIR__ . '/includes/header.php';
?>
<h1 class="page-title">Rekam Medis Elektronik</h1>
<?php if(in_array($user['role_code'],['admin_simrs','rekammedis'],true)):?><p><a class="btn btn-secondary" href="emr_archive.php">Cari Arsip EMR berdasarkan Nama / Registrasi / Tanggal Lahir</a></p><?php endif;?>
<p class="page-subtitle">Catatan klinis menyimpan siapa dokter/perawat yang melakukan pemeriksaan beserta ID pegawai dan aktivitasnya.</p>
<div class="grid grid-2">
  <?php if(is_doctor($user)):?><div class="card"><h2 class="section-title">Tambah / Perbarui Catatan Dokter</h2><form method="POST">
    <div class="field"><label>Kunjungan Pasien</label><select class="input" name="registration_id" required><option value="">-- Pilih Kunjungan --</option><?php foreach($registrations as $r): ?><option value="<?= $r['id'] ?>"><?= e($r['registration_no'].' · '.$r['medical_record_no'].' · '.$r['full_name'].' · '.$r['unit_name']) ?></option><?php endforeach; ?></select></div>
    <div class="field"><label>Pemeriksa / Pelaksana</label><select class="input" name="examiner_id" required><option value="">-- Pilih Pegawai --</option><?php foreach($staff as $s): ?><option value="<?= $s['id'] ?>"><?= e($s['employee_code'].' · '.$s['full_name'].' · '.$s['role_name']) ?></option><?php endforeach; ?></select></div>
    <div class="field"><label>Aktivitas Pemeriksa</label><input class="input" name="activity" placeholder="Contoh: pemeriksaan fisik, pengukuran tanda vital" required></div>
    <div class="field"><label>Subjektif</label><textarea class="input" name="subjective"></textarea></div>
    <div class="field"><label>Objektif</label><textarea class="input" name="objective"></textarea></div>
    <div class="field"><label>Asesmen</label><textarea class="input" name="assessment"></textarea></div>
    <div class="field"><label>Rencana</label><textarea class="input" name="plan"></textarea></div>
    <button class="btn btn-primary">Simpan EMR</button>
  </form></div><?php else: ?><div class="card"><h2 class="section-title">Rekam Medis (Baca Saja)</h2><p class="note">Role ini tidak dapat mengubah catatan klinis. Admin dan petugas arsip dapat mengunggah scan berkas melalui menu Arsip Rekam Medis. Perawat hanya mengisi tanda vital dan tindak lanjut keperawatan pada modul unitnya.</p><?php if(in_array($user['role_code'],['admin_simrs','rekammedis'],true)):?><a class="btn btn-secondary" href="emr_archive.php">Buka Arsip dan Unggah Scan Berkas</a><?php endif;?></div><?php endif; ?>
  <div class="table-wrap"><table><thead><tr><th>Pasien</th><th>Asesmen / Rencana</th><th>Pemeriksa</th></tr></thead><tbody><?php foreach($history as $h): ?><tr><td><b><?= e($h['patient_name']) ?></b><br><small><?= e($h['medical_record_no']) ?></small></td><td><?= e($h['assessment']) ?><br><small><?= e($h['plan']) ?></small></td><td><small><?= e($h['examiners'] ?? 'Belum ada') ?></small></td></tr><?php endforeach; ?></tbody></table></div>
</div>

<div class="card" style="margin-top:18px">
  <h2 class="section-title">Hasil Laboratorium dari Order Dokter</h2>
  <p class="note">Dokter dapat melihat apakah order laboratorium masih diproses atau sudah tervalidasi, termasuk hasil dan petugas laboratorium yang memverifikasi.</p>
  <div class="table-wrap" style="margin-top:12px">
    <table>
      <thead><tr><th>Order</th><th>Pasien</th><th>Pemeriksaan</th><th>Status</th><th>Hasil</th><th>Verifikasi</th></tr></thead>
      <tbody>
      <?php if (!$labResults): ?>
        <tr><td colspan="6" style="text-align:center;padding:24px;color:#667085">Belum ada order laboratorium untuk ditampilkan.</td></tr>
      <?php endif; ?>
      <?php foreach ($labResults as $lab): ?>
        <tr>
          <td><b><?= e($lab['order_no']) ?></b><br><small><?= e($lab['priority']) ?></small></td>
          <td><b><?= e($lab['patient_name']) ?></b><br><small><?= e($lab['medical_record_no']) ?></small></td>
          <td><?= e($lab['test_name']) ?></td>
          <td><span class="badge <?= status_badge_class($lab['lab_status']) ?>"><?= e(status_label($lab['lab_status'])) ?></span></td>
          <td><?= $lab['result'] ? nl2br(e($lab['result'])) : '<span class="note">Belum tersedia</span>' ?></td>
          <td>
            <?php if ($lab['verified_at']): ?>
              <b><?= e(($lab['verifier_code'] ?? '-') . ' - ' . ($lab['verifier_name'] ?? '-')) ?></b><br>
              <small><?= e(date('d/m/Y H:i', strtotime($lab['verified_at']))) ?></small>
            <?php else: ?>
              <span class="note">Belum diverifikasi</span>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>
<div class="card" style="margin-top:18px"><h2 class="section-title">Hasil Radiologi Pasien</h2><p class="note">Hasil radiologi yang telah diinput dan diarsipkan oleh petugas radiologi ditampilkan berdasarkan cakupan pasien role yang sedang login.</p><div class="table-wrap"><table><thead><tr><th>Pasien</th><th>Pemeriksaan</th><th>Status</th><th>Hasil</th><th>Arsip</th></tr></thead><tbody><?php foreach($radiologyResults as $rr):?><tr><td><?=e($rr['patient_name'])?><small><?=e($rr['medical_record_no'].' · '.$rr['registration_no'])?></small></td><td><?=e($rr['exam_name'])?></td><td><span class="badge <?=status_badge_class($rr['status'])?>"><?=e(status_label($rr['status']))?></span></td><td><?= $rr['result']?nl2br(e($rr['result'])):'<span class="note">Belum tersedia</span>' ?></td><td><?php $af=db()->prepare('SELECT id,description,original_name FROM radiology_attachments WHERE radiology_order_id=? ORDER BY id DESC');$af->execute([$rr['id']]);foreach($af as $f):?><a href="radiology_file.php?id=<?=$f['id']?>" target="_blank"><?=e($f['description'].' · '.$f['original_name'])?></a><br><?php endforeach;?></td></tr><?php endforeach;?><?php if(!$radiologyResults):?><tr><td colspan="5">Belum ada hasil radiologi untuk pasien dalam cakupan Anda.</td></tr><?php endif;?></tbody></table></div></div>
<?php require __DIR__ . '/includes/footer.php'; ?>
