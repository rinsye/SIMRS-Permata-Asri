-- Jalankan per SELECT di phpMyAdmin setelah migrasi.
USE `simrs_permata_asri`;
-- 1. Daftar dokter dan unit dari database
SELECT e.id,e.employee_code,e.full_name,u.name AS unit_name
FROM employees e JOIN roles ro ON ro.id=e.role_id LEFT JOIN units u ON u.id=e.unit_id
WHERE ro.code='dokter' ORDER BY e.id;
-- 2. Perawat yang terhubung dengan dokter: hanya relasi yang ada di database
SELECT n.employee_code AS nurse_code,n.full_name AS nurse_name,
       d.employee_code AS doctor_code,d.full_name AS doctor_name
FROM nurse_doctor_assignments nda
JOIN employees n ON n.id=nda.nurse_employee_id
JOIN employees d ON d.id=nda.doctor_employee_id ORDER BY n.employee_code;
-- 3. Daftar pasien berikut DPJP berdasarkan registrasi, bukan data PHP
SELECT r.registration_no,p.medical_record_no,p.full_name,e.full_name AS dpjp,u.name AS unit_name,r.status
FROM registrations r JOIN patients p ON p.id=r.patient_id
JOIN employees e ON e.id=r.doctor_employee_id
JOIN units u ON u.id=r.unit_id ORDER BY r.id DESC;
-- 4. Unit IGD & admisi rawat inap, dengan status kunjungan aktual
SELECT r.registration_no,u.unit_type,r.status AS visit_status,
       ia.status AS inpatient_status,ia.room,ia.bed
FROM registrations r JOIN units u ON u.id=r.unit_id
LEFT JOIN inpatient_admissions ia ON ia.registration_id=r.id
WHERE u.unit_type='IGD' OR ia.id IS NOT NULL ORDER BY r.id DESC;
-- 5. Master farmasi: harga/stok/tanggal kedaluwarsa dari SQL
SELECT item_code,item_name,category,unit,stock,minimum_stock,price,expiry_date
FROM pharmacy_items ORDER BY item_code;
-- 6. Master tempat tidur yang dapat diedit di SQL
SELECT room,bed_code,room_class,is_active FROM hospital_beds ORDER BY room,bed_code;
-- 7. Master laboratorium dan parameter rujukan
SELECT p.panel_code,p.panel_name,k.keyword,x.parameter_name,x.result_unit,x.reference_range
FROM lab_test_panels p LEFT JOIN lab_panel_keywords k ON k.panel_id=p.id
LEFT JOIN lab_panel_parameters x ON x.panel_id=p.id ORDER BY p.panel_code,x.sort_order;
-- 8. Audit tabel hak akses
SELECT r.code AS role_code,p.code AS permission_code
FROM role_permissions rp JOIN roles r ON r.id=rp.role_id
JOIN permissions p ON p.id=rp.permission_id ORDER BY r.code,p.code;
