/* File: 09_Test_Queries_FINAL.sql
   Deskripsi: Performance Test 
*/

USE DM_SatuDataITERA_DW;
GO

SET STATISTICS TIME ON;  -- Untuk mengukur waktu
SET STATISTICS IO ON;    -- Untuk melihat jumlah pembacaan data
GO

PRINT 'Memulai performance testing';
PRINT '';


-- SIMPLE AGGREGATION
-- Target: < 1 detik
-- Deskripsi: Menghitung total tanpa join berat.

PRINT 'RUNNING: Simple Aggregation...';

SELECT 
    SUM(Jumlah_Akses) AS Total_Akses,
    SUM(Jumlah_Download) AS Total_Download,
    AVG(Response_Time_MS) AS Rata_Rata_Respon
FROM dbo.Fact_Dataset_Access;
GO


-- COMPLEX JOIN
-- Target: < 3 detik
-- Deskripsi: Join 4 Tabel (Fact + Time + User + Dataset)

PRINT 'RUNNING: Complex Join...';

SELECT TOP 100
    d.Nama_Dataset,
    u.Unit_Organisasi,
    t.Tahun,
    SUM(f.Jumlah_Akses) AS Total_Akses
FROM dbo.Fact_Dataset_Access f
INNER JOIN dbo.Dim_Dataset d ON f.Dataset_SK = d.Dataset_SK
INNER JOIN dbo.Dim_User u ON f.User_SK = u.User_SK
INNER JOIN dbo.Dim_Time t ON f.Time_SK = t.Time_SK
WHERE t.Tahun = 2024
GROUP BY d.Nama_Dataset, u.Unit_Organisasi, t.Tahun
ORDER BY Total_Akses DESC;
GO


-- DRILL-DOWN ANALYSIS
-- Target: < 2 detik
-- Deskripsi: Analisis mendalam (Filter spesifik kategori & waktu)

PRINT 'RUNNING: Drill-down Analysis...';

SELECT 
    c.Nama_Kategori,
    d.Nama_Dataset,
    t.Nama_Bulan,
    COUNT(*) AS Jumlah_Transaksi
FROM dbo.Fact_Dataset_Access f
INNER JOIN dbo.Dim_Category c ON f.Category_SK = c.Category_SK
INNER JOIN dbo.Dim_Dataset d ON f.Dataset_SK = d.Dataset_SK
INNER JOIN dbo.Dim_Time t ON f.Time_SK = t.Time_SK
WHERE c.Nama_Kategori = 'Akademik'  -- Drill-down ke kategori Akademik
  AND t.Tahun = 2024                -- Drill-down ke Tahun 2024
GROUP BY c.Nama_Kategori, d.Nama_Dataset, t.Nama_Bulan;
GO


-- FULL SCAN REPORT
-- Target: < 10 detik
-- Deskripsi: Laporan lengkap seluruh data (Export simulation)

PRINT 'RUNNING: Full Scan Report...';

SELECT 
    t.Date,
    u.Username,
    d.Nama_Dataset,
    CASE 
        WHEN f.Jumlah_Download = 1 THEN 'Download'
        WHEN f.Jumlah_View = 1 THEN 'View'
        ELSE 'Other' 
    END AS Tipe_Akses,
    f.Response_Time_MS
FROM dbo.Fact_Dataset_Access f
INNER JOIN dbo.Dim_Time t ON f.Time_SK = t.Time_SK
INNER JOIN dbo.Dim_User u ON f.User_SK = u.User_SK
INNER JOIN dbo.Dim_Dataset d ON f.Dataset_SK = d.Dataset_SK
ORDER BY t.Date DESC; 
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
PRINT 'performance testing selesai';