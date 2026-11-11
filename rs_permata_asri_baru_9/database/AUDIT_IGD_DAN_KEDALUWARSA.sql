-- Pilih database SIMRS yang digunakan aplikasi sebelum menjalankan.
-- Pemeriksaan akun dokter dan perawat IGD beserta unitnya.
SELECT u.username, e.employee_code, e.full_name, ro.code AS role_code, un.name AS unit, un.unit_type
FROM users u JOIN employees e ON e.id=u.employee_id
JOIN roles ro ON ro.id=e.role_id LEFT JOIN units un ON un.id=e.unit_id
WHERE u.username IN ('dokter_igd','triage');

-- Pasien IGD aktif yang dapat dilihat perawat IGD (berdasarkan unit dan status kunjungan).
SELECT r.registration_no, p.full_name AS pasien, r.status, ud.name AS unit,
       d.full_name AS dokter_penanggung_jawab
FROM registrations r JOIN patients p ON p.id=r.patient_id
JOIN units ud ON ud.id=r.unit_id
LEFT JOIN employees d ON d.id=r.doctor_employee_id
WHERE ud.unit_type='IGD' AND r.status NOT IN ('Selesai','Dibatalkan','Batal','Ditolak','Pulang','Closed','Completed')
ORDER BY r.id DESC;

-- Obat dengan tanggal kadaluwarsa yang belum tercatat (NULL).
SELECT item_code,item_name,unit,stock,expiry_date FROM pharmacy_items
WHERE expiry_date IS NULL ORDER BY item_name;

-- Tanggal kadaluwarsa diisi dengan tanggal yang TERTERA PADA KEMASAN,
-- bukan tanggal contoh. Contoh sintaks, jangan dijalankan tanpa mengganti nilai sesuai stok nyata:
-- UPDATE pharmacy_items SET expiry_date = 'YYYY-MM-DD' WHERE item_code = 'KODE_OBAT';
