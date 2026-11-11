<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/schema_updates.php';
require_once __DIR__ . '/schema_v5.php';

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

function e(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function status_label(?string $status): string
{
    $value = strtolower(trim($status ?? ''));
    if (in_array($value, ['selesai','completed','tervalidasi','verified','closed','done'], true)) {
        return 'Selesai';
    }
    if (in_array($value, ['menunggu','ordered','pending','menunggu verifikasi','waiting','queued'], true)) {
        return 'Menunggu';
    }
    if (in_array($value, ['in process','in-process','processing','dalam proses','on process','ongoing'], true)) {
        return 'Dalam Proses';
    }
    return $status ?? '-';
}

function status_badge_class(?string $status): string
{
    $value = strtolower(trim($status ?? ''));
    if (in_array($value, ['selesai','completed','tervalidasi','verified','closed','done'], true)) {
        return 'badge-green';
    }
    if (in_array($value, ['menunggu','ordered','pending','menunggu verifikasi','waiting','queued'], true)) {
        return 'badge-blue';
    }
    if (in_array($value, ['in process','in-process','processing','dalam proses','on process','ongoing'], true)) {
        return 'badge-yellow';
    }
    return 'badge-blue';
}

function redirect(string $path): never
{
    header('Location: ' . $path);
    exit;
}

function current_user(): ?array
{
    ensure_progress03_schema(db());
    ensure_v5_schema(db());
    if (empty($_SESSION['user_id'])) {
        return null;
    }

    $stmt = db()->prepare(
        'SELECT u.id AS user_id, u.username, e.id AS employee_id, e.employee_code,
                e.full_name, e.profession, r.id AS role_id, r.code AS role_code,
                r.name AS role_name, un.name AS unit_name, e.unit_id
         FROM users u
         JOIN employees e ON e.id = u.employee_id
         JOIN roles r ON r.id = e.role_id
         LEFT JOIN units un ON un.id = e.unit_id
         WHERE u.id = ? AND u.is_active = 1
         LIMIT 1'
    );
    $stmt->execute([$_SESSION['user_id']]);
    $user = $stmt->fetch();

    return $user ?: null;
}

function require_login(): array
{
    $user = current_user();
    if (!$user) {
        redirect('login.php');
    }
    return $user;
}

function user_has_permission(int $roleId, string $permissionCode): bool
{
    $stmt = db()->prepare(
        'SELECT 1
         FROM role_permissions rp
         JOIN permissions p ON p.id = rp.permission_id
         WHERE rp.role_id = ? AND p.code = ?
         LIMIT 1'
    );
    $stmt->execute([$roleId, $permissionCode]);
    return (bool) $stmt->fetchColumn();
}

function require_permission(array $user, string $permissionCode): void
{
    if ($permissionCode === 'emr.archive' && !in_array($user['role_code'],['admin_simrs','rekammedis'],true)) {http_response_code(403);exit('403 - Akses arsip dibatasi.');}
    $fixed=['lab.manage'=>['lab','admin_simrs'],'radiology.manage'=>['radiologi','admin_simrs'],'farmasi.manage'=>['farmasi','admin_simrs'],'emr.manage'=>['dokter','dokter_umum','dokter_igd','perawat','igd','rekammedis','admin_simrs'],'cpoe.manage'=>['dokter','dokter_umum','dokter_igd','admin_simrs'],'triage.manage'=>['igd','admin_simrs'],'nursing.manage'=>['perawat','igd'],'registration.manage'=>['admisi','admin_simrs']];
    if(isset($fixed[$permissionCode]) && !in_array($user['role_code'],$fixed[$permissionCode],true)){http_response_code(403);exit('403 - Tidak sesuai peran.');}
    if (in_array($permissionCode, ['reporting.view','users.manage','employees.manage','roles.manage'], true) && !is_admin($user)) { http_response_code(403); exit('403 — Khusus administrator.'); }
    if ($permissionCode === 'inpatient.manage' && is_doctor($user)) {
        $q=db()->prepare('SELECT unit_type FROM units WHERE id=?'); $q->execute([(int)($user['unit_id']??0)]);
        if ($q->fetchColumn() === 'POLI') { http_response_code(403); exit('403 — Dokter poli tidak memiliki akses rawat inap.'); }
    }
    if (!user_has_permission((int) $user['role_id'], $permissionCode)) {
        http_response_code(403);
        echo '<h2 style="font-family:Arial">403 — Akses ditolak</h2><p>Role Anda tidak memiliki akses ke halaman ini.</p>';
        exit;
    }
}


function sidebar_menus(int $roleId): array
{
    $stmt = db()->prepare(
        'SELECT DISTINCT m.id, m.label, m.icon, m.section_name, m.page_file, m.sort_order
         FROM menus m
         JOIN permissions p ON p.code = m.permission_code
         JOIN role_permissions rp ON rp.permission_id = p.id
         WHERE rp.role_id = ? AND m.is_active = 1
         ORDER BY m.sort_order, m.id'
    );

    $stmt->execute([$roleId]);
    $result=$stmt->fetchAll();
    $user=current_user();
    return array_values(array_filter($result, static function($m) use ($user) {
        $restricted=['user_registration.php','employees.php','role_management.php','reporting.php'];
        if (in_array($m['page_file'],$restricted,true) && !is_admin($user)) return false;
        if ($m['page_file']==='inpatient.php' && in_array(($user['role_code']??''),['dokter','perawat'],true)) {
            $q=db()->prepare('SELECT unit_type FROM units WHERE id=?'); $q->execute([(int)($user['unit_id']??0)]);
            if ($q->fetchColumn()!=='RAWAT_INAP') return false;
        }
        return true;
    }));
}

function flash(string $key, ?string $value = null): ?string
{
    if ($value !== null) {
        $_SESSION['_flash'][$key] = $value;
        return null;
    }

    if (!isset($_SESSION['_flash'][$key])) {
        return null;
    }

    $message = $_SESSION['_flash'][$key];
    unset($_SESSION['_flash'][$key]);
    return $message;
}

function make_code(string $prefix, int $id, int $pad = 4): string
{
    return $prefix . '-' . str_pad((string) $id, $pad, '0', STR_PAD_LEFT);
}


/** Aturan klinis tidak dapat dilewati melalui izin menu yang diberikan admin. */
function is_admin(array $user): bool { return $user['role_code'] === 'admin_simrs'; }
function is_doctor(array $user): bool { return in_array($user['role_code'], ['dokter','dokter_umum','dokter_igd'], true); }
function is_nurse(array $user): bool { return in_array($user['role_code'], ['perawat','igd'], true); }
function deny_patient(): never { http_response_code(403); exit('403 — Anda tidak memiliki akses terhadap data pasien ini.'); }

/** Filter untuk tabel registrations dengan alias r. $mode: active, history, write. */
/**
 * Batas akses tingkat kunjungan, bukan sekadar tampilan menu.
 * Dokter hanya kunjungan yang ditugaskan kepadanya; tidak mewarisi kunjungan
 * dokter lain melalui pasien dengan nomor RM yang sama.
 * Perawat poli hanya kunjungan dokter yang dipasangkan secara eksplisit.
 * Perawat IGD hanya kunjungan IGD yang masih aktif.
 * Perawat rawat inap hanya admisi yang masih Dirawat.
 */
function patient_scope(array $user, string $mode = 'active'): array {
    if (is_admin($user) || $user['role_code'] === 'rekammedis') return ['1=1', []];
    $employee = (int)$user['employee_id'];
    if (is_doctor($user)) {
        if ($user['role_code']==='dokter_igd') return ["r.doctor_employee_id=? AND EXISTS (SELECT 1 FROM units ud WHERE ud.id=r.unit_id AND ud.unit_type='IGD')",[$employee]];
        return ['r.doctor_employee_id=? AND r.unit_id=?', [$employee,(int)$user['unit_id']]];
    }
    if (is_nurse($user)) {
        $active = "r.status NOT IN ('Selesai','Dibatalkan','Batal','Ditolak','Pulang','Closed','Completed')";
        $q=db()->prepare('SELECT unit_type FROM units WHERE id=?');
        $q->execute([(int)($user['unit_id']??0)]);
        $unitType=strtoupper((string)$q->fetchColumn());
        if ($user['role_code'] === 'igd' || $unitType === 'IGD') {
            return ["($active AND EXISTS (SELECT 1 FROM units ux WHERE ux.id=r.unit_id AND ux.unit_type='IGD'))", []];
        }
        if ($unitType === 'RAWAT_INAP') {
            return ["EXISTS (SELECT 1 FROM inpatient_admissions ia WHERE ia.registration_id=r.id AND ia.status='Dirawat')", []];
        }
        if ($unitType === 'POLI') {
            return ["($active AND r.unit_id=? AND EXISTS (SELECT 1 FROM nurse_doctor_assignments nda JOIN employees de ON de.id=nda.doctor_employee_id WHERE nda.nurse_employee_id=? AND nda.doctor_employee_id=r.doctor_employee_id AND de.unit_id=r.unit_id AND de.is_active=1))", [(int)$user['unit_id'],$employee]];
        }
    }
    return ['1=0', []];
}
function patient_registration_allowed(array $user, int $registrationId, string $mode='active'): bool {
    [$filter,$params]=patient_scope($user,$mode);
    $q=db()->prepare('SELECT 1 FROM registrations r WHERE r.id=? AND ('.$filter.') LIMIT 1');
    $q->execute(array_merge([$registrationId],$params));
    return (bool)$q->fetchColumn();
}
function require_patient_registration(array $user, int $registrationId, string $mode='active'): void {
    if (!$registrationId || !patient_registration_allowed($user,$registrationId,$mode)) deny_patient();
}
function require_admin(array $user): void { if (!is_admin($user)) deny_patient(); }
function csrf_token(): string {
    if (empty($_SESSION['csrf_token'])) $_SESSION['csrf_token']=bin2hex(random_bytes(32));
    return $_SESSION['csrf_token'];
}
function check_csrf(): void {
    if (!hash_equals(csrf_token(), (string)($_POST['csrf_token']??''))) { http_response_code(419); exit('Permintaan ditolak: token keamanan tidak valid.'); }
}
