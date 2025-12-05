# Prosedur Pemulihan - Data Warehouse DM_SatuDataITERA_DW

---

## 1. Gambaran Umum

Dokumen ini menyediakan prosedur pemulihan untuk data warehouse **DM_SatuDataITERA_DW**. Prosedur backup dibuat menggunakan script `SQL-Scripts/12_Backup.sql`.

### Tujuan Pemulihan

| Metrik | Target | Keterangan |
|--------|--------|------------|
| **RTO** (Recovery Time Objective) | 4 jam | Maksimal downtime |
| **RPO** (Recovery Point Objective) | 6 jam | Maksimal kehilangan data |

---

## 2. Strategi Backup

### Jadwal Backup

| Tipe Backup | Frekuensi | Waktu | Retensi | Stored Procedure |
|-------------|-----------|-------|---------|------------------|
| **Full** | Mingguan | Minggu 02:00 | 30 hari | `sp_FullBackup_SatuDataITERA` |
| **Differential** | Harian | Sen-Sab 02:00 | 14 hari | `sp_DifferentialBackup_SatuDataITERA` |
| **Transaction Log** | Setiap 6 jam | 00:00, 06:00, 12:00, 18:00 | 7 hari | `sp_LogBackup_SatuDataITERA` |

### Konvensi Penamaan File

| Tipe | Format Nama File |
|------|------------------|
| Full | `DM_SatuDataITERA_DW_Full_YYYYMMDD_HHMMSS.bak` |
| Differential | `DM_SatuDataITERA_DW_Diff_YYYYMMDD_HHMMSS.bak` |
| Log | `DM_SatuDataITERA_DW_Log_YYYYMMDD_HHMMSS.trn` |

**Lokasi Backup:** `/var/opt/mssql/data/`

---

## 3. Skenario Pemulihan

| Skenario | Penyebab | Metode Restore |
|----------|----------|----------------|
| Database hilang/rusak total | File corrupt, hardware failure | Full + Diff + Log |
| Penghapusan data tidak sengaja | Human error | Point-in-Time Recovery |
| Disaster Recovery | Bencana data center | Restore ke server baru |

---

## 4. Prosedur Restore Utama

### Langkah 1: Verifikasi Backup
```sql
-- Cek integritas backup
RESTORE VERIFYONLY 
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_YYYYMMDD_HHMMSS.bak'
WITH CHECKSUM;
```

### Langkah 2: Set Database ke Single User
```sql
USE master;
ALTER DATABASE DM_SatuDataITERA_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
```

### Langkah 3: Restore Full Backup
```sql
RESTORE DATABASE DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_YYYYMMDD_HHMMSS.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
```

### Langkah 4: Restore Differential (Opsional)
```sql
RESTORE DATABASE DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Diff_YYYYMMDD_HHMMSS.bak'
WITH NORECOVERY, STATS = 10;
```

### Langkah 5: Restore Transaction Logs (Berurutan)
```sql
-- Restore semua log secara kronologis, log terakhir dengan RECOVERY
RESTORE LOG DM_SatuDataITERA_DW
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_YYYYMMDD_HHMMSS.trn'
WITH RECOVERY, STATS = 10;  -- RECOVERY hanya di log terakhir
```

### Langkah 6: Kembalikan ke Multi User
```sql
ALTER DATABASE DM_SatuDataITERA_DW SET MULTI_USER;
```

### Langkah 7: Verifikasi
```sql
-- Cek status database
SELECT name, state_desc FROM sys.databases WHERE name = 'DM_SatuDataITERA_DW';

-- Cek integritas
DBCC CHECKDB('DM_SatuDataITERA_DW') WITH NO_INFOMSGS;

-- Cek jumlah record
SELECT 'Dim_User' AS Tabel, COUNT(*) AS Jumlah FROM Dim_User
UNION ALL SELECT 'Dim_Dataset', COUNT(*) FROM Dim_Dataset
UNION ALL SELECT 'Fact_Dataset_Access', COUNT(*) FROM Fact_Dataset_Access;
```

---

## 5. Point-in-Time Recovery

Untuk memulihkan data ke waktu tertentu (misal: sebelum penghapusan tidak sengaja):

```sql
-- Restore ke database terpisah dengan STOPAT
RESTORE DATABASE DM_SatuDataITERA_DW_RECOVERY
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Full_YYYYMMDD.bak'
WITH NORECOVERY, REPLACE,
MOVE 'DM_SatuDataITERA_DW' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_RECOVERY.mdf',
MOVE 'DM_SatuDataITERA_DW_log' TO '/var/opt/mssql/data/DM_SatuDataITERA_DW_RECOVERY_log.ldf';

-- Restore log sampai waktu tertentu
RESTORE LOG DM_SatuDataITERA_DW_RECOVERY
FROM DISK = '/var/opt/mssql/data/DM_SatuDataITERA_DW_Log_YYYYMMDD.trn'
WITH RECOVERY, STOPAT = '2025-12-05 14:30:00';
```

---

## 6. Checklist Pemulihan

### Pra-Pemulihan
- [ ] Identifikasi file backup yang diperlukan
- [ ] Verifikasi integritas backup (`RESTORE VERIFYONLY`)
- [ ] Pastikan ruang disk cukup
- [ ] Beritahu stakeholder

### Selama Pemulihan
- [ ] Set database ke SINGLE_USER
- [ ] Restore Full → Diff → Log (berurutan)
- [ ] Jalankan DBCC CHECKDB

### Pasca-Pemulihan
- [ ] Verifikasi kelengkapan data
- [ ] Set database ke MULTI_USER
- [ ] Uji konektivitas aplikasi/dashboard
- [ ] Dokumentasikan detail pemulihan

---

## 7. Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Error "Database in Use" | `ALTER DATABASE ... SET SINGLE_USER WITH ROLLBACK IMMEDIATE` |
| Ruang disk tidak cukup | Gunakan `WITH MOVE` ke drive lain |
| Backup corrupt | Gunakan backup sebelumnya |
| LSN chain terputus | Restore log sesuai urutan kronologis |
| Versi tidak cocok | Upgrade SQL Server ke versi ≥ backup |

---

## 8. SQL Agent Jobs (Referensi)

Jobs yang dibuat di `12_Backup.sql`:

| Job Name | Schedule | Fungsi |
|----------|----------|--------|
| `SatuData_Backup_Full_Weekly` | Minggu 02:00 | Full backup mingguan |
| `SatuData_Backup_Diff_Daily` | Sen-Sab 02:00 | Differential backup harian |
| `SatuData_Backup_Log_6Hourly` | Setiap 6 jam | Transaction log backup |

---

**Referensi Script:** `SQL-Scripts/12_Backup.sql`
