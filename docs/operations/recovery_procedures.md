# Prosedur Pemulihan - Data Warehouse DM_SatuDataITERA_DW

---
## Daftar Isi

1. [Gambaran Umum](#gambaran-umum)
2. [Tujuan Pemulihan](#tujuan-pemulihan)
3. [Ringkasan Strategi Backup](#ringkasan-strategi-backup)
4. [Skenario Pemulihan](#skenario-pemulihan)
5. [Prosedur Pemulihan Langkah Demi Langkah](#prosedur-pemulihan-langkah-demi-langkah)
6. [Pemulihan Point-in-Time](#pemulihan-point-in-time)
7. [Pemulihan Bencana](#pemulihan-bencana)
8. [Pengujian dan Validasi](#pengujian-dan-validasi)
9. [Pemecahan Masalah](#pemecahan-masalah)
10. [Informasi Kontak](#informasi-kontak)

---

## Gambaran Umum

Dokumen ini menyediakan prosedur pemulihan komprehensif untuk data warehouse DM_SatuDataITERA_DW (Satu Data ITERA). Dokumen ini mencakup berbagai skenario bencana dan memberikan instruksi langkah demi langkah untuk operasi pemulihan database.

### Tujuan
- Meminimalkan kehilangan data saat terjadi kegagalan
- Menyediakan prosedur pemulihan yang jelas untuk berbagai skenario
- Memastikan kelangsungan bisnis
- Memenuhi persyaratan kepatuhan dan audit

### Ruang Lingkup
Dokumen ini mencakup prosedur pemulihan untuk:
- Kehilangan database secara menyeluruh
- File database yang rusak
- Penghapusan data tidak disengaja
- Skenario pemulihan point-in-time
- Situasi pemulihan bencana

---

## Tujuan Pemulihan

### RTO (Recovery Time Objective)
**Target:** Maksimal 4 jam downtime

### RPO (Recovery Point Objective)
**Target:** Maksimal 6 jam kehilangan data

Berdasarkan jadwal backup:
- Backup Penuh: Mingguan (Minggu 02:00)
- Backup Diferensial: Harian (02:00)
- Backup Transaction Log: Setiap 6 jam

---

## Ringkasan Strategi Backup

### Jadwal Backup

| Tipe Backup | Frekuensi | Waktu | Retensi | Lokasi |
|-------------|-----------|-------|---------|--------|
| Penuh | Mingguan | Minggu 02:00 | 30 hari | /var/opt/mssql/data/ |
| Diferensial | Harian | Sen-Sab 02:00 | 14 hari | /var/opt/mssql/data/ |
| Transaction Log | Setiap 6 jam | 00:00, 06:00, 12:00, 18:00 | 7 hari | /var/opt/mssql/data/ |

### Konvensi Penamaan File Backup

- **Penuh:** `DM_SatuDataITERA_DW_Full_YYYYMMDD_HHMMSS.bak`
- **Diferensial:** `DM_SatuDataITERA_DW_Diff_YYYYMMDD_HHMMSS.bak`
- **Log:** `DM_SatuDataITERA_DW_Log_YYYYMMDD_HHMMSS.trn`

---

## Skenario Pemulihan

### Skenario 1: Kehilangan Database Secara Menyeluruh
**Situasi:** File database rusak atau terhapus  
**Dampak:** Data tidak tersedia sepenuhnya  
**Metode Pemulihan:** Restore Penuh + Diferensial + Log

### Skenario 2: Penghapusan Data Tidak Disengaja
**Situasi:** Pengguna secara tidak sengaja menghapus data penting  
**Dampak:** Kehilangan data parsial  
**Metode Pemulihan:** Restore point-in-time ke database terpisah

### Skenario 3: Database Rusak
**Situasi:** Kerusakan database terdeteksi  
**Dampak:** Database tidak dapat diakses  
**Metode Pemulihan:** Restore dari backup valid terbaru

### Skenario 4: Kegagalan Hardware
**Situasi:** Kegagalan hardware server  
**Dampak:** Sistem down sepenuhnya  
**Metode Pemulihan:** Restore ke server baru

### Skenario 5: Pemulihan Bencana
**Situasi:** Bencana data center  
**Dampak:** Kehilangan infrastruktur sepenuhnya  
**Metode Pemulihan:** Restore dari backup offsite/Azure

---

## Prosedur Pemulihan Langkah Demi Langkah

### Prosedur 1: Restore Database Lengkap (Pemulihan Penuh)

#### Prasyarat
- Akses ke file backup
- Instance SQL Server berjalan
- Ruang disk yang cukup
- Hak akses sysadmin

#### Langkah-Langkah

**Langkah 1: Verifikasi File Backup**
```sql
-- Daftar file backup yang tersediasedia
RESTORE HEADERONLY 
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak';

-- Verifikasi integritas backup
RESTORE VERIFYONLY 
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH CHECKSUM;
```

**Langkah 2: Tutup Semua Koneksi**
```sql
USE master;
GO

-- Set database ke mode single user
ALTER DATABASE DM_SatuDataITERA_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
```

**Langkah 3: Restore Backup Penuh**
```sql
-- Restore backup penuh dengan NORECOVERY (untuk menerapkan diferensial dan log nanti)
RESTORE DATABASE DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO
```

**Langkah 4: Restore Backup Diferensial Terbaru**
```sql
-- Temukan backup diferensial paling baru
-- Kemudian restore
RESTORE DATABASE DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Diff_20251207_020000.bak'
WITH NORECOVERY, STATS = 10;
GO
```

**Langkah 5: Restore Backup Transaction Log (Secara Berurutan)**
```sql
-- Restore semua backup log sejak backup diferensial
-- PENTING: Terapkan sesuai urutan kronologis

-- Backup log pertamama
RESTORE LOG DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_060000.trn'
WITH NORECOVERY, STATS = 10;

-- Backup log kedua
RESTORE LOG DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_120000.trn'
WITH NORECOVERY, STATS = 10;

-- Backup log ketiga
RESTORE LOG DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_180000.trn'
WITH NORECOVERY, STATS = 10;

-- Backup log terakhir (dengan RECOVERY untuk membawa database online)
RESTORE LOG DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_200000.trn'
WITH RECOVERY, STATS = 10;
GO
```

**Langkah 6: Buat Database Online**
```sql
-- Database sekarang harus online
-- Set kembali ke mode multi-user
ALTER DATABASE DM_SatuDataITERA_DW SET MULTI_USER;
GO

-- Verifikasi status database
SELECT name, state_desc, recovery_model_desc
FROM sys.databases
WHERE name = 'DM_SatuDataITERA_DW';
GO
```

**Langkah 7: Verifikasi Integritas Data**
```sql
USE DM_SatuDataITERA_DW;
GO

-- Jalankan DBCC CHECKDB
DBCC CHECKDB('DM_SatuDataITERA_DW') WITH NO_INFOMSGS;
GO

-- Verifikasi jumlah record
SELECT 'Dim_User' AS TableName, COUNT(*) AS RecordCount FROM Dim_User
UNION ALL
SELECT 'Dim_Dataset', COUNT(*) FROM Dim_Dataset
UNION ALL
SELECT 'Fact_Dataset_Access', COUNT(*) FROM Fact_Dataset_Access
UNION ALL
SELECT 'Fact_Dataset_Quality', COUNT(*) FROM Fact_Dataset_Quality;
GO
```

**Langkah 8: Dokumentasikan Pemulihan**
- Catat waktu penyelesaian pemulihan
- Dokumentasikan backup mana yang digunakan
- Verifikasi data dengan stakeholder
- Perbarui log insiden

---

### Prosedur 2: Pemulihan Point-in-Time

Gunakan ini ketika Anda perlu memulihkan data ke titik waktu tertentu (misalnya, sebelum penghapusan tidak disengaja).

#### Langkah-Langkah

**Langkah 1: Backup Tail-Log (Jika Database Masih Dapat Diakses)**
```sql
-- Backup tail transaction log saat ini
BACKUP LOG DM_SatuDataITERA_DW
TO DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_TailLog.trn'
WITH NORECOVERY;
GO
```

**Langkah 2: Restore ke Point in Time**
```sql
USE master;
GO

-- Restore backup penuh
RESTORE DATABASE DM_SatuDataITERA_DW_PITR
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH NORECOVERY, REPLACE,
MOVE 'DM_SatuDataITERA_DW' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_PITR.mdf',
MOVE 'DM_SatuDataITERA_DW_log' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_PITR_log.ldf';

-- Restore diferensial
RESTORE DATABASE DM_SatuDataITERA_DW_PITR
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Diff_20251207_020000.bak'
WITH NORECOVERY;

-- Restore log sampai waktu tertentu
RESTORE LOG DM_SatuDataITERA_DW_PITR
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_120000.trn'
WITH NORECOVERY;

-- Restore terakhir dengan klausa STOPAT
RESTORE LOG DM_SatuDataITERA_DW_PITR
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_20251207_180000.trn'
WITH RECOVERY, STOPAT = '2025-12-07 14:30:00';
GO
```

**Langkah 3: Bandingkan dan Ekstrak Data**
```sql
-- Bandingkan data antara database asli dan yang dipulihkan
USE DM_SatuDataITERA_DW_PITR;
GO

-- Ekstrak data yang terhapus
SELECT * INTO DM_SatuDataITERA_DW.dbo.Recovered_Data
FROM DM_SatuDataITERA_DW_PITR.dbo.TableName
WHERE [conditions];
GO
```

**Langkah 4: Pembersihan**
```sql
-- Drop database sementara setelah mengekstrak data yang diperlukan
DROP DATABASE DM_SatuDataITERA_DW_PITR;
GO
```

---

### Prosedur 3: Pemulihan Darurat (Kerusakan Database)

#### Langkah-Langkah

**Langkah 1: Evaluasi Kerusakan**
```sql
-- Periksa status database
SELECT name, state_desc FROM sys.databases WHERE name = 'DM_SatuDataITERA_DW';

-- Coba mode emergency
ALTER DATABASE DM_SatuDataITERA_DW SET EMERGENCY;
ALTER DATABASE DM_SatuDataITERA_DW SET SINGLE_USER;

-- Periksa kerusakan
DBCC CHECKDB('DM_SatuDataITERA_DW', REPAIR_ALLOW_DATA_LOSS);
```

**Langkah 2: Jika Dapat Diperbaiki**
```sql
-- Coba perbaikan (PERINGATAN: Dapat menyebabkan kehilangan data)
ALTER DATABASE DM_SatuDataITERA_DW SET EMERGENCY;
ALTER DATABASE DM_SatuDataITERA_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DBCC CHECKDB('DM_SatuDataITERA_DW', REPAIR_ALLOW_DATA_LOSS);
ALTER DATABASE DM_SatuDataITERA_DW SET MULTI_USER;
```

**Langkah 3: Jika Tidak Dapat Diperbaiki**
- Ikuti **Prosedur 1: Restore Database Lengkap**
- Restore dari backup valid terbaru

---

### Prosedur 4: Restore ke Server Baru (Pemulihan Bencana)

#### Langkah-Langkah

**Langkah 1: Persiapkan Server Baru**
- Install SQL Server (versi sama atau lebih baru)
- Buat direktori yang diperlukan
- Konfigurasi pengaturan SQL Server

**Langkah 2: Salin File Backup**
```bash
# Salin file backup ke server baru (Linux)
scp /var/opt/mssql/data/DM_SatuDataITERA_DW_*.bak newserver:/var/opt/mssql/data/
scp /var/opt/mssql/data/DM_SatuDataITERA_DW_*.trn newserver:/var/opt/mssql/data/
```

**Langkah 3: Restore Database**
```sql
-- Restore dengan lokasi file baru
RESTORE DATABASE DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH NORECOVERY,
MOVE 'DM_SatuDataITERA_DW' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW.mdf',
MOVE 'DM_SatuDataITERA_DW_log' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_log.ldf';

-- Lanjutkan dengan restore diferensial dan log...
```

**Langkah 4: Konfigurasi Ulang**
- Buat ulang login dan user
- Restore pengaturan keamanan
- Uji koneksi
- Perbarui connection string dalam aplikasi

---

## Pemulihan Point-in-Time

### Kapan Menggunakan
- Modifikasi atau penghapusan data tidak disengaja
- Perlu memulihkan ke sebelum insiden tertentu
- Persyaratan audit atau kepatuhan

### Persyaratan
- Model pemulihan FULL diaktifkan
- Chain backup lengkap tersedia
- Backup transaction log

### Jendela Waktu
Dapat memulihkan ke titik waktu mana pun dalam retensi backup transaction log (7 hari).

---

## Pemulihan Bencana

### Strategi Backup Offsite

#### Backup Azure Blob Storage
```sql
-- Konfigurasi kredensial Azure (setup sekali)
CREATE CREDENTIAL [AzureStorageCredential]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'your_sas_token_here';
GO

-- Restore dari Azure
RESTORE DATABASE DM_SatuDataITERA_DW
FROM URL = 'https://yourstorageaccount.blob.core.windows.net/sqlbackups/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH CREDENTIAL = 'AzureStorageCredential',
MOVE 'DM_SatuDataITERA_DW' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW.mdf',
MOVE 'DM_SatuDataITERA_DW_log' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_log.ldf';
GO
```

### Setup Situs DR
1. Pertahankan server standby di lokasi DR
2. Salin backup secara teratur ke situs DR
3. Uji prosedur DR setiap kuartal
4. Dokumentasikan konfigurasi jaringan
5. Pertahankan runbook yang diperbarui

---

## Pengujian dan Validasi

### Tes Pemulihan Bulanan

**Prosedur Tes:**
1. Restore ke server tes
2. Verifikasi integritas data
3. Jalankan query sampel
4. Dokumentasikan hasil
5. Laporkan masalah apa pun

### Script Tes
```sql
-- Script Tes Pemulihan Bulanan
USE master;
GO

-- Restore ke database tes
RESTORE DATABASE DM_SatuDataITERA_DW_TEST
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak'
WITH RECOVERY, REPLACE,
MOVE 'DM_SatuDataITERA_DW' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_TEST.mdf',
MOVE 'DM_SatuDataITERA_DW_log' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_TEST_log.ldf';
GO

-- Query verifikasi
USE DM_SatuDataITERA_DW_TEST;
GO

SELECT 'Test Date' = GETDATE();
SELECT 'Record Counts' AS Test;
SELECT 'Dim_User' AS Table, COUNT(*) AS Records FROM Dim_User;
SELECT 'Fact_Dataset_Access' AS Table, COUNT(*) AS Records FROM Fact_Dataset_Access;

-- Pembersihan
USE master;
DROP DATABASE DM_SatuDataITERA_DW_TEST;
GO
```

---

## Pemecahan Masalah

### Masalah Umum dan Solusinya

#### Masalah 1: Error "Database in Use"
**Solusi:**
```sql
ALTER DATABASE DM_SatuDataITERA_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- Kemudian coba restore lagi
```

#### Masalah 2: Ruang Disk Tidak Cukup
**Solusi:**
- Bebaskan ruang disk
- Gunakan drive alternatif
- Gunakan WITH MOVE untuk menentukan lokasi berbeda

#### Masalah 3: Kerusakan File Backup
**Error:** `Backup set is corrupted`
**Solusi:**
- Coba backup sebelumnya
- Restore VERIFYONLY terlebih dahulu
- Periksa integritas file backup

#### Masalah 4: Chain LSN Terputus
**Error:** `The log in this backup set begins at LSN...`
**Solusi:**
- Identifikasi backup log yang hilang
- Restore log sesuai urutan yang benar
- Periksa riwayat backup

#### Masalah 5: Ketidakcocokan Versi
**Error:** `Cannot restore to different version`
**Solusi:**
- Upgrade SQL Server agar sesuai versi backup
- Restore ke versi yang kompatibel

---

## Checklist Pemulihan

### Pra-Pemulihan
- [ ] Identifikasi file backup yang diperlukan
- [ ] Verifikasi integritas backup
- [ ] Pastikan ruang disk cukup
- [ ] Beritahu stakeholder
- [ ] Dokumentasikan insiden

### Selama Pemulihan
- [ ] Tutup semua koneksi
- [ ] Restore backup penuh
- [ ] Restore backup diferensial
- [ ] Restore backup log secara berurutan
- [ ] Buat database online
- [ ] Jalankan pemeriksaan integritas

### Pasca-Pemulihan
- [ ] Verifikasi kelengkapan data
- [ ] Uji konektivitas aplikasi
- [ ] Jalankan query sampel
- [ ] Beritahu pengguna
- [ ] Dokumentasikan detail pemulihan
- [ ] Perbarui log insiden
- [ ] Lakukan review post-mortem

---

## Informasi Kontak

### Kontak Darurat

| Peran | Nama | Telepon | Email | Ketersediaan |
|-------|------|---------|-------|--------------|--||
| Administrator Database | [Nama] | +62-xxx-xxxx | dba@university.edu | 24/7 |
| Manajer IT | [Nama] | +62-xxx-xxxx | itmanager@university.edu | Jam Kerja |
| Administrator Backup | [Nama] | +62-xxx-xxxx | backup@university.edu | Jam Kerja |
| Teknisi On-Call | Rotasi | +62-xxx-xxxx | oncall@university.edu | 24/7 |

### Jalur Eskalasi
1. **Level 1:** Administrator Database (DBA)
2. **Level 2:** Manajer IT
3. **Level 3:** Direktur IT
4. **Level 4:** CIO

### Dukungan Vendor
- **Dukungan Microsoft SQL Server:** 1-800-xxx-xxxx
- **Dukungan Azure:** support.azure.com
- **Dukungan Software Backup:** [Jika berlaku]

---

## Riwayat Revisi Dokumen

| Versi | Tanggal | Penulis | Perubahan |
|-------|---------|---------|-----------|---||
| 1.0 | 2025-12-01 | [Nama Anda] | Pembuatan dokumen awal |

---

## Lampiran A: Perintah Referensi Cepat

### Periksa Riwayat Backup
```sql
SELECT TOP 20
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'DM_SatuDataITERA_DW'
ORDER BY bs.backup_start_date DESC;
```

### Daftar Konten File Backup
```sql
RESTORE HEADERONLY FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak';
RESTORE FILELISTONLY FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_20251201_020000.bak';
```

### Periksa Status Database
```sql
SELECT name, state_desc, recovery_model_desc, 
       user_access_desc, is_read_only
FROM sys.databases
WHERE name = 'DM_SatuDataITERA_DW';
```

---

**Akhir Dokumen**

*Dokumen ini harus ditinjau dan diperbarui setiap kuartal atau setelah perubahan infrastruktur yang signifikan.*
