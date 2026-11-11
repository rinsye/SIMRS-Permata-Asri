-- SIMRS Permata Asri | Migrasi data-driven | Untuk DB yang SUDAH ADA
-- Backup DB terlebih dahulu; jalankan sekali di phpMyAdmin pada database simrs_permata_asri.
-- Data transaksi (pasien, EMR, order) tidak dihapus atau diganti.
USE `simrs_permata_asri`;

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
-- Pegawai farmasi master awal (tidak membuat akun atau password tanpa otorisasi admin).
INSERT INTO employees(employee_code,full_name,profession,role_id,unit_id,is_active)
SELECT 'PEG-FAR-001','Apt. Nadia Farmasi, S.Farm','Apoteker',r.id,u.id,1
FROM roles r JOIN units u ON u.code='FAR'
WHERE r.code='farmasi' AND NOT EXISTS(SELECT 1 FROM employees WHERE employee_code='PEG-FAR-001');

-- Hak edit klinis tidak diberikan ke admin pendaftaran; kewenangan akun bergantung pada role dan penugasan.
-- Akun poli yang sudah ada dipertahankan. Untuk akun baru, petugas menggunakan antarmuka admin.
SELECT 'MIGRASI_MASTER_OK' AS status;
