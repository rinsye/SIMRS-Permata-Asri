-- SIMRS pembagian profesi & cakupan pasien — jalankan SETELAH migration_data_driven_2026.sql
-- Migrasi idempoten dan tidak membuat password. Lengkapi akun dari Pendaftaran Pengguna.
USE simrs_permata_asri;
INSERT IGNORE INTO roles(code,name) VALUES
 ('dokter_umum','Dokter Umum'),('dokter_igd','Dokter IGD');
-- Dokter poli umum yang sudah ada tetap terhubung ke pegawai dan user yang sama.
UPDATE employees e JOIN roles r ON r.code='dokter_umum' JOIN units u ON u.id=e.unit_id
SET e.role_id=r.id WHERE e.employee_code IN ('PEG-DOK-001','PEG-DOK-003') AND u.code='PU';
-- Pegawai IGD DEMO untuk instalasi pengujian saja; ganti identitas sebelum penggunaan nyata.
INSERT INTO employees(employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-IGD-001','Dokter IGD (DEMO)','Dokter IGD',r.id,u.id,1
FROM roles r JOIN units u ON u.unit_type='IGD' AND u.code='IGD'
WHERE r.code='dokter_igd' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-IGD-001');
-- Jadwal IGD khusus DEMO; administrator mengganti jadwal sebenarnya pada sistem nyata.
INSERT INTO doctor_schedules(employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Rabu','08:00:00','16:00:00' FROM employees e JOIN units u ON u.id=e.unit_id
WHERE e.employee_code='PEG-DOK-IGD-001' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id);

-- Satu pegawai perawat DEMO per dokter poli, dibuat hanya satu kali melalui SQL.
INSERT INTO employees(employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')),
       CONCAT('Perawat Poli ',d.employee_code,' (DEMO)'),
       'Perawat Poli',rp.id,d.unit_id,1
FROM employees d JOIN roles rd ON rd.id=d.role_id AND rd.code IN ('dokter','dokter_umum')
JOIN units ud ON ud.id=d.unit_id AND ud.unit_type='POLI'
JOIN roles rp ON rp.code='perawat'
WHERE NOT EXISTS (SELECT 1 FROM employees px WHERE px.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')));
-- Ganti relasi perawat poli dengan perawat khusus masing-masing DPJP.
DELETE nda FROM nurse_doctor_assignments nda
JOIN employees n ON n.id=nda.nurse_employee_id
JOIN units u ON u.id=n.unit_id AND u.unit_type='POLI';
INSERT IGNORE INTO nurse_doctor_assignments(nurse_employee_id,doctor_employee_id)
SELECT n.id,d.id FROM employees d
JOIN roles dr ON dr.id=d.role_id AND dr.code IN ('dokter','dokter_umum')
JOIN units du ON du.id=d.unit_id AND du.unit_type='POLI'
JOIN employees n ON n.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0'));
-- Permission mengikuti tabel, tidak di-hardcode per pegawai.
INSERT IGNORE INTO role_permissions(role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code IN ('dashboard.view','emr.manage','cpoe.manage')
WHERE r.code IN ('dokter_umum','dokter_igd');
INSERT IGNORE INTO role_permissions(role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='dashboard.view' WHERE r.code IN ('perawat','igd','farmasi');
-- Akun DEMO disisipkan sekali ke database, bukan dibuat otomatis saat login.
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_maya','$2y$12$cDV9tCI7a4q72WlPQgZp4eulFtYkQ2zQ2JgiP6cfXx9cGpqrSCAde',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-002' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_maya');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_raka','$2y$12$/C9ixVnFB1cyDPA2GbB23OHUz7CoIE4LES1LmLFomJ4SiLHybm5Pu',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-003' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_raka');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_nadia','$2y$12$f9bFVxLyNfiSkeH8a01xxebfMUF7eOPCyDVIRDRY8RJxEr8kFzsey',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-004' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_nadia');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_salsabila','$2y$12$vznhdLlCiYNwDcHIpOx/YuVJnOOshhMXrqGPkaogHmDp/.rX6IMTu',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-005' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_salsabila');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_bima','$2y$12$YXwTzU.nI9.GnKhvIy4fC.SfiScVDO7sfz1g1ncN2Tv2buQdg9b8y',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-006' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_bima');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_citra','$2y$12$fAkiO2heGJc337wKQsxKvuOg4Q.9vhFPx0Q5BYgI9ghmemGlNTOSe',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-007' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_citra');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'dokter_igd','$2y$12$Xt6XTUNROBid2kpwy2syQudJ9uNEcwwEQYXwkU.ufTxxJN0sgGCQ2',1 FROM roles r JOIN employees e ON e.employee_code='PEG-DOK-IGD-001' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='dokter_igd');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'farmasi_nadia','$2y$12$EFaIaDSf90eCa3SZXj9zeu6Q4K86ij3i50lp616Tq39YS/VeMiaqy',1 FROM roles r JOIN employees e ON e.employee_code='PEG-FAR-001' WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='farmasi_nadia');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_1','$2y$12$VZ536TJwtM4w.Sed6//K5e5.ykEu5vEukVuZKrIEYf8oEidp2AMWq',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-001' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_1');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_2','$2y$12$VMDF6feqmDdI8VcY.dnEv.mV0cq72iN/dayiv9TO1Y5DAZ7pHR.r.',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-002' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_2');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_3','$2y$12$R7oXEENIKLOWGozuHzohR.sAT1zumBkxs0EtZm.K1yzgIjYvuqvNW',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-003' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_3');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_4','$2y$12$eW2rNxxBKvBm8fiG0R2RguvX0xAKDKYBtIVwiZiIlyE78/JTIzQHu',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-004' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_4');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_5','$2y$12$rHoQHOf4nYbYD8WW5P/RXeRupJ3brXZK7Xz1yjAf/5dCKV9QuZU8y',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-005' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_5');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_6','$2y$12$gS4iHG6d3GAHM4QItv1oIOQpDqAJ7iAiJeTL1UXnGYcocaboRs//O',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-006' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_6');
INSERT INTO users(employee_id,username,password_hash,is_active) SELECT e.id,'nurse_poli_7','$2y$12$QPZFjnS1aUnotCKtp5Ka1uXl3SAP6U0mcd2RQC180uJbgs9Fi.v8a',1 FROM roles r JOIN employees d ON d.employee_code='PEG-DOK-007' JOIN employees e ON e.employee_code=CONCAT('PEG-PRW-P-',LPAD(d.id,4,'0')) WHERE r.code='admin_simrs' AND e.is_active=1 AND NOT EXISTS(SELECT 1 FROM users u WHERE u.employee_id=e.id OR u.username='nurse_poli_7');
-- Audit pegawai dan user dibuat/ditugaskan melalui database.
SELECT e.employee_code,e.full_name,r.name AS role,un.name AS unit,e.is_active,
  (SELECT COUNT(*) FROM users us WHERE us.employee_id=e.id) AS jumlah_akun
FROM employees e JOIN roles r ON r.id=e.role_id LEFT JOIN units un ON un.id=e.unit_id
WHERE r.code IN ('dokter','dokter_umum','dokter_igd','perawat','igd','farmasi')
ORDER BY r.name,un.name,e.employee_code;
