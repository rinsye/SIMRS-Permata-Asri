<?php
require_once __DIR__ . '/includes/functions.php';
$user=require_login(); require_permission($user,'roles.manage'); require_admin($user);
$pageTitle='Manajemen Role & Izin'; $pdo=db();
$restricted=['reporting.view','users.manage','employees.manage','roles.manage'];
if ($_SERVER['REQUEST_METHOD']==='POST') {
    check_csrf(); $action=(string)($_POST['action']??'');
    try {
        if ($action==='save_permissions') {
            $roleId=(int)($_POST['role_id']??0);
            $q=$pdo->prepare('SELECT code FROM roles WHERE id=?'); $q->execute([$roleId]); $roleCode=$q->fetchColumn();
            if (!$roleCode || $roleCode==='admin_simrs') throw new RuntimeException('Role admin tidak dapat diubah melalui formulir ini.');
            $ids=array_values(array_unique(array_map('intval',(array)($_POST['permission_ids']??[]))));
            $allowed=$pdo->query('SELECT id,code FROM permissions')->fetchAll(PDO::FETCH_KEY_PAIR);
            foreach ($ids as $id) {
                if (!isset($allowed[$id]) || in_array($allowed[$id],$restricted,true)) throw new RuntimeException('Izin khusus admin tidak boleh diberikan kepada role lain.');
            }
            $pdo->beginTransaction();
            $pdo->prepare('DELETE FROM role_permissions WHERE role_id=?')->execute([$roleId]);
            $q=$pdo->prepare('INSERT INTO role_permissions(role_id,permission_id) VALUES (?,?)');
            foreach ($ids as $id) $q->execute([$roleId,$id]);
            $pdo->prepare('INSERT INTO permission_audit(actor_user_id,action,subject,details) VALUES (?,?,?,?)')->execute([$user['user_id'],'Ubah izin', $roleCode,implode(',',$ids)]);
            $pdo->commit(); flash('success','Hak akses role berhasil diperbarui.');
        } elseif ($action==='assign_nurse') {
            $nurse=(int)($_POST['nurse_id']??0); $doctor=(int)($_POST['doctor_id']??0);
            $q=$pdo->prepare("SELECT COUNT(*) FROM employees e JOIN roles r ON r.id=e.role_id JOIN units u ON u.id=e.unit_id WHERE e.id=? AND r.code='perawat' AND u.unit_type='POLI'"); $q->execute([$nurse]);
            if (!$q->fetchColumn()) throw new RuntimeException('Pilih perawat poli yang valid.');
            $q=$pdo->prepare("SELECT COUNT(*) FROM employees e JOIN roles r ON r.id=e.role_id WHERE e.id=? AND r.code IN ('dokter','dokter_umum') AND e.unit_id=(SELECT unit_id FROM employees WHERE id=?)"); $q->execute([$doctor,$nurse]);
            if (!$q->fetchColumn()) throw new RuntimeException('Dokter harus berada pada poli yang sama.');
            // Satu perawat poli hanya boleh memiliki satu DPJP aktif.
            $q=$pdo->prepare('SELECT doctor_employee_id FROM nurse_doctor_assignments WHERE nurse_employee_id=? AND doctor_employee_id<>? LIMIT 1');
            $q->execute([$nurse,$doctor]);
            if ($q->fetchColumn()) throw new RuntimeException('Perawat ini sudah ditugaskan ke dokter lain. Hapus penugasan lama terlebih dahulu.');
            $pdo->prepare('INSERT IGNORE INTO nurse_doctor_assignments(nurse_employee_id,doctor_employee_id) VALUES (?,?)')->execute([$nurse,$doctor]);
            $pdo->prepare('INSERT INTO permission_audit(actor_user_id,action,subject,details) VALUES (?,?,?,?)')->execute([$user['user_id'],'Penugasan perawat',(string)$nurse,(string)$doctor]);
            flash('success','Perawat berhasil ditugaskan ke dokter poli.');
        } elseif ($action==='remove_nurse') {
            $nurse=(int)($_POST['nurse_id']??0); $doctor=(int)($_POST['doctor_id']??0);
            $pdo->prepare('DELETE FROM nurse_doctor_assignments WHERE nurse_employee_id=? AND doctor_employee_id=?')->execute([$nurse,$doctor]);
            $pdo->prepare('INSERT INTO permission_audit(actor_user_id,action,subject,details) VALUES (?,?,?,?)')->execute([$user['user_id'],'Hapus penugasan perawat',(string)$nurse,(string)$doctor]);
            flash('success','Penugasan dihapus.');
        } elseif ($action==='referral') {
            $patient=(int)($_POST['patient_id']??0); $doctor=(int)($_POST['doctor_id']??0);
            $reason=trim((string)($_POST['reason']??''));
            $q=$pdo->prepare("SELECT COUNT(*) FROM employees e JOIN roles r ON r.id=e.role_id WHERE e.id=? AND r.code IN ('dokter','dokter_umum')");$q->execute([$doctor]);
            if (!$q->fetchColumn() || !$patient || $reason==='') throw new RuntimeException('Pasien, dokter, dan alasan rujukan wajib diisi.');
            $pdo->prepare('INSERT INTO patient_referrals(patient_id,to_doctor_id,reason,created_by) VALUES (?,?,?,?)')->execute([$patient,$doctor,$reason,$user['user_id']]);
            $pdo->prepare('INSERT INTO permission_audit(actor_user_id,action,subject,details) VALUES (?,?,?,?)')->execute([$user['user_id'],'Rujukan pasien',(string)$patient,'Dokter: '.$doctor.'; '.$reason]);
            flash('success','Rujukan berhasil dicatat.');
        } elseif ($action==='revoke_referral') {
            $id=(int)($_POST['referral_id']??0);
            $pdo->prepare('UPDATE patient_referrals SET is_active=0 WHERE id=?')->execute([$id]);
            $pdo->prepare('INSERT INTO permission_audit(actor_user_id,action,subject,details) VALUES (?,?,?,?)')->execute([$user['user_id'],'Cabut rujukan',(string)$id,'']);
            flash('success','Rujukan dicabut.');
        }
    } catch(Throwable $e) {
        if($pdo->inTransaction()) $pdo->rollBack();
        flash('error', $e instanceof RuntimeException?$e->getMessage():'Perubahan gagal disimpan.');
    }
    redirect('role_management.php');
}
$roles=$pdo->query('SELECT id,code,name FROM roles ORDER BY id')->fetchAll();
$permissions=$pdo->query('SELECT id,code,name FROM permissions ORDER BY code')->fetchAll();
$assigned=$pdo->query('SELECT role_id,permission_id FROM role_permissions')->fetchAll();
$matrix=[];foreach($assigned as $r)$matrix[(int)$r['role_id']][(int)$r['permission_id']]=true;
$nurses=$pdo->query("SELECT e.id,e.full_name,un.name unit_name FROM employees e JOIN roles ro ON ro.id=e.role_id JOIN units un ON un.id=e.unit_id WHERE ro.code='perawat' AND un.unit_type='POLI' ORDER BY e.full_name")->fetchAll();
$doctors=$pdo->query("SELECT e.id,e.full_name,un.name unit_name FROM employees e JOIN roles ro ON ro.id=e.role_id LEFT JOIN units un ON un.id=e.unit_id WHERE ro.code IN ('dokter','dokter_umum','dokter_igd') ORDER BY e.full_name")->fetchAll();
$patients=$pdo->query('SELECT id,medical_record_no,full_name FROM patients ORDER BY id DESC LIMIT 200')->fetchAll();
$links=$pdo->query('SELECT nda.*,n.full_name nurse_name,d.full_name doctor_name FROM nurse_doctor_assignments nda JOIN employees n ON n.id=nda.nurse_employee_id JOIN employees d ON d.id=nda.doctor_employee_id ORDER BY n.full_name')->fetchAll();
$referrals=$pdo->query('SELECT pr.*,p.full_name patient_name,d.full_name doctor_name FROM patient_referrals pr JOIN patients p ON p.id=pr.patient_id JOIN employees d ON d.id=pr.to_doctor_id WHERE pr.is_active=1 ORDER BY pr.id DESC LIMIT 50')->fetchAll();
require __DIR__.'/includes/header.php';
?>
<h1 class="page-title">Manajemen Role & Izin Akses</h1>
<p class="page-subtitle">Akses administrasi bersifat tetap khusus admin. Hak lihat rekam medis tetap dibatasi berdasarkan penugasan pasien dan unit, walaupun izin menu diaktifkan.</p>
<div class="grid grid-2">
<?php foreach($roles as $role): ?>
<div class="card"><h2 class="section-title"><?=e($role['name'])?></h2>
<?php if($role['code']==='admin_simrs'): ?><p class="note">Administrator memiliki semua hak akses. Izin inti tidak dapat dilepas dari halaman ini.</p><?php else: ?>
<form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="action" value="save_permissions"><input type="hidden" name="role_id" value="<?=$role['id']?>">
<div class="permission-grid"><?php foreach($permissions as $perm): ?>
<label class="permission-option"><input type="checkbox" name="permission_ids[]" value="<?=$perm['id']?>" <?=isset($matrix[$role['id']][$perm['id']])?'checked':''?> <?=in_array($perm['code'],$restricted,true)?'disabled':''?>> <span><?=e($perm['name'])?><small><?=e($perm['code'])?></small></span></label>
<?php endforeach;?></div><button class="btn btn-primary" type="submit">Simpan Izin</button></form><?php endif;?></div>
<?php endforeach;?></div>
<div class="grid grid-2" style="margin-top:20px">
<div class="card"><h2 class="section-title">Penugasan Perawat Poli</h2><p class="note">Perawat poli hanya dapat melihat pasien aktif dari dokter yang ditugaskan kepadanya.</p>
<form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="action" value="assign_nurse">
<div class="field"><label>Perawat</label><select class="input" name="nurse_id" required><option value="">Pilih perawat poli</option><?php foreach($nurses as $n):?><option value="<?=$n['id']?>"><?=e($n['full_name'].' — '.$n['unit_name'])?></option><?php endforeach;?></select></div>
<div class="field"><label>Dokter</label><select class="input" name="doctor_id" required><option value="">Pilih dokter</option><?php foreach($doctors as $d):?><option value="<?=$d['id']?>"><?=e($d['full_name'].' — '.$d['unit_name'])?></option><?php endforeach;?></select></div><button class="btn btn-primary">Tambahkan Penugasan</button></form>
<?php foreach($links as $link):?><form method="post" class="management-line"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="action" value="remove_nurse"><input type="hidden" name="nurse_id" value="<?=$link['nurse_employee_id']?>"><input type="hidden" name="doctor_id" value="<?=$link['doctor_employee_id']?>"><span><?=e($link['nurse_name'].' → '.$link['doctor_name'])?></span><button class="btn btn-secondary" type="submit">Hapus</button></form><?php endforeach;?></div>
<div class="card"><h2 class="section-title">Rujukan Antar Dokter</h2><p class="note">Rujukan aktif memberikan dokter penerima akses ke rekam medis pasien terkait. Pencabutan rujukan menghentikan akses melalui rujukan tersebut.</p>
<form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="action" value="referral">
<div class="field"><label>Pasien</label><select class="input" name="patient_id" required><option value="">Pilih pasien</option><?php foreach($patients as $pt):?><option value="<?=$pt['id']?>"><?=e($pt['medical_record_no'].' — '.$pt['full_name'])?></option><?php endforeach;?></select></div>
<div class="field"><label>Dokter Penerima</label><select class="input" name="doctor_id" required><option value="">Pilih dokter</option><?php foreach($doctors as $d):?><option value="<?=$d['id']?>"><?=e($d['full_name'])?></option><?php endforeach;?></select></div>
<div class="field"><label>Alasan Rujukan</label><input class="input" name="reason" maxlength="255" required></div><button class="btn btn-primary">Catat Rujukan</button></form>
<?php foreach($referrals as $ref):?><form method="post" class="management-line"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><input type="hidden" name="action" value="revoke_referral"><input type="hidden" name="referral_id" value="<?=$ref['id']?>"><span><?=e($ref['patient_name'].' → '.$ref['doctor_name'])?></span><button class="btn btn-secondary">Cabut</button></form><?php endforeach;?></div>
</div>
<?php require __DIR__.'/includes/footer.php'; ?>
