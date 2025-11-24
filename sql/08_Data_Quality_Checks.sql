/* File: 08_Data_Quality_Checks.sql
   Deskripsi: Script untuk menguji kualitas data (Completeness, Consistency, Accuracy, Uniqueness)
*/

USE DM_SatuDataITERA_DW;
GO

PRINT 'STARTING DATA QUALITY CHECKS';


-- 1. COMPLETENESS CHECK (Cek NULL Values)
-- Memastikan kolom-kolom kritis tidak boleh kosong
PRINT '>>> 1. Checking Completeness (NULL Values)...';

-- Cek apakah ada User tanpa Username
SELECT 'Dim_User' AS TableName, User_ID, 'Username is NULL' AS Issue
FROM dbo.Dim_User
WHERE Username IS NULL;

-- Cek apakah ada Dataset tanpa Nama
SELECT 'Dim_Dataset' AS TableName, Dataset_ID, 'Nama_Dataset is NULL' AS Issue
FROM dbo.Dim_Dataset
WHERE Nama_Dataset IS NULL;


-- 2. CONSISTENCY CHECK (Referential Integrity / Orphan Records)
-- Memastikan data di tabel fakta punya induk di tabel dimensi
PRINT '>>> 2. Checking Consistency (Orphan Records)...';

-- Cek Fact Access yang Dataset-nya tidak dikenal
SELECT f.Access_SK, f.Dataset_SK, 'Orphan Dataset in Fact Access' AS Issue
FROM dbo.Fact_Dataset_Access f
LEFT JOIN dbo.Dim_Dataset d ON f.Dataset_SK = d.Dataset_SK
WHERE d.Dataset_SK IS NULL;

-- Cek Fact Quality yang Dataset-nya tidak dikenal
SELECT f.Quality_SK, f.Dataset_SK, 'Orphan Dataset in Fact Quality' AS Issue
FROM dbo.Fact_Dataset_Quality f
LEFT JOIN dbo.Dim_Dataset d ON f.Dataset_SK = d.Dataset_SK
WHERE d.Dataset_SK IS NULL;


-- 3. ACCURACY CHECK (Valid Ranges)
-- Memastikan angka-angka masuk akal secara logika bisnis
PRINT '>>> 3. Checking Accuracy (Valid Ranges)...';

-- Cek Skor Kualitas harus 0-100
SELECT Quality_SK, Overall_Quality_Score, 'Score Out of Range' AS Issue
FROM dbo.Fact_Dataset_Quality
WHERE Overall_Quality_Score < 0 OR Overall_Quality_Score > 100;

-- Cek File Size tidak boleh negatif
SELECT Access_SK, File_Size_Downloaded, 'Negative File Size' AS Issue
FROM dbo.Fact_Dataset_Access
WHERE File_Size_Downloaded < 0;

-- Cek Tanggal Registrasi User tidak boleh di masa depan
SELECT User_SK, Tanggal_Registrasi, 'Future Registration Date' AS Issue
FROM dbo.Dim_User
WHERE Tanggal_Registrasi > GETDATE();


-- 4. UNIQUENESS CHECK (Duplikasi Data)
-- Memastikan tidak ada data ganda yang aneh
PRINT '>>> 4. Checking Uniqueness (Duplicates)...';

-- Cek apakah ada User ID yang ganda di tabel dimensi
SELECT User_ID, COUNT(*) AS Duplicate_Count
FROM dbo.Dim_User
GROUP BY User_ID
HAVING COUNT(*) > 1;

-- Cek SCD Type 2: Tidak boleh ada 2 record aktif (Is_Current=1) untuk Dataset ID yang sama
SELECT Dataset_ID, COUNT(*) AS Active_Count
FROM dbo.Dim_Dataset
WHERE Is_Current = 1
GROUP BY Dataset_ID
HAVING COUNT(*) > 1;

PRINT 'DATA QUALITY Selesai';