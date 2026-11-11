<?php
require_once __DIR__ . '/includes/functions.php';
$user = require_login();
require_permission($user, 'farmasi.manage');
$pageTitle = 'Farmasi & Persediaan';
$pdo = db();
$pdo->exec("CREATE TABLE IF NOT EXISTS pharmacy_items (
 id INT AUTO_INCREMENT PRIMARY KEY, item_code VARCHAR(40) NOT NULL UNIQUE, item_name VARCHAR(160) NOT NULL,
 category VARCHAR(80) NOT NULL DEFAULT 'Obat', unit VARCHAR(30) NOT NULL DEFAULT 'tablet',
 stock INT NOT NULL DEFAULT 0, minimum_stock INT NOT NULL DEFAULT 10, price DECIMAL(12,2) NOT NULL DEFAULT 0,
 expiry_date DATE NULL, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB");
$pdo->exec("CREATE TABLE IF NOT EXISTS pharmacy_transactions (
 id INT AUTO_INCREMENT PRIMARY KEY, item_id INT NOT NULL, transaction_type ENUM('Masuk','Keluar') NOT NULL,
 quantity INT NOT NULL, note VARCHAR(255) NULL, employee_id INT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (item_id) REFERENCES pharmacy_items(id), FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB");
if ($_SERVER['REQUEST_METHOD']==='POST') {
 if (is_admin($user)) {http_response_code(403);exit('Admin hanya dapat melihat data farmasi.');} check_csrf();
 $action=$_POST['action']??'';
 try {
  if($action==='add') {
   $stmt=$pdo->prepare('INSERT INTO pharmacy_items(item_code,item_name,category,unit,stock,minimum_stock,price,expiry_date) VALUES(?,?,?,?,?,?,?,?)');
   $stmt->execute([trim($_POST['item_code']),trim($_POST['item_name']),trim($_POST['category']),trim($_POST['unit']),max(0,(int)$_POST['stock']),max(0,(int)$_POST['minimum_stock']),max(0,(float)$_POST['price']),(($_POST['expiry_date']??'')?:null)]);
   flash('success','Item farmasi berhasil ditambahkan.');
  } elseif($action==='update_expiry') {
   if (($user['role_code'] ?? '') !== 'farmasi') throw new RuntimeException('Hanya petugas farmasi yang berwenang memperbarui tanggal kedaluwarsa.');
   $itemId = filter_var($_POST['item_id'] ?? null, FILTER_VALIDATE_INT);
   $date = trim((string)($_POST['expiry_date'] ?? ''));
   $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
   if (!$itemId || !$parsed || $parsed->format('Y-m-d') !== $date) {
      throw new RuntimeException('Pilih obat dan isi tanggal kedaluwarsa yang valid.');
   }
   $stmt = $pdo->prepare('UPDATE pharmacy_items SET expiry_date=? WHERE id=?');
   $stmt->execute([$date, $itemId]);
   if ($stmt->rowCount()===0) {
      $check=$pdo->prepare('SELECT id FROM pharmacy_items WHERE id=?');$check->execute([$itemId]);
      if (!$check->fetchColumn()) throw new RuntimeException('Item farmasi tidak ditemukan.');
   }
   flash('success','Tanggal kedaluwarsa tersimpan di MariaDB.');
  } elseif($action==='stock') {
   $itemId=(int)$_POST['item_id']; $qty=max(1,(int)$_POST['quantity']); $type=$_POST['transaction_type']==='Keluar'?'Keluar':'Masuk';
   $pdo->beginTransaction();
   $q=$pdo->prepare('SELECT stock FROM pharmacy_items WHERE id=? FOR UPDATE');$q->execute([$itemId]);$stock=$q->fetchColumn();
   if($stock===false || ($type==='Keluar' && (int)$stock<$qty)) throw new RuntimeException('Stok tidak tersedia atau jumlah keluar melebihi stok.');
   $pdo->prepare('UPDATE pharmacy_items SET stock=stock '.($type==='Masuk'?'+':'-').' ? WHERE id=?')->execute([$qty,$itemId]);
   $pdo->prepare('INSERT INTO pharmacy_transactions(item_id,transaction_type,quantity,note,employee_id) VALUES(?,?,?,?,?)')->execute([$itemId,$type,$qty,trim($_POST['note']??''),(int)$user['employee_id']]);
   $pdo->commit(); flash('success','Transaksi stok berhasil dicatat.');
  }
 } catch(Throwable $e) { if($pdo->inTransaction())$pdo->rollBack(); flash('error',$e instanceof RuntimeException?$e->getMessage():'Data gagal disimpan. Pastikan kode item unik dan semua kolom valid.'); }
 redirect('farmasi.php');
}
$items=$pdo->query('SELECT * FROM pharmacy_items ORDER BY item_name')->fetchAll();
$history=$pdo->query('SELECT t.created_at,t.transaction_type,t.quantity,t.note,i.item_name,e.full_name FROM pharmacy_transactions t JOIN pharmacy_items i ON i.id=t.item_id JOIN employees e ON e.id=t.employee_id ORDER BY t.id DESC LIMIT 15')->fetchAll();
$low=(int)$pdo->query('SELECT COUNT(*) FROM pharmacy_items WHERE stock<=minimum_stock')->fetchColumn();
$expiryMissing=(int)$pdo->query('SELECT COUNT(*) FROM pharmacy_items WHERE expiry_date IS NULL')->fetchColumn();
$expirySoon=(int)$pdo->query('SELECT COUNT(*) FROM pharmacy_items WHERE expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)')->fetchColumn();
$expiryPast=(int)$pdo->query('SELECT COUNT(*) FROM pharmacy_items WHERE expiry_date < CURDATE()')->fetchColumn();
require __DIR__.'/includes/header.php';
?>
<h1 class="page-title">Farmasi & Persediaan</h1><p><a class="btn btn-secondary" href="pharmacy_orders.php">Buka Daftar Order dan Penyerahan Obat</a></p><p class="page-subtitle">Pengelolaan persediaan obat dan alat kesehatan, transaksi stok, serta pemantauan stok minimum.</p>
<div class="stats-grid"><div class="stat-card"><span>Belum ada tanggal kedaluwarsa</span><strong><?=$expiryMissing?></strong><small>Perlu dilengkapi dari label/kemasan</small></div><div class="stat-card"><span>Kedaluwarsa / segera</span><strong><?=$expiryPast+$expirySoon?></strong><small><?=$expiryPast?> sudah lewat, <?=$expirySoon?> dalam 90 hari</small></div><div class="stat-card"><span>Total Item</span><strong><?=count($items)?></strong></div><div class="stat-card"><span>Perlu isi ulang</span><strong><?=$low?></strong><small>Item pada/bawah stok minimum</small></div><div class="stat-card"><span>Transaksi Terbaru</span><strong><?=count($history)?></strong><small>15 transaksi terakhir</small></div></div>
<?php if(!is_admin($user)):?><div class="grid grid-2">
<div class="card"><h2 class="section-title">Tambah item</h2><form method="post"><input type="hidden" name="action" value="add"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><div class="field"><label>Kode item</label><input class="input" name="item_code" placeholder="OBT-001" required></div><div class="field"><label>Nama obat / item</label><input class="input" name="item_name" required></div><div class="field"><label>Kategori</label><select class="input" name="category"><option>Obat</option><option>Alat Kesehatan</option><option>Bahan Medis Habis Pakai</option></select></div><div class="field"><label>Satuan</label><input class="input" name="unit" value="tablet" required></div><div class="grid grid-2"><div class="field"><label>Stok awal</label><input class="input" type="number" name="stock" min="0" value="0"></div><div class="field"><label>Stok minimum</label><input class="input" type="number" name="minimum_stock" min="0" value="10"></div></div><div class="grid grid-2"><div class="field"><label>Harga satuan (Rp)</label><input class="input" type="number" name="price" min="0" step="0.01" value="0"></div><div class="field"><label>Kedaluwarsa</label><input class="input" type="date" name="expiry_date"></div></div><button class="btn btn-primary">Simpan item</button></form></div>
<div class="card"><h2 class="section-title">Catat pergerakan stok</h2><form method="post"><input type="hidden" name="action" value="stock"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>"><div class="field"><label>Item</label><select class="input" name="item_id" required><?php foreach($items as $i):?><option value="<?=$i['id']?>"><?=e($i['item_code'].' · '.$i['item_name'])?> (stok <?=$i['stock']?>)</option><?php endforeach;?></select></div><div class="grid grid-2"><div class="field"><label>Jenis transaksi</label><select class="input" name="transaction_type"><option>Masuk</option><option>Keluar</option></select></div><div class="field"><label>Jumlah</label><input class="input" type="number" name="quantity" min="1" required></div></div><div class="field"><label>Keterangan / nomor dokumen</label><input class="input" name="note" placeholder="Pembelian, retur, atau pemakaian"></div><button class="btn btn-primary" <?=!$items?'disabled':''?>>Catat transaksi</button></form><p class="note">Transaksi keluar akan ditolak jika stok tidak mencukupi.</p></div>
</div>
<?php if(($user['role_code'] ?? '') === 'farmasi'): ?>
<div class="card"><h2 class="section-title">Lengkapi / Perbarui Tanggal Kedaluwarsa</h2>
<p class="note">Tanggal harus sesuai kemasan atau dokumen batch yang sebenarnya. Data obat awal belum otomatis mempunyai tanggal karena tanggal tersebut tidak tersedia dalam SQL sumber.</p>
<form method="post"><input type="hidden" name="action" value="update_expiry"><input type="hidden" name="csrf_token" value="<?=e(csrf_token())?>">
<div class="grid grid-2"><div class="field"><label>Item Farmasi</label><select class="input" name="item_id" required><option value="">-- Pilih obat --</option><?php foreach($items as $i):?><option value="<?=(int)$i['id']?>"><?=e($i['item_code'].' · '.$i['item_name'].' · '.($i['expiry_date']?:'belum ada tanggal'))?></option><?php endforeach;?></select></div>
<div class="field"><label>Tanggal Kedaluwarsa</label><input class="input" type="date" name="expiry_date" required></div></div>
<button class="btn btn-primary">Simpan Tanggal Kedaluwarsa</button></form></div>
<?php endif;?>
<?php else: ?><p class="note">Administrator: mode lihat saja; perubahan inventaris hanya dapat dilakukan petugas farmasi.</p><?php endif;?>
<div class="card"><h2 class="section-title">Daftar persediaan</h2><p class="note">Tanggal kedaluwarsa dibaca dari <b>pharmacy_items.expiry_date</b> di MariaDB. Tanggal kosong berarti belum tercatat dan <b>tidak boleh dianggap masih aman</b>. Peringatan kuning: 90 hari menjelang kedaluwarsa.</p><div class="table-wrap"><table><thead><tr><th>Kode</th><th>Nama item</th><th>Satuan / Bentuk</th><th>Kategori</th><th>Stok</th><th>Minimum</th><th>Harga</th><th>Kedaluwarsa</th><th>Status</th></tr></thead><tbody><?php foreach($items as $i):?><tr><td><?=e($i['item_code'])?></td><td><b><?=e($i['item_name'])?></b></td><td><?=e(ucfirst($i['unit']))?></td><td><?=e($i['category'])?></td><td><?=$i['stock']?></td><td><?=$i['minimum_stock']?></td><td>Rp <?=number_format((float)$i['price'],0,',','.')?></td><td><?=e($i['expiry_date']?date('d/m/Y',strtotime($i['expiry_date'])):'Belum diisi')?></td><td><?php if($i['expiry_date'] && $i['expiry_date'] < date('Y-m-d')): ?><span class="badge badge-red">Kedaluwarsa</span><?php elseif($i['expiry_date'] && $i['expiry_date'] <= date('Y-m-d',strtotime('+90 days'))): ?><span class="badge badge-yellow">Segera Kedaluwarsa</span><?php elseif(!$i['expiry_date']):?><span class="badge badge-yellow">Tanggal belum diisi</span><?php elseif($i['stock']<=$i['minimum_stock']):?><span class="badge badge-red">Isi Stok</span><?php else:?><span class="badge badge-green">Aman</span><?php endif;?></td></tr><?php endforeach;?><?php if(!$items):?><tr><td colspan="9">Belum ada item farmasi. Tambahkan item melalui formulir di atas.</td></tr><?php endif;?></tbody></table></div></div>
<div class="card"><h2 class="section-title">Riwayat transaksi stok</h2><div class="table-wrap"><table><thead><tr><th>Waktu</th><th>Item</th><th>Jenis</th><th>Jumlah</th><th>Keterangan</th><th>Pegawai</th></tr></thead><tbody><?php foreach($history as $h):?><tr><td><?=e($h['created_at'])?></td><td><?=e($h['item_name'])?></td><td><?=e($h['transaction_type'])?></td><td><?=$h['quantity']?></td><td><?=e($h['note']??'-')?></td><td><?=e($h['full_name'])?></td></tr><?php endforeach;?><?php if(!$history):?><tr><td colspan="6">Belum ada transaksi.</td></tr><?php endif;?></tbody></table></div></div>
<?php require __DIR__.'/includes/footer.php'; ?>
