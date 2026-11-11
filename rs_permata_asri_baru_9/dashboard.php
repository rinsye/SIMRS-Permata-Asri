<?php
require_once __DIR__ . '/includes/functions.php';
$user = require_login();
require_permission($user, 'dashboard.view');
$pageTitle = 'Dashboard';

[$filter,$params]=patient_scope($user,'active');
$makeCount=static function(string $sql,array $params): int { $stmt=db()->prepare($sql);$stmt->execute($params);return (int)$stmt->fetchColumn(); };
$stats = [
 'patients'=>$makeCount("SELECT COUNT(DISTINCT r.patient_id) FROM registrations r WHERE ($filter)",$params),
 'today'=>$makeCount("SELECT COUNT(*) FROM registrations r WHERE r.visit_date=CURDATE() AND ($filter)",$params),
 'lab_pending'=>$makeCount("SELECT COUNT(*) FROM lab_orders l JOIN orders o ON o.id=l.order_id JOIN registrations r ON r.id=o.registration_id WHERE l.status IN ('Menunggu','In Process') AND ($filter)",$params),
 'inpatient'=>$makeCount("SELECT COUNT(*) FROM inpatient_admissions ia JOIN registrations r ON r.id=ia.registration_id WHERE ia.status='Dirawat' AND ($filter)",$params),
];

$doctorPatients = [];
if (is_doctor($user)) {
    $stmt=db()->prepare("SELECT r.id, r.registration_no, r.visit_date, r.status,
        p.medical_record_no, p.full_name AS patient_name, un.name AS unit_name,
        r.queue_no, r.complaint
        FROM registrations r JOIN patients p ON p.id=r.patient_id
        JOIN units un ON un.id=r.unit_id
        WHERE ($filter)
        ORDER BY (r.visit_date=CURDATE()) DESC, r.visit_date DESC, r.id DESC LIMIT 100");
    $stmt->execute($params);
    $doctorPatients=$stmt->fetchAll();
}
$assignedNurses=[];
if (is_doctor($user)) {
    $q=db()->prepare("SELECT e.full_name,e.employee_code FROM nurse_doctor_assignments nda JOIN employees e ON e.id=nda.nurse_employee_id WHERE nda.doctor_employee_id=? AND e.is_active=1 ORDER BY e.full_name");
    $q->execute([(int)$user['employee_id']]);$assignedNurses=$q->fetchAll();
}
$nursePatients=[];
if (is_nurse($user)) {
    $stmt=db()->prepare("SELECT r.registration_no,r.visit_date,r.status,p.full_name AS patient_name,p.medical_record_no,un.name unit_name, d.full_name doctor_name FROM registrations r JOIN patients p ON p.id=r.patient_id JOIN units un ON un.id=r.unit_id LEFT JOIN employees d ON d.id=r.doctor_employee_id WHERE ($filter) ORDER BY r.visit_date DESC,r.id DESC LIMIT 100");
    $stmt->execute($params);$nursePatients=$stmt->fetchAll();
}
require __DIR__ . '/includes/header.php';
?>
<h1 class="page-title">Dashboard</h1>
<p class="page-subtitle"><?= is_doctor($user) ? 'Ringkasan kunjungan dan daftar pasien sesuai penugasan DPJP.' : 'Ringkasan operasional SIMRS berdasarkan data yang tersimpan di MariaDB.' ?></p>
<div class="grid grid-4">
  <div class="card stat"><small><?= is_doctor($user) ? 'Pasien Saya' : 'Total Pasien' ?></small><b><?= $stats['patients'] ?></b></div>
  <div class="card stat"><small><?= is_doctor($user) ? 'Kunjungan Saya Hari Ini' : 'Kunjungan Hari Ini' ?></small><b><?= $stats['today'] ?></b></div>
  <div class="card stat"><small>Order Lab Aktif</small><b><?= $stats['lab_pending'] ?></b></div>
  <div class="card stat"><small>Pasien Rawat Inap</small><b><?= $stats['inpatient'] ?></b></div>
</div>

<?php if (is_doctor($user)): ?>
<div class="card" style="margin-top:18px">
  <h2 class="section-title">Daftar Pasien Saya — <?=e($user['full_name'])?></h2>
  <p class="note">Hanya kunjungan yang mencantumkan Anda sebagai dokter penanggung jawab. Kunjungan hari ini adalah jumlah kunjungan, bukan seluruh pasien rumah sakit.</p>
  <p class="note"><b>Perawat Poli yang ditugaskan:</b> <?php if($assignedNurses): ?><?=e(implode(', ',array_map(static fn($n)=>$n['full_name'].' ('.$n['employee_code'].')',$assignedNurses)))?><?php else: ?>Belum ada perawat yang ditugaskan.<?php endif; ?></p>
  <div class="table-wrap" style="margin-top:12px"><table>
    <thead><tr><th>No. Registrasi</th><th>Pasien / No. RM</th><th>Unit</th><th>Tanggal</th><th>Antrian</th><th>Status</th><th>Tindakan</th></tr></thead>
    <tbody>
    <?php if (!$doctorPatients): ?><tr><td colspan="7" style="text-align:center;padding:20px;color:#667085">Belum ada pasien yang didaftarkan kepada dokter ini. Periksa penugasan dokter pada data registrasi.</td></tr><?php endif; ?>
    <?php foreach ($doctorPatients as $patient): ?>
      <tr>
        <td><b><?=e($patient['registration_no'])?></b></td>
        <td><?=e($patient['patient_name'])?><br><small><?=e($patient['medical_record_no'])?></small></td>
        <td><?=e($patient['unit_name'])?></td><td><?=e($patient['visit_date'])?></td>
        <td><?=e($patient['queue_no'] ?: '-')?></td>
        <td><span class="badge <?=status_badge_class($patient['status'])?>"><?=e($patient['status'])?></span></td>
        <td><a class="btn btn-secondary" href="emr.php">Buka EMR</a></td>
      </tr>
    <?php endforeach; ?>
    </tbody></table></div>
</div>
<?php endif; ?>
<?php if (is_nurse($user)): ?>
<div class="card" style="margin-top:18px"><h2 class="section-title">Daftar Pasien dalam Tanggung Jawab Saya</h2>
<p class="note">Pasien poli dibatasi menurut dokter yang dipasangkan; IGD hanya kunjungan IGD aktif; rawat inap hanya pasien berstatus Dirawat.</p>
<div class="table-wrap"><table><thead><tr><th>Registrasi</th><th>Pasien</th><th>Dokter</th><th>Unit</th><th>Tanggal</th><th>Status</th></tr></thead><tbody>
<?php foreach($nursePatients as $r): ?><tr><td><?=e($r['registration_no'])?></td><td><?=e($r['patient_name'])?><br><small><?=e($r['medical_record_no'])?></small></td><td><?=e($r['doctor_name']??'-')?></td><td><?=e($r['unit_name'])?></td><td><?=e($r['visit_date'])?></td><td><?=e($r['status'])?></td></tr><?php endforeach; ?>
<?php if(!$nursePatients): ?><tr><td colspan="6">Tidak ada pasien yang sedang berada dalam cakupan akses akun ini.</td></tr><?php endif; ?>
</tbody></table></div></div>
<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
