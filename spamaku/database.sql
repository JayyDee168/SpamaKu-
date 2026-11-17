-- ============================================================
--  DATABASE.SQL — gudang datanya Spamaku!
--  Import lewat phpMyAdmin (tab Import → pilih file ini → Go).
--  Kalau muncul "#1046 No database selected" pas import, santai aja,
--  itu cuma phpMyAdmin lagi drama. Datanya tetap masuk.
--  PERINGATAN: database "spamaku" yang lama bakal dihapus dulu.
-- ============================================================

DROP DATABASE IF EXISTS spamaku;
CREATE DATABASE spamaku CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE spamaku;

-- ---------- PENGGUNA (semua akun, termasuk admin) ----------
CREATE TABLE pengguna (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nama        VARCHAR(100) NOT NULL,
  namaPengguna VARCHAR(30)  NOT NULL UNIQUE,
  email       VARCHAR(120) NOT NULL UNIQUE,
  npm         VARCHAR(20)  NULL,
  prodi       VARCHAR(80)  NULL,
  angkatan    YEAR         NULL,
  bio         VARCHAR(255) NULL,
  kataSandi    VARCHAR(255) NOT NULL,          -- hasil password_hash()
  peran        ENUM('mahasiswa','admin') NOT NULL DEFAULT 'mahasiswa',
  foto        VARCHAR(255) NULL,
  dibuatPada  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- KATEGORI SPAMA (5 bos terakhir sebelum wisuda) ----------
CREATE TABLE kategori (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nama          VARCHAR(60) NOT NULL,
  singkatan     VARCHAR(4)  NOT NULL,
  poinMinimum  INT NOT NULL,
  warna         CHAR(7) NOT NULL,
  urutan        INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ---------- ORGANISASI (penyelenggara) ----------
CREATE TABLE organisasi (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nama        VARCHAR(100) NOT NULL,
  deskripsi   TEXT NULL,
  status      ENUM('menunggu','disetujui','ditolak') NOT NULL DEFAULT 'menunggu',
  dibuatOleh  INT NULL,
  dibuatPada  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dibuatOleh) REFERENCES pengguna(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE anggota (
  idOrganisasi  INT NOT NULL,
  idPengguna        INT NOT NULL,
  jabatan        ENUM('ketua','anggota') NOT NULL DEFAULT 'anggota',
  PRIMARY KEY (idOrganisasi, idPengguna),
  FOREIGN KEY (idOrganisasi) REFERENCES organisasi(id) ON DELETE CASCADE,
  FOREIGN KEY (idPengguna) REFERENCES pengguna(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- ACARA / EVENT ----------
CREATE TABLE acara (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  idOrganisasi   INT NOT NULL,
  judul           VARCHAR(150) NOT NULL,
  deskripsi       TEXT NOT NULL,
  tanggalMulai   DATETIME NOT NULL,
  tanggalSelesai DATETIME NULL,
  mode            ENUM('offline','online') NOT NULL DEFAULT 'offline',
  lokasi          VARCHAR(200) NULL,
  lintang        DECIMAL(10,7) NULL,
  bujur       DECIMAL(10,7) NULL,
  biaya           INT NOT NULL DEFAULT 0,
  linkDaftar      VARCHAR(255) NULL,               -- link pendaftaran resmi dari panitia (Google Form, dll)
  poster          VARCHAR(255) NULL,
  status          ENUM('menunggu','disetujui','ditolak') NOT NULL DEFAULT 'menunggu',
  catatanAdmin   VARCHAR(255) NULL,
  dibuatPada      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (idOrganisasi) REFERENCES organisasi(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Satu event bisa memberi poin di beberapa kategori
CREATE TABLE poinAcara (
  idAcara     INT NOT NULL,
  idKategori  INT NOT NULL,
  poin         INT NOT NULL,
  PRIMARY KEY (idAcara, idKategori),
  FOREIGN KEY (idAcara) REFERENCES acara(id) ON DELETE CASCADE,
  FOREIGN KEY (idKategori) REFERENCES kategori(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- KERANJANG (event yang disimpan mahasiswa. belum tentu didatengin 😅) ----------
CREATE TABLE keranjang (
  idPengguna     INT NOT NULL,
  idAcara    INT NOT NULL,
  dibuatPada  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (idPengguna, idAcara),
  FOREIGN KEY (idPengguna) REFERENCES pengguna(id) ON DELETE CASCADE,
  FOREIGN KEY (idAcara) REFERENCES acara(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- POIN SIKMA ----------
-- Poin resmi tetap dicatat di SIKMA. Di sini mahasiswa cuma nyalin angkanya
-- biar Spamaku! bisa ngitung kurang berapa & kasih rekomendasi event.
CREATE TABLE poinSikma (
  idPengguna  INT NOT NULL,
  idKategori  INT NOT NULL,
  poin        INT NOT NULL DEFAULT 0,
  PRIMARY KEY (idPengguna, idKategori),
  FOREIGN KEY (idPengguna) REFERENCES pengguna(id) ON DELETE CASCADE,
  FOREIGN KEY (idKategori) REFERENCES kategori(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  DATA AWAL (biar pas dibuka nggak sepi kayak kuburan)
-- ============================================================

INSERT INTO kategori (id, nama, singkatan, poinMinimum, warna, urutan) VALUES
 (1, 'Keatmajayaan',               'KAJ', 25, '#F3AD1B', 1),
 (2, 'Penalaran',                  'PNL', 12, '#22D3EE', 2),
 (3, 'Minat Bakat',                'MB',   8, '#F472B6', 3),
 (4, 'Pengabdian kepada Masyarakat','PKM',  6, '#34D399', 4),
 (5, 'Organisasi & Kepemimpinan',  'ORG', 14, '#60A5FA', 5);

-- Akun demo
--   admin     / admin123
--   mahasiswa / password123
--   panitia   / password123
INSERT INTO pengguna (id, nama, namaPengguna, email, npm, prodi, angkatan, kataSandi, peran) VALUES
 (1, 'Admin Spamaku!', 'admin',     'admin@spamaku.test',     NULL,        NULL,          NULL, '$2y$10$sEKcYekdxkmoCh4.L/27Y.Oegkin2ij9wWKS5rxOA7cIfVjUWgUSG', 'admin'),
 (2, 'Budi Santoso',    'mahasiswa', 'budi@students.uajy.ac.id', '250712345', 'Informatika', 2025, '$2y$10$mmrMKwfA5FY74d3UA2lNDueBfsi2GU.NHam/Q11H9Emfqhz06oPZq', 'mahasiswa'),
 (3, 'Rani Pratiwi',    'panitia',   'rani@students.uajy.ac.id', '240711111', 'Informatika', 2024, '$2y$10$mmrMKwfA5FY74d3UA2lNDueBfsi2GU.NHam/Q11H9Emfqhz06oPZq', 'mahasiswa');

INSERT INTO organisasi (id, nama, deskripsi, status, dibuatOleh) VALUES
 (1, 'BEM FTI UAJY',          'Badan Eksekutif Mahasiswa Fakultas Teknologi Industri.', 'disetujui', 3),
 (2, 'UKM Fotografi Atma Jaya','Unit kegiatan mahasiswa bidang fotografi.',             'disetujui', 3),
 (3, 'KSR PMI Unit UAJY',      'Korps Sukarela PMI unit kampus.',                        'menunggu',  2);

INSERT INTO anggota (idOrganisasi, idPengguna, jabatan) VALUES
 (1, 3, 'ketua'), (2, 3, 'ketua'), (3, 2, 'ketua');

INSERT INTO acara (id, idOrganisasi, judul, deskripsi, tanggalMulai, tanggalSelesai, mode, lokasi, lintang, bujur, biaya, linkDaftar, status) VALUES
 (1, 1, 'Donor Darah Bersama FTI', 'Setetes darahmu menyelamatkan nyawa. Donor darah bekerja sama dengan PMI Kota Yogyakarta. Peserta wajib sarapan dan membawa KTM.', '2026-11-20 08:00:00', '2026-11-20 13:00:00', 'offline', 'Gedung Bonaventura, Kampus 3 UAJY, Babarsari', -7.7795000, 110.4148000, 0, 'https://example.com/daftar/event-1', 'disetujui'),
 (2, 1, 'Lomba Karya Tulis Ilmiah FTI 2026', 'Kompetisi karya tulis ilmiah tingkat universitas dengan tema "Teknologi untuk Keberlanjutan". Tim maksimal 3 orang.', '2026-11-28 09:00:00', '2026-11-28 16:00:00', 'offline', 'Ruang Seminar Gedung Bonaventura, Babarsari', -7.7797000, 110.4146000, 25000, 'https://example.com/daftar/event-2', 'disetujui'),
 (3, 1, 'Latihan Kepemimpinan Mahasiswa (LKMM)', 'Pelatihan dasar kepemimpinan dan manajemen organisasi selama dua hari. Wajib bagi calon pengurus organisasi.', '2026-12-05 08:00:00', '2026-12-06 16:00:00', 'offline', 'Kampus 2 UAJY, Jl. Babarsari 6', -7.7790000, 110.4135000, 0, 'https://example.com/daftar/event-3', 'disetujui'),
 (4, 2, 'Hunting Foto Malioboro', 'Hunting foto street photography bareng UKM Fotografi. Bawa kamera atau HP, kita belajar komposisi langsung di lapangan.', '2026-11-22 15:00:00', '2026-11-22 19:00:00', 'offline', 'Titik Nol Kilometer, Malioboro', -7.8013000, 110.3647000, 0, 'https://example.com/daftar/event-4', 'disetujui'),
 (5, 1, 'Seminar Nasional AI & Etika', 'Seminar daring bersama praktisi industri membahas penggunaan AI yang bertanggung jawab.', '2026-11-25 13:00:00', '2026-11-25 15:30:00', 'online', 'Zoom Meeting', NULL, NULL, 0, 'https://example.com/daftar/event-5', 'disetujui'),
 (6, 1, 'Bakti Sosial Desa Kalibiru', 'Kegiatan pengabdian: mengajar anak-anak, kerja bakti, dan pembagian sembako di Desa Kalibiru, Kulon Progo.', '2026-12-12 06:00:00', '2026-12-12 17:00:00', 'offline', 'Desa Kalibiru, Kulon Progo', -7.8091000, 110.1294000, 50000, 'https://example.com/daftar/event-6', 'disetujui'),
 (7, 1, 'Misa & Rekoleksi Kampus', 'Rekoleksi dan refleksi nilai-nilai Atma Jaya: Serviens in Lumine Veritatis.', '2026-11-15 08:00:00', '2026-11-15 12:00:00', 'offline', 'Kampus 1 UAJY, Mrican', -7.7760000, 110.3880000, 0, 'https://example.com/daftar/event-7', 'disetujui'),
 (8, 2, 'Festival Band Antar Fakultas', 'Ajang unjuk bakat musik antar fakultas. Daftar sebagai penampil atau kru.', '2026-12-01 16:00:00', '2026-12-01 22:00:00', 'offline', 'Lapangan Kampus 3 UAJY', -7.7799000, 110.4152000, 0, 'https://example.com/daftar/event-8', 'disetujui'),
 (9, 1, 'Workshop UI/UX untuk Pemula', 'Belajar dasar desain antarmuka menggunakan Figma.', '2026-12-08 09:00:00', '2026-12-08 12:00:00', 'offline', 'Lab Komputer Bonaventura', -7.7796000, 110.4149000, 15000, 'https://example.com/daftar/event-9', 'menunggu'),
 (10, 1, 'Inisiasi Atma Jaya 2026', 'Masa pengenalan kampus bagi mahasiswa baru.', '2026-08-20 07:00:00', '2026-08-22 16:00:00', 'offline', 'Kampus 3 UAJY', -7.7795000, 110.4148000, 0, NULL, 'disetujui'),
 (11, 1, 'Donor Darah September', 'Donor darah rutin.', '2026-09-15 08:00:00', '2026-09-15 12:00:00', 'offline', 'Kampus 3 UAJY', -7.7795000, 110.4148000, 0, NULL, 'disetujui'),
 (12, 1, 'Debat Mahasiswa FTI', 'Kompetisi debat bahasa Indonesia.', '2026-10-10 09:00:00', '2026-10-10 15:00:00', 'offline', 'Kampus 3 UAJY', -7.7795000, 110.4148000, 0, NULL, 'disetujui');

INSERT INTO poinAcara (idAcara, idKategori, poin) VALUES
 (1, 4, 2), (1, 1, 1),
 (2, 2, 4),
 (3, 5, 4), (3, 1, 2),
 (4, 3, 2),
 (5, 2, 2), (5, 1, 1),
 (6, 4, 3),
 (7, 1, 2),
 (8, 3, 3),
 (9, 2, 2),
 (10, 1, 8), (10, 5, 2),
 (11, 4, 2),
 (12, 2, 3);

-- poin Budi yang disalin dari SIKMA
INSERT INTO poinSikma (idPengguna, idKategori, poin) VALUES
 (2, 1, 8), (2, 2, 3), (2, 3, 3), (2, 4, 2), (2, 5, 2);

INSERT INTO keranjang (idPengguna, idAcara) VALUES (2, 3), (2, 4);
