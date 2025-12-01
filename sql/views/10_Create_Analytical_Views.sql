/* File: 09_Create_Analytical_Views.sql
   Deskripsi: Membuat View untuk Dashboard
*/

USE DM_SatuDataITERA_DW;
GO

-- VIEW 1: Executive Governance Dashboard
-- Tujuan: Memantau keaktifan Unit/Fakultas dalam mempublikasikan data dan kualitasnya.
-- Target User: Rektorat, Kepala UPT TIK
CREATE OR ALTER VIEW dbo.vw_Executive_Governance AS
SELECT 
    dt.Tahun,
    dt.Kuartal,
    dt.Nama_Bulan,
    dt.Bulan,  -- Untuk sorting yang benar
    do.Nama_Unit,
    do.Tipe_Unit,
    
    -- Metrik Utama
    SUM(fim.Total_Dataset_Published) AS Total_Dataset_Published,
    SUM(fim.Total_Downloads) AS Total_Unduhan_Unit,
    ROUND(AVG(fim.Avg_Quality_Score), 2) AS Rata_Rata_Skor_Kualitas,
    SUM(fim.Total_Active_Users) AS Total_User_Aktif,
    
    -- Status Kualitas (untuk visual indicator)
    CASE 
        WHEN AVG(fim.Avg_Quality_Score) >= 90 THEN 'Excellent'
        WHEN AVG(fim.Avg_Quality_Score) >= 80 THEN 'Good'
        WHEN AVG(fim.Avg_Quality_Score) >= 70 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS Status_Kualitas,
    
    -- Ranking unit berdasarkan downloads (untuk leaderboard)
    RANK() OVER (PARTITION BY dt.Tahun, dt.Kuartal ORDER BY SUM(fim.Total_Downloads) DESC) AS Ranking_Download
    
FROM dbo.Fact_Institution_Metrics fim WITH (NOLOCK)
JOIN dbo.Dim_Time dt ON fim.Time_SK = dt.Time_SK
JOIN dbo.Dim_Organization do ON fim.Organization_SK = do.Organization_SK
WHERE fim.Organization_SK <> -1  -- Filter Unknown
GROUP BY dt.Tahun, dt.Kuartal, dt.Nama_Bulan, dt.Bulan, do.Nama_Unit, do.Tipe_Unit;
GO

