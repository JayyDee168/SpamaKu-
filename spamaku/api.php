<?php
/* ================================================================
   API.PHP — pelayan JSON. JavaScript pesen, PHP nganterin datanya.
     api.php?aksi=landing                       → data halaman utama (index.xhtml)
     api.php?aksi=cek&field=email&value=a@b.c   → cek username/email udah dipakai belum
   ================================================================ */
require 'inti.php';
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$aksi = $_GET['aksi'] ?? '';

// ---------- CEK USERNAME / EMAIL (dipanggil tiap user berhenti ngetik) ----------
if ($aksi === 'cek') {
    $kolom = $_GET['field'] ?? '';
    $nilai = strtolower(trim($_GET['value'] ?? ''));

    // whitelist kolom. kalau nggak, orang bisa iseng masukin SQL aneh-aneh ke sini
    if (!in_array($kolom, ['namaPengguna', 'email'], true) || $nilai === '') {
        exit(json_encode(['tersedia' => false, 'pesan' => '']));
    }
    if ($kolom === 'namaPengguna' && !preg_match('/^[a-z0-9_.]{3,30}$/', $nilai)) {
        exit(json_encode(['tersedia' => false, 'pesan' => '3–30 karakter: huruf kecil, angka, titik, garis bawah.']));
    }
    if ($kolom === 'email' && !filter_var($nilai, FILTER_VALIDATE_EMAIL)) {
        exit(json_encode(['tersedia' => false, 'pesan' => 'Format email belum valid.']));
    }

    $sql = "SELECT 1 FROM pengguna WHERE $kolom = ?";
    $param = [$nilai];
    if (!empty($_GET['exclude']) && isLogin()) {   // di halaman profil, akun sendiri jangan dihitung
        $sql .= ' AND id <> ?';
        $param[] = getPenggunaAktif()['id'];
    }
    $stmt = $pdo->prepare($sql);
    $stmt->execute($param);
    $terpakai = (bool)$stmt->fetch();
    $label = $kolom === 'email' ? 'Email' : 'Username';

    exit(json_encode([
        'tersedia' => !$terpakai,
        'pesan' => $terpakai ? "$label sudah dipakai." : "$label tersedia ✓",
    ], JSON_UNESCAPED_UNICODE));
}

// ---------- DATA HALAMAN UTAMA ----------
if ($aksi === 'landing') {
    $statistik = $pdo->query("SELECT
        (SELECT COUNT(*) FROM acara WHERE status='disetujui' AND tanggalMulai >= NOW()) AS akanDatang,
        (SELECT COUNT(*) FROM organisasi WHERE status='disetujui') AS organisasi,
        (SELECT COUNT(*) FROM pengguna) AS pengguna,
        (SELECT COALESCE(SUM(pa.poin),0) FROM poinAcara pa JOIN acara a ON a.id = pa.idAcara
          WHERE a.status='disetujui' AND a.tanggalMulai >= NOW()) AS poin")->fetch();

    $kategori = array_values(array_map(fn($k) => [
        'id' => (int)$k['id'], 'nama' => $k['nama'], 'singkatan' => $k['singkatan'],
        'minimum' => (int)$k['poinMinimum'], 'warna' => $k['warna'],
    ], getSemuaKategori()));

    $baris = $pdo->query(sqlAcara() . " WHERE a.status='disetujui' AND a.tanggalMulai >= NOW() ORDER BY a.tanggalMulai LIMIT 4")->fetchAll();
    $poinPerAcara = getPoinAcara(array_column($baris, 'id'));
    $saya = getPenggunaAktif();
    $idKeranjang = getIdKeranjang();

    $acara = array_map(fn($a) => [
        'id' => (int)$a['id'],
        'judul' => $a['judul'],
        'organisasi' => $a['namaOrganisasi'],
        'tanggal' => formatTanggal($a['tanggalMulai']),
        'mode' => $a['mode'],
        'lokasi' => $a['lokasi'],
        'biaya' => formatRupiah((int)$a['biaya']),
        'totalPoin' => (int)$a['totalPoin'],
        'poster' => getUrlPoster($a),
        'poin' => array_map(fn($p) => ['kategori' => (int)$p['idKategori'], 'poin' => (int)$p['poin']], $poinPerAcara[$a['id']] ?? []),
        'inKeranjang' => in_array((int)$a['id'], $idKeranjang, true),
    ], $baris);

    exit(json_encode([
        'statistik' => array_map('intval', $statistik),
        'kategori' => $kategori,
        'acara' => $acara,
        'pengguna' => $saya ? [
            'namaPengguna' => $saya['namaPengguna'],
            'foto' => getUrlAvatar($saya),
            'admin' => $saya['peran'] === 'admin',
            'keranjang' => count($idKeranjang),
        ] : null,
        'tokenCsrf' => $saya ? getTokenCsrf() : null,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
}

http_response_code(404);
echo json_encode(['pesan' => 'Aksi tidak dikenal. Kamu nyasar ya?']);
