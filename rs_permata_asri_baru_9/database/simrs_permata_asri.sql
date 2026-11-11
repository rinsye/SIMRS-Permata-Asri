-- RS Permata Asri SIMRS
-- XAMPP / MariaDB installer
-- File ini akan membuat ulang database simrs_permata_asri.

DROP DATABASE IF EXISTS simrs_permata_asri;
CREATE DATABASE IF NOT EXISTS simrs_permata_asri CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE simrs_permata_asri;

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS inpatient_admissions;
DROP TABLE IF EXISTS triage;
DROP TABLE IF EXISTS radiology_orders;
DROP TABLE IF EXISTS lab_orders;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS emr_staff;
DROP TABLE IF EXISTS emr;
DROP TABLE IF EXISTS registrations;
DROP TABLE IF EXISTS doctor_schedules;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS menus;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS units;
DROP TABLE IF EXISTS roles;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE units (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    unit_type VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_code VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    profession VARCHAR(100) NOT NULL,
    role_id INT NOT NULL,
    unit_id INT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_employee_role FOREIGN KEY (role_id) REFERENCES roles(id),
    CONSTRAINT fk_employee_unit FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL UNIQUE,
    username VARCHAR(60) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE menus (
    id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    icon VARCHAR(10) NOT NULL,
    section_name VARCHAR(50) NOT NULL,
    page_file VARCHAR(100) NOT NULL,
    permission_code VARCHAR(80) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    medical_record_no VARCHAR(30) NULL UNIQUE,
    nik VARCHAR(16) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    birth_date DATE NOT NULL,
    gender ENUM('L','P') NOT NULL,
    address TEXT NULL,
    phone VARCHAR(30) NULL,
    email VARCHAR(120) NULL,
    payer VARCHAR(40) NOT NULL DEFAULT 'Umum',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE doctor_schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    unit_id INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT fk_schedule_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_schedule_unit FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registration_no VARCHAR(40) NULL UNIQUE,
    patient_id INT NOT NULL,
    unit_id INT NOT NULL,
    doctor_employee_id INT NULL,
    schedule_id INT NULL,
    visit_date DATE NOT NULL,
    complaint TEXT NULL,
    payer VARCHAR(40) NOT NULL DEFAULT 'Umum',
    status VARCHAR(40) NOT NULL DEFAULT 'Menunggu',
    queue_no VARCHAR(20) NULL,
    created_by INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reg_patient FOREIGN KEY (patient_id) REFERENCES patients(id),
    CONSTRAINT fk_reg_unit FOREIGN KEY (unit_id) REFERENCES units(id),
    CONSTRAINT fk_reg_doctor FOREIGN KEY (doctor_employee_id) REFERENCES employees(id),
    CONSTRAINT fk_reg_schedule FOREIGN KEY (schedule_id) REFERENCES doctor_schedules(id),
    CONSTRAINT fk_reg_creator FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE patient_registration_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_no VARCHAR(40) NULL UNIQUE,
    nik VARCHAR(16) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    birth_date DATE NOT NULL,
    gender ENUM('L','P') NOT NULL,
    address TEXT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(120) NULL,
    payer VARCHAR(40) NOT NULL DEFAULT 'Umum',
    unit_id INT NOT NULL,
    doctor_employee_id INT NOT NULL,
    schedule_id INT NOT NULL,
    visit_date DATE NOT NULL,
    complaint TEXT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Menunggu Verifikasi',
    admin_note TEXT NULL,
    patient_id INT NULL,
    registration_id INT NULL,
    reviewed_by INT NULL,
    reviewed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prr_unit FOREIGN KEY (unit_id) REFERENCES units(id),
    CONSTRAINT fk_prr_doctor FOREIGN KEY (doctor_employee_id) REFERENCES employees(id),
    CONSTRAINT fk_prr_schedule FOREIGN KEY (schedule_id) REFERENCES doctor_schedules(id),
    CONSTRAINT fk_prr_patient FOREIGN KEY (patient_id) REFERENCES patients(id),
    CONSTRAINT fk_prr_registration FOREIGN KEY (registration_id) REFERENCES registrations(id),
    CONSTRAINT fk_prr_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE emr (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL UNIQUE,
    subjective TEXT NULL,
    objective TEXT NULL,
    assessment TEXT NULL,
    plan TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_emr_reg FOREIGN KEY (registration_id) REFERENCES registrations(id)
) ENGINE=InnoDB;

CREATE TABLE emr_staff (
    id INT AUTO_INCREMENT PRIMARY KEY,
    emr_id INT NOT NULL,
    employee_id INT NOT NULL,
    activity VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_emrstaff_emr FOREIGN KEY (emr_id) REFERENCES emr(id) ON DELETE CASCADE,
    CONSTRAINT fk_emrstaff_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(40) NULL UNIQUE,
    registration_id INT NOT NULL,
    ordering_employee_id INT NOT NULL,
    order_type ENUM('Laboratorium','Radiologi','Obat','Konsultasi','Rawat Inap') NOT NULL,
    detail VARCHAR(255) NOT NULL,
    clinical_indication TEXT NULL,
    priority ENUM('Rutin','CITO') NOT NULL DEFAULT 'Rutin',
    status VARCHAR(40) NOT NULL DEFAULT 'Ordered',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_reg FOREIGN KEY (registration_id) REFERENCES registrations(id),
    CONSTRAINT fk_order_employee FOREIGN KEY (ordering_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE lab_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    test_name VARCHAR(255) NOT NULL,
    specimen VARCHAR(100) NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Menunggu',
    result TEXT NULL,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    CONSTRAINT fk_lab_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_lab_verify FOREIGN KEY (verified_by) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE radiology_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    exam_name VARCHAR(255) NOT NULL,
    clinical_indication TEXT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Menunggu',
    result TEXT NULL,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    CONSTRAINT fk_rad_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_rad_verify FOREIGN KEY (verified_by) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE triage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    nurse_employee_id INT NOT NULL,
    urgency VARCHAR(20) NOT NULL,
    bp VARCHAR(20) NULL,
    hr VARCHAR(20) NULL,
    rr VARCHAR(20) NULL,
    temp VARCHAR(20) NULL,
    spo2 VARCHAR(20) NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_triage_reg FOREIGN KEY (registration_id) REFERENCES registrations(id),
    CONSTRAINT fk_triage_nurse FOREIGN KEY (nurse_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE inpatient_admissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    ordered_by INT NOT NULL,
    room VARCHAR(100) NOT NULL,
    bed VARCHAR(100) NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Dirawat',
    admitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inpatient_reg FOREIGN KEY (registration_id) REFERENCES registrations(id),
    CONSTRAINT fk_inpatient_employee FOREIGN KEY (ordered_by) REFERENCES employees(id)
) ENGINE=InnoDB;

INSERT INTO roles (id, code, name) VALUES
(1,'admin_simrs','Administrator SIMRS'),
(2,'dokter','Dokter / DPJP'),
(3,'perawat','Perawat / PPA'),
(4,'lab','Laboratorium / ATLM'),
(5,'radiologi','Radiografer'),
(6,'igd','Perawat IGD / Triage'),
(7,'admisi','Admisi / Pendaftaran'),
(8,'rekammedis','Petugas Rekam Medis');

INSERT INTO units (id,code,name,unit_type) VALUES
(1,'IT','Teknologi Informasi','ADMIN'),
(2,'PU','Poli Umum','POLI'),
(3,'PD','Poli Penyakit Dalam','POLI'),
(4,'PA','Poli Anak','POLI'),
(5,'IGD','Instalasi Gawat Darurat','IGD'),
(6,'LAB','Laboratorium','PENUNJANG'),
(7,'RAD','Radiologi','PENUNJANG'),
(8,'RI','Rawat Inap','RAWAT_INAP'),
(9,'RM','Rekam Medis','ADMIN'),
(10,'ADM','Admisi / Pendaftaran','ADMIN');

INSERT INTO employees (id,employee_code,full_name,profession,role_id,unit_id,is_active) VALUES
(1,'PEG-ADM-001','Novella','Administrator SIMRS',1,1,1),
(2,'PEG-DOK-001','dr. Andi Pratama','Dokter',2,2,1),
(3,'PEG-DOK-002','dr. Maya Kusuma, Sp.PD','Dokter Sp.PD',2,3,1),
(4,'PEG-PRW-001','Ns. Intan Permata, S.Kep','Perawat',3,8,1),
(5,'PEG-LAB-001','Dewi Lestari, A.Md.AK','ATLM',4,6,1),
(6,'PEG-RAD-001','Rizky Maulana, A.Md.Rad','Radiografer',5,7,1),
(7,'PEG-IGD-001','Ns. Rani Puspita, S.Kep','Perawat IGD',6,5,1),
(8,'PEG-ADM-002','Rika Andriani, A.Md.Kes','Petugas Admisi',7,10,1),
(9,'PEG-RM-001','Sinta Maharani, A.Md.RMIK','Perekam Medis',8,9,1);

INSERT INTO users (id,employee_id,username,password_hash,is_active) VALUES
(1,1,'novella','$2y$12$uQyklXfnl0fSsn907DFtOepclVtaJke1iHQZoMjFsNRrR1bdG3m2e',1),
(2,2,'dokter','$2y$12$peGWpz0zFKVmcQDrksyZueRX0YZVrTy816PBxH/n1vIg2VPfBZqda',1),
(3,4,'perawat','$2y$12$afRjQzrcKNoeVFZLL4LdnuO/LGlhVcomRUN/nk1lvdyUlib4FRtGm',1),
(4,5,'lab','$2y$12$arwZHtu2KytQwcGOF5Gb1urvfBdYWg3ynvfJfYmAmPBZPltjsSIjC',1),
(5,6,'radiologi','$2y$12$wJNCErZ5VzWWlOCZpklc1uxs28GLxvC5Au.lXjrwV.zPSCd9CIQgy',1),
(6,7,'triage','$2y$12$HDZo0Dn6Nzzteu1RX5PmO.ghkAg4l2YS6J97grihB5Onno9ehEckG',1),
(7,8,'admisi','$2y$12$tqgoCZsujyRJrQwgLSadTO3O/3A5Ons/1gE.Odq7b7M7YAUhtffMO',1),
(8,9,'rekammedis','$2y$12$d0dPj0dqTQyTmV2hZB.xWOdn/eGR9qiMwyZygBWk6HWyk3ES2PANe',1);

INSERT INTO permissions (id,code,name) VALUES
(1,'dashboard.view','Lihat Dashboard'),
(2,'users.manage','User Registration'),
(3,'employees.manage','Kelola Data Pegawai'),
(4,'registration.manage','Patient Registration'),
(5,'emr.manage','Kelola EMR'),
(6,'cpoe.manage','Kelola CPOE'),
(7,'lab.manage','Kelola Laboratory'),
(8,'radiology.manage','Kelola Radiology'),
(9,'triage.manage','Kelola Triage'),
(10,'inpatient.manage','Kelola Rawat Inap'),
(11,'reporting.view','Lihat Laporan Operasional'),
(12,'development.view','Lihat Modul Pengembangan'),
(13,'roles.manage','Kelola Role dan Izin Akses');

INSERT INTO permissions (code,name) VALUES ('farmasi.manage','Kelola Farmasi dan Inventory');

-- Administrator: semua permission
INSERT INTO role_permissions SELECT 1,id FROM permissions;
-- Dokter
INSERT INTO role_permissions (role_id,permission_id) VALUES (2,1),(2,5),(2,6);
-- Perawat
INSERT INTO role_permissions (role_id,permission_id) VALUES (3,1),(3,5),(3,10);
-- Laboratorium
INSERT INTO role_permissions (role_id,permission_id) VALUES (4,1),(4,7);
-- Radiologi
INSERT INTO role_permissions (role_id,permission_id) VALUES (5,1),(5,8);
-- IGD
INSERT INTO role_permissions (role_id,permission_id) VALUES (6,1),(6,9),(6,5);
-- Admisi
INSERT INTO role_permissions (role_id,permission_id) VALUES (7,1);
-- Rekam medis
INSERT INTO role_permissions (role_id,permission_id) VALUES (8,1);

INSERT INTO menus (label,icon,section_name,page_file,permission_code,sort_order) VALUES
('Dashboard','⌂','NAVIGASI','dashboard.php','dashboard.view',1),
('Pendaftaran Pengguna','♙','DATA MASTER','user_registration.php','users.manage',10),
('Data Pegawai','♟','DATA MASTER','employees.php','employees.manage',11),
('Registrasi Online','▦','TRANSAKSI','patient_registration_requests.php','registration.manage',19),
('Pendaftaran Pasien','▣','TRANSAKSI','patient_registration.php','registration.manage',20),
('Rekam Medis Elektronik','▣','PELAYANAN','emr.php','emr.manage',30),
('CPOE / Manajemen Instruksi','+','PELAYANAN','cpoe.php','cpoe.manage',31),
('Laboratorium','⌁','PELAYANAN','laboratory.php','lab.manage',32),
('Radiologi','◫','PELAYANAN','radiology.php','radiology.manage',33),
('IGD / Triase','✚','PELAYANAN','triage.php','triage.manage',34),
('Rawat Inap','▤','PELAYANAN','inpatient.php','inpatient.manage',35),
('Laporan Operasional','▧','LAPORAN','reporting.php','reporting.view',40),
('Farmasi & Persediaan','Rx','PELAYANAN','farmasi.php','farmasi.manage',36),
('Manajemen Role & Izin','⚙','DATA MASTER','role_management.php','roles.manage',12);

INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time) VALUES
(2,2,'Senin','08:00:00','12:00:00'),
(2,2,'Rabu','08:00:00','12:00:00'),
(3,3,'Selasa','09:00:00','13:00:00'),
(3,3,'Kamis','09:00:00','13:00:00');

INSERT INTO patients (id,medical_record_no,nik,full_name,birth_date,gender,address,phone,email,payer) VALUES
(1,'RM-2026-000001','3671010101900001','Budi Santoso','1990-01-01','L','Tangerang','081234567890','budi@example.com','Umum'),
(2,'RM-2026-000002','3671020202920002','Siti Aminah','1992-02-02','P','Tangerang','081298765432','siti@example.com','BPJS');

INSERT INTO registrations (id,registration_no,patient_id,unit_id,doctor_employee_id,schedule_id,visit_date,complaint,payer,status,queue_no,created_by,created_at) VALUES
(1,'REG-20261101-0001',1,2,2,1,CURDATE(),'Demam dan batuk','Umum','Menunggu','PU001',1,NOW()),
(2,'REG-20261101-0002',2,3,3,3,CURDATE(),'Kontrol hipertensi','BPJS','Menunggu','PD001',1,NOW()),
(3,'REG-20261101-0003',1,5,2,NULL,CURDATE(),'Sesak napas mendadak','Umum','Menunggu','IGD001',1,NOW());

INSERT INTO emr (id,registration_id,subjective,objective,assessment,plan,created_at,updated_at) VALUES
(1,1,'Demam 2 hari, batuk','T 38 C, HR 96 x/menit','Suspek ISPA','Pemeriksaan darah lengkap',NOW(),NOW());
INSERT INTO emr_staff (emr_id,employee_id,activity) VALUES
(1,2,'Anamnesis dan pemeriksaan fisik'),
(1,4,'Pengukuran tanda vital');

INSERT INTO orders (id,order_no,registration_id,ordering_employee_id,order_type,detail,clinical_indication,priority,status,created_at) VALUES
(1,'ORD-20261101-0001',1,2,'Laboratorium','Darah lengkap','Demam 2 hari','Rutin','Ordered',NOW()),
(2,'ORD-20261101-0002',1,2,'Radiologi','X-Ray Thorax PA','Batuk dan demam','Rutin','Ordered',NOW());
INSERT INTO lab_orders (order_id,test_name,status) VALUES (1,'Darah lengkap','Menunggu');
INSERT INTO radiology_orders (order_id,exam_name,clinical_indication,status) VALUES (2,'X-Ray Thorax PA','Batuk dan demam','Menunggu');



-- Tambahan data dokter/poli untuk registrasi pasien online
INSERT INTO units (code,name,unit_type)
SELECT 'PB','Poli Bedah','POLI' WHERE NOT EXISTS (SELECT 1 FROM units WHERE code='PB');
INSERT INTO units (code,name,unit_type)
SELECT 'PK','Poli Kandungan','POLI' WHERE NOT EXISTS (SELECT 1 FROM units WHERE code='PK');

INSERT INTO employees (employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-003','dr. Raka Mahendra','Dokter',r.id,u.id,1 FROM roles r, units u
WHERE r.code='dokter' AND u.code='PU' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-003');
INSERT INTO employees (employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-004','dr. Nadia Putri, Sp.PD','Dokter Sp.PD',r.id,u.id,1 FROM roles r, units u
WHERE r.code='dokter' AND u.code='PD' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-004');
INSERT INTO employees (employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-005','dr. Salsabila Rahman, Sp.A','Dokter Sp.A',r.id,u.id,1 FROM roles r, units u
WHERE r.code='dokter' AND u.code='PA' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-005');
INSERT INTO employees (employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-006','dr. Bima Aditya, Sp.B','Dokter Sp.B',r.id,u.id,1 FROM roles r, units u
WHERE r.code='dokter' AND u.code='PB' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-006');
INSERT INTO employees (employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-DOK-007','dr. Citra Maharani, Sp.OG','Dokter Sp.OG',r.id,u.id,1 FROM roles r, units u
WHERE r.code='dokter' AND u.code='PK' AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_code='PEG-DOK-007');

INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Selasa','08:00:00','12:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-003' AND u.code='PU' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Selasa' AND ds.start_time='08:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Jumat','08:00:00','11:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-003' AND u.code='PU' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Jumat' AND ds.start_time='08:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Senin','13:00:00','16:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-004' AND u.code='PD' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Senin' AND ds.start_time='13:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Jumat','09:00:00','12:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-004' AND u.code='PD' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Jumat' AND ds.start_time='09:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Senin','09:00:00','12:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-005' AND u.code='PA' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Senin' AND ds.start_time='09:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Kamis','13:00:00','16:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-005' AND u.code='PA' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Kamis' AND ds.start_time='13:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Selasa','13:00:00','16:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-006' AND u.code='PB' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Selasa' AND ds.start_time='13:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Jumat','13:00:00','16:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-006' AND u.code='PB' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Jumat' AND ds.start_time='13:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Rabu','09:00:00','12:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-007' AND u.code='PK' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Rabu' AND ds.start_time='09:00:00');
INSERT INTO doctor_schedules (employee_id,unit_id,day_name,start_time,end_time)
SELECT e.id,u.id,'Sabtu','08:00:00','11:00:00' FROM employees e, units u
WHERE e.employee_code='PEG-DOK-007' AND u.code='PK' AND NOT EXISTS (SELECT 1 FROM doctor_schedules ds WHERE ds.employee_id=e.id AND ds.unit_id=u.id AND ds.day_name='Sabtu' AND ds.start_time='08:00:00');

SELECT 'IMPORT_OK' AS status, DATABASE() AS database_name;
SHOW TABLES;



-- Master tambahan, jalankan setelah seluruh tabel/transaksi dasar tersedia.

CREATE TABLE IF NOT EXISTS patient_registration_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            request_no VARCHAR(40) NULL UNIQUE,
            nik VARCHAR(16) NOT NULL,
            full_name VARCHAR(150) NOT NULL,
            birth_date DATE NOT NULL,
            gender ENUM('L','P') NOT NULL,
            address TEXT NULL,
            phone VARCHAR(30) NOT NULL,
            email VARCHAR(120) NULL,
            payer VARCHAR(40) NOT NULL DEFAULT 'Umum',
            unit_id INT NOT NULL,
            doctor_employee_id INT NOT NULL,
            schedule_id INT NOT NULL,
            visit_date DATE NOT NULL,
            complaint TEXT NULL,
            status VARCHAR(40) NOT NULL DEFAULT 'Menunggu Verifikasi',
            admin_note TEXT NULL,
            patient_id INT NULL,
            registration_id INT NULL,
            reviewed_by INT NULL,
            reviewed_at DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_prr_status (status),
            INDEX idx_prr_visit_date (visit_date),
            CONSTRAINT fk_prr_unit FOREIGN KEY (unit_id) REFERENCES units(id),
            CONSTRAINT fk_prr_doctor FOREIGN KEY (doctor_employee_id) REFERENCES employees(id),
            CONSTRAINT fk_prr_schedule FOREIGN KEY (schedule_id) REFERENCES doctor_schedules(id),
            CONSTRAINT fk_prr_patient FOREIGN KEY (patient_id) REFERENCES patients(id),
            CONSTRAINT fk_prr_registration FOREIGN KEY (registration_id) REFERENCES registrations(id),
            CONSTRAINT fk_prr_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS patient_referrals (
      id INT AUTO_INCREMENT PRIMARY KEY, patient_id INT NOT NULL,
      from_doctor_id INT NULL, to_doctor_id INT NOT NULL, is_active TINYINT(1) NOT NULL DEFAULT 1,
      reason VARCHAR(255) NOT NULL, created_by INT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_referral_patient_doctor (patient_id,to_doctor_id,is_active),
      FOREIGN KEY (patient_id) REFERENCES patients(id), FOREIGN KEY (to_doctor_id) REFERENCES employees(id)
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS nurse_doctor_assignments (
      nurse_employee_id INT NOT NULL, doctor_employee_id INT NOT NULL,
      PRIMARY KEY(nurse_employee_id,doctor_employee_id),
      FOREIGN KEY(nurse_employee_id) REFERENCES employees(id),
      FOREIGN KEY(doctor_employee_id) REFERENCES employees(id)
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permission_audit (
      id INT AUTO_INCREMENT PRIMARY KEY, actor_user_id INT NOT NULL,
      action VARCHAR(60) NOT NULL, subject VARCHAR(120) NOT NULL,
      details TEXT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pharmacy_items (
        id INT AUTO_INCREMENT PRIMARY KEY, item_code VARCHAR(40) NOT NULL UNIQUE,
        item_name VARCHAR(160) NOT NULL, category VARCHAR(80) NOT NULL DEFAULT 'Obat',
        unit VARCHAR(30) NOT NULL DEFAULT 'tablet', stock INT NOT NULL DEFAULT 0,
        minimum_stock INT NOT NULL DEFAULT 10, price DECIMAL(12,2) NOT NULL DEFAULT 0,
        expiry_date DATE NULL, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pharmacy_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY, item_id INT NOT NULL,
        transaction_type ENUM('Masuk','Keluar') NOT NULL, quantity INT NOT NULL,
        note VARCHAR(255) NULL, employee_id INT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES pharmacy_items(id), FOREIGN KEY (employee_id) REFERENCES employees(id)
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS simrs_migration_flags (flag_key VARCHAR(100) PRIMARY KEY, applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS hospital_beds (id INT AUTO_INCREMENT PRIMARY KEY, room VARCHAR(70) NOT NULL, bed_code VARCHAR(40) NOT NULL, room_class VARCHAR(50) NOT NULL DEFAULT 'Kelas III', is_active TINYINT(1) NOT NULL DEFAULT 1, UNIQUE KEY uq_room_bed(room,bed_code)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS laboratory_values (id INT AUTO_INCREMENT PRIMARY KEY, lab_order_id INT NOT NULL, parameter_name VARCHAR(90) NOT NULL, result_value VARCHAR(100) NOT NULL, result_unit VARCHAR(35) NULL, reference_range VARCHAR(100) NULL, UNIQUE KEY uq_lab_parameter(lab_order_id,parameter_name), FOREIGN KEY(lab_order_id) REFERENCES lab_orders(id) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pharmacy_dispensing (id INT AUTO_INCREMENT PRIMARY KEY, order_id INT NOT NULL UNIQUE, status VARCHAR(30) NOT NULL DEFAULT 'Menunggu', started_by INT NULL, started_at DATETIME NULL, handed_over_by INT NULL, handed_over_at DATETIME NULL, FOREIGN KEY(order_id) REFERENCES orders(id)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pharmacy_dispensing_items (id INT AUTO_INCREMENT PRIMARY KEY, dispensing_id INT NOT NULL, item_name VARCHAR(255) NOT NULL, checked TINYINT(1) NOT NULL DEFAULT 0, UNIQUE KEY uq_dispense_name(dispensing_id,item_name), FOREIGN KEY(dispensing_id) REFERENCES pharmacy_dispensing(id) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS radiology_attachments (id INT AUTO_INCREMENT PRIMARY KEY, radiology_order_id INT NOT NULL, description VARCHAR(200) NOT NULL, stored_name VARCHAR(120) NOT NULL, original_name VARCHAR(255) NOT NULL, mime_type VARCHAR(90) NOT NULL, uploaded_by INT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(radiology_order_id) REFERENCES radiology_orders(id), FOREIGN KEY(uploaded_by) REFERENCES employees(id)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS emr_attachments (id INT AUTO_INCREMENT PRIMARY KEY, registration_id INT NOT NULL, description VARCHAR(200) NOT NULL, stored_name VARCHAR(120) NOT NULL, original_name VARCHAR(255) NOT NULL, mime_type VARCHAR(90) NOT NULL, uploaded_by INT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(registration_id) REFERENCES registrations(id), FOREIGN KEY(uploaded_by) REFERENCES employees(id)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS nursing_followups (id INT AUTO_INCREMENT PRIMARY KEY, registration_id INT NOT NULL, nurse_employee_id INT NOT NULL, action_note TEXT NOT NULL, performed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(registration_id) REFERENCES registrations(id), FOREIGN KEY(nurse_employee_id) REFERENCES employees(id)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS nursing_observations (id INT AUTO_INCREMENT PRIMARY KEY, registration_id INT NOT NULL, nurse_employee_id INT NOT NULL, bp VARCHAR(30) NULL, hr VARCHAR(20) NULL, rr VARCHAR(20) NULL, temp VARCHAR(20) NULL, spo2 VARCHAR(20) NULL, notes TEXT NULL, observed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(registration_id) REFERENCES registrations(id), FOREIGN KEY(nurse_employee_id) REFERENCES employees(id)) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lab_test_panels (id INT AUTO_INCREMENT PRIMARY KEY, panel_code VARCHAR(50) NOT NULL UNIQUE, panel_name VARCHAR(150) NOT NULL, is_active TINYINT(1) NOT NULL DEFAULT 1) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS lab_panel_keywords (id INT AUTO_INCREMENT PRIMARY KEY, panel_id INT NOT NULL, keyword VARCHAR(150) NOT NULL, UNIQUE KEY uq_lab_panel_keyword(panel_id,keyword), FOREIGN KEY (panel_id) REFERENCES lab_test_panels(id) ON DELETE CASCADE) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS lab_panel_parameters (id INT AUTO_INCREMENT PRIMARY KEY, panel_id INT NOT NULL, parameter_name VARCHAR(90) NOT NULL, result_unit VARCHAR(35) NULL, reference_range VARCHAR(100) NULL, sort_order INT NOT NULL DEFAULT 0, UNIQUE KEY uq_lab_panel_param(panel_id,parameter_name), FOREIGN KEY (panel_id) REFERENCES lab_test_panels(id) ON DELETE CASCADE) ENGINE=InnoDB;

INSERT INTO lab_test_panels(panel_code,panel_name) VALUES('CBC','Darah Lengkap') ON DUPLICATE KEY UPDATE panel_code=VALUES(panel_code);
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'darah lengkap' FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'cbc' FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'complete blood' FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Hemoglobin (Hb)','g/dL','12–17',1 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Hematokrit (Ht)','%','36–50',2 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Eritrosit','juta/µL','4,0–6,0',3 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Leukosit','ribu/µL','4–11',4 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Trombosit','ribu/µL','150–450',5 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'MCV','fL','80–100',6 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'MCH','pg','27–33',7 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'MCHC','g/dL','32–36',8 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'RDW','%','11,5–14,5',9 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Neutrofil','%','40–70',10 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Limfosit','%','20–45',11 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Monosit','%','2–10',12 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Eosinofil','%','1–6',13 FROM lab_test_panels WHERE panel_code='CBC';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Basofil','%','0–2',14 FROM lab_test_panels WHERE panel_code='CBC';
INSERT INTO lab_test_panels(panel_code,panel_name) VALUES('GLU','Gula Darah') ON DUPLICATE KEY UPDATE panel_code=VALUES(panel_code);
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'gula darah' FROM lab_test_panels WHERE panel_code='GLU';
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'glukosa' FROM lab_test_panels WHERE panel_code='GLU';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Glukosa','mg/dL','sesuai kondisi pemeriksaan',1 FROM lab_test_panels WHERE panel_code='GLU';
INSERT INTO lab_test_panels(panel_code,panel_name) VALUES('REN','Fungsi Ginjal') ON DUPLICATE KEY UPDATE panel_code=VALUES(panel_code);
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'fungsi ginjal' FROM lab_test_panels WHERE panel_code='REN';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Ureum','mg/dL','sesuai laboratorium',1 FROM lab_test_panels WHERE panel_code='REN';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Kreatinin','mg/dL','sesuai laboratorium',2 FROM lab_test_panels WHERE panel_code='REN';
INSERT INTO lab_test_panels(panel_code,panel_name) VALUES('LIV','Fungsi Hati') ON DUPLICATE KEY UPDATE panel_code=VALUES(panel_code);
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'fungsi hati' FROM lab_test_panels WHERE panel_code='LIV';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'AST / SGOT','U/L','sesuai laboratorium',1 FROM lab_test_panels WHERE panel_code='LIV';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'ALT / SGPT','U/L','sesuai laboratorium',2 FROM lab_test_panels WHERE panel_code='LIV';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Bilirubin Total','mg/dL','sesuai laboratorium',3 FROM lab_test_panels WHERE panel_code='LIV';
INSERT INTO lab_test_panels(panel_code,panel_name) VALUES('ELE','Elektrolit') ON DUPLICATE KEY UPDATE panel_code=VALUES(panel_code);
INSERT IGNORE INTO lab_panel_keywords(panel_id,keyword) SELECT id,'elektrolit' FROM lab_test_panels WHERE panel_code='ELE';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Natrium','mmol/L','135–145',1 FROM lab_test_panels WHERE panel_code='ELE';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Kalium','mmol/L','3,5–5,1',2 FROM lab_test_panels WHERE panel_code='ELE';
INSERT IGNORE INTO lab_panel_parameters(panel_id,parameter_name,result_unit,reference_range,sort_order) SELECT id,'Klorida','mmol/L','98–107',3 FROM lab_test_panels WHERE panel_code='ELE';
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-101','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-102','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-103','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-104','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-105','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Melati','M-106','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Anggrek','A-101','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Anggrek','A-102','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Anggrek','A-103','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Anggrek','A-104','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Mawar','MW-101','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Mawar','MW-102','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Mawar','MW-103','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Mawar','MW-104','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Flamboyan','F-101','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('Flamboyan','F-102','Kelas III');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('ICU','ICU-01','ICU');
INSERT IGNORE INTO hospital_beds(room,bed_code,room_class) VALUES ('ICU','ICU-02','ICU');
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0001','Paracetamol 500 mg','Analgesik/Antipiretik','tablet',500,100,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0002','Paracetamol 120 mg/5 mL','Analgesik/Antipiretik','botol',100,20,18000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0003','Ibuprofen 200 mg','NSAID','tablet',200,50,800);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0004','Ibuprofen 100 mg/5 mL','NSAID','botol',40,10,25000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0005','Amoxicillin 500 mg','Antibiotik','kapsul',300,60,1500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0006','Amoxicillin 125 mg/5 mL','Antibiotik','botol',50,10,22000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0007','Cefixime 200 mg','Antibiotik','kapsul',150,30,4500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0008','Ceftriaxone 1 g','Antibiotik injeksi','vial',100,20,18000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0009','Azithromycin 500 mg','Antibiotik','tablet',100,20,6000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0010','Omeprazole 20 mg','Gastrointestinal','kapsul',250,50,1200);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0011','Pantoprazole 40 mg','Gastrointestinal','vial',80,15,35000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0012','Antasida DOEN','Gastrointestinal','tablet',200,40,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0013','Ondansetron 4 mg','Antiemetik','tablet',150,30,2500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0014','Ondansetron 4 mg/2 mL','Antiemetik injeksi','ampul',100,20,12000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0015','Metoclopramide 10 mg','Antiemetik','tablet',100,20,700);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0016','Amlodipine 5 mg','Kardiovaskular','tablet',300,60,700);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0017','Amlodipine 10 mg','Kardiovaskular','tablet',200,40,1000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0018','Captopril 25 mg','Kardiovaskular','tablet',200,40,600);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0019','Bisoprolol 5 mg','Kardiovaskular','tablet',150,30,2500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0020','Furosemide 40 mg','Diuretik','tablet',200,40,700);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0021','Furosemide 10 mg/mL','Diuretik injeksi','ampul',80,15,8000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0022','Metformin 500 mg','Antidiabetes','tablet',400,80,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0023','Glibenclamide 5 mg','Antidiabetes','tablet',150,30,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0024','Insulin regular 100 IU/mL','Antidiabetes','vial',30,6,95000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0025','Salbutamol 2 mg','Respirasi','tablet',100,20,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0026','Salbutamol 2.5 mg/2.5 mL nebule','Respirasi','nebule',100,20,8500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0027','Cetirizine 10 mg','Antihistamin','tablet',200,40,700);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0028','Dexamethasone 0.5 mg','Kortikosteroid','tablet',150,30,500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0029','Dexamethasone 5 mg/mL','Kortikosteroid injeksi','ampul',80,15,5000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0030','RL 500 mL','Cairan infus','botol',100,20,12000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('OBT-0031','NaCl 0,9% 500 mL','Cairan infus','botol',100,20,11000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0001','Spuit 3 mL','BMHP','pcs',500,100,1200);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0002','Spuit 5 mL','BMHP','pcs',500,100,1500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0003','Infus set','BMHP','pcs',200,40,9000);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0004','Sarung tangan nitril (pasang)','BMHP','pasang',300,60,2500);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0005','Masker medis','BMHP','pcs',1000,200,800);
INSERT IGNORE INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price) VALUES ('BMHP-0006','Kasa steril 10 x 10 cm','BMHP','pak',100,20,12000);
INSERT IGNORE INTO roles(code,name) VALUES ('farmasi','Farmasi / Apoteker');
INSERT INTO units(code,name,unit_type) SELECT 'FAR','Farmasi','PENUNJANG' WHERE NOT EXISTS(SELECT 1 FROM units WHERE code='FAR');
INSERT IGNORE INTO permissions(code,name) VALUES ('emr.archive','Cari dan Unggah Dokumen Rekam Medis'),('nursing.manage','Catatan Keperawatan dan Tanda Vital'),('farmasi.manage','Kelola Farmasi dan Inventory'),('dashboard.view','Lihat Dashboard'),('roles.manage','Kelola Role dan Izin Akses');
INSERT INTO menus(label,icon,section_name,page_file,permission_code,sort_order,is_active) SELECT 'Pencarian dan Arsip Rekam Medis','▣','PELAYANAN','emr_archive.php','emr.archive',29,1 WHERE NOT EXISTS(SELECT 1 FROM menus WHERE page_file='emr_archive.php');
INSERT INTO menus(label,icon,section_name,page_file,permission_code,sort_order,is_active) SELECT 'Penyiapan Obat','Rx','PELAYANAN','pharmacy_orders.php','farmasi.manage',37,1 WHERE NOT EXISTS(SELECT 1 FROM menus WHERE page_file='pharmacy_orders.php');
INSERT INTO menus(label,icon,section_name,page_file,permission_code,sort_order,is_active) SELECT 'Catatan Keperawatan','✚','PELAYANAN','nursing_care.php','nursing.manage',35,1 WHERE NOT EXISTS(SELECT 1 FROM menus WHERE page_file='nursing_care.php');
INSERT INTO menus(label,icon,section_name,page_file,permission_code,sort_order,is_active) SELECT 'Manajemen Role & Izin','⚙','DATA MASTER','role_management.php','roles.manage',12,1 WHERE NOT EXISTS(SELECT 1 FROM menus WHERE page_file='role_management.php');
UPDATE menus SET is_active=0 WHERE page_file='demo_data.php';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='registration.manage' WHERE r.code='admisi';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='farmasi.manage' WHERE r.code='farmasi';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='emr.archive' WHERE r.code='rekammedis';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='emr.archive' WHERE r.code='admin_simrs';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='nursing.manage' WHERE r.code='perawat';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='nursing.manage' WHERE r.code='igd';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code='roles.manage' WHERE r.code='admin_simrs';
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT r.id,p.id FROM roles r CROSS JOIN permissions p WHERE p.code='dashboard.view';
-- Tidak ada password/akun perawat yang diciptakan otomatis; gunakan Data Pegawai, Pendaftaran Pengguna, dan Manajemen Role.
-- Tidak mengubah tanggal kedaluwarsa obat. Isi sesuai data faktual setiap batch.

-- Staf Farmasi tersimpan sebagai master pegawai, akun dibuat lewat menu Pendaftaran Pengguna.

INSERT INTO employees(employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-FAR-001','Apt. Nadia Farmasi, S.Farm','Apoteker',r.id,u.id,1
FROM roles r JOIN units u ON u.code='FAR'
WHERE r.code='farmasi' AND NOT EXISTS(SELECT 1 FROM employees WHERE employee_code='PEG-FAR-001');