-- VIEW 2: Dataset Popularity & Usage
-- Tujuan: Dataset mana yang paling "Laris" dan siapa penggunanya.
-- Target User: Data Steward, Admin Satu Data
CREATE OR ALTER VIEW dbo.vw_Dataset_Popularity AS
SELECT 
    dd.Nama_Dataset,
    dd.Kategori_Nama,
    dd.Format,
    dd.Tingkat_Akses,
    dd.Status_Dataset,
    dt.Nama_Bulan,
    dt.Bulan,
    dt.Tahun,
    
    -- Metrik Engagement
    SUM(fa.Jumlah_View) AS Total_Views,
    SUM(fa.Jumlah_Download) AS Total_Downloads,
    SUM(fa.Jumlah_API_Call) AS Total_API_Calls,
    CAST(SUM(fa.File_Size_Downloaded) / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS Total_Traffic_MB,
    COUNT(DISTINCT fa.User_SK) AS Unique_Users,
    
    -- Conversion Rate (View to Download)
    CASE 
        WHEN SUM(fa.Jumlah_View) > 0 
        THEN CAST(SUM(fa.Jumlah_Download) * 100.0 / SUM(fa.Jumlah_View) AS DECIMAL(5,2))
        ELSE 0 
    END AS Download_Rate_Percent,
    
    -- Performance Metrics
    AVG(fa.Response_Time_MS) AS Avg_Response_Time_MS,
    SUM(CASE WHEN fa.Success_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Success_Rate_Percent,
    
    -- Ranking per kategori
    RANK() OVER (PARTITION BY dd.Kategori_Nama, dt.Tahun ORDER BY SUM(fa.Jumlah_Download) DESC) AS Ranking_In_Category
    
FROM dbo.Fact_Dataset_Access fa WITH (NOLOCK)
JOIN dbo.Dim_Dataset dd ON fa.Dataset_SK = dd.Dataset_SK
JOIN dbo.Dim_Time dt ON fa.Time_SK = dt.Time_SK
WHERE dd.Is_Current = 1 
  AND dd.Dataset_SK <> -1  -- Filter Unknown
  AND fa.User_SK <> -1     -- Filter Unknown users
GROUP BY dd.Nama_Dataset, dd.Kategori_Nama, dd.Format, dd.Tingkat_Akses, dd.Status_Dataset,
         dt.Nama_Bulan, dt.Bulan, dt.Tahun;
GO

-- VIEW 3: Search & Demand Analysis
-- Tujuan: Apa yang dicari pengguna tapi tidak ditemukan? (Insight untuk pengadaan data baru)
-- Target User: Tim Konten/Perencanaan
CREATE OR ALTER VIEW dbo.vw_Search_Analysis AS
SELECT 
    LEFT(CAST(fsq.Query_Text AS VARCHAR(500)), 500) AS Kata_Kunci,
    dt.Tahun,
    dt.Kuartal,
    dt.Nama_Bulan,
    dt.Bulan,
    
    -- Search Metrics
    SUM(fsq.Jumlah_Pencarian) AS Total_Pencarian,
    SUM(fsq.Jumlah_Hasil) AS Total_Hasil_Ditemukan,
    SUM(CASE WHEN fsq.Jumlah_Hasil = 0 THEN 1 ELSE 0 END) AS Pencarian_Nihil,
    SUM(CASE WHEN fsq.Click_Through_Flag = 1 THEN 1 ELSE 0 END) AS Total_Clicked,
    
    -- Engagement Rate
    CASE 
        WHEN SUM(fsq.Jumlah_Pencarian) > 0
        THEN CAST(SUM(CASE WHEN fsq.Click_Through_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fsq.Jumlah_Pencarian) AS DECIMAL(5,2))
        ELSE 0
    END AS Click_Through_Rate_Percent,
    
    -- Performance
    ROUND(AVG(fsq.Search_Time_MS), 0) AS Avg_Response_Time_MS,
    
    -- Flag prioritas untuk content gap
    CASE 
        WHEN SUM(CASE WHEN fsq.Jumlah_Hasil = 0 THEN 1 ELSE 0 END) > 10 THEN 'High Priority - Many Failed Searches'
        WHEN SUM(CASE WHEN fsq.Jumlah_Hasil = 0 THEN 1 ELSE 0 END) > 5 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS Content_Gap_Priority,
    
    -- Ranking keyword paling banyak dicari
    RANK() OVER (PARTITION BY dt.Tahun ORDER BY SUM(fsq.Jumlah_Pencarian) DESC) AS Popularity_Rank
    
FROM dbo.Fact_Search_Query fsq WITH (NOLOCK)
JOIN dbo.Dim_Time dt ON fsq.Time_SK = dt.Time_SK
WHERE fsq.User_SK <> -1 OR fsq.User_SK IS NULL  -- Termasuk anonymous search
GROUP BY LEFT(CAST(fsq.Query_Text AS VARCHAR(500)), 500), dt.Tahun, dt.Kuartal, dt.Nama_Bulan, dt.Bulan; 
GO

-- VIEW 4: User Activity Profile
-- Tujuan: Profil aktivitas user untuk engagement analysis
-- Target User: Admin, Data Governance Team
CREATE OR ALTER VIEW dbo.vw_User_Activity AS
SELECT 
    du.Username,
    du.Tipe_User,
    du.Status AS User_Status,
    do.Nama_Unit,
    do.Tipe_Unit,
    dt.Tahun,
    dt.Kuartal,
    dt.Nama_Bulan,
    dt.Bulan,
    
    -- Activity Metrics
    COUNT(DISTINCT fa.Dataset_SK) AS Unique_Datasets_Accessed,
    COUNT(DISTINCT dc.Category_SK) AS Unique_Categories_Accessed,
    SUM(fa.Jumlah_Download) AS Total_Downloads,
    SUM(fa.Jumlah_View) AS Total_Views,
    SUM(fa.Jumlah_API_Call) AS Total_API_Calls,
    COUNT(*) AS Total_Akses,
    
    -- Engagement Pattern
    CAST(SUM(fa.File_Size_Downloaded) / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS Total_Data_Downloaded_MB,
    ROUND(AVG(fa.Response_Time_MS), 0) AS Avg_Response_Time_MS,
    SUM(CASE WHEN fa.Success_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Success_Rate_Percent,
    
    -- User Segmentation (lebih detail)
    CASE 
        WHEN SUM(fa.Jumlah_Download) >= 100 THEN 'Power User'
        WHEN SUM(fa.Jumlah_Download) >= 50 THEN 'Heavy User'
        WHEN SUM(fa.Jumlah_Download) >= 20 THEN 'Active User'
        WHEN SUM(fa.Jumlah_Download) >= 5 THEN 'Regular User'
        ELSE 'Casual User'
    END AS User_Segment,
    
    -- Behavioral Flags
    CASE WHEN SUM(fa.Jumlah_API_Call) > 0 THEN 'API User' ELSE 'Manual User' END AS Access_Type,
    
    -- Ranking user dalam unit
    RANK() OVER (PARTITION BY do.Nama_Unit, dt.Tahun ORDER BY SUM(fa.Jumlah_Download) DESC) AS Ranking_In_Unit
    
FROM dbo.Fact_Dataset_Access fa WITH (NOLOCK)
JOIN dbo.Dim_User du ON fa.User_SK = du.User_SK
JOIN dbo.Dim_Organization do ON fa.Organization_SK = do.Organization_SK
JOIN dbo.Dim_Time dt ON fa.Time_SK = dt.Time_SK
JOIN dbo.Dim_Category dc ON fa.Category_SK = dc.Category_SK
WHERE fa.User_SK <> -1           -- Filter Unknown
  AND fa.Organization_SK <> -1   -- Filter Unknown
  AND fa.Dataset_SK <> -1        -- Filter Unknown
GROUP BY du.Username, du.Tipe_User, du.Status, do.Nama_Unit, do.Tipe_Unit,
         dt.Tahun, dt.Kuartal, dt.Nama_Bulan, dt.Bulan;
GO

PRINT 'Analytical Views berhasil dibuat.';