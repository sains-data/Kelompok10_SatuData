/* File: 06_Create_Staging.sql
   Deskripsi: Membuat Tabel Staging untuk menampung data mentah
*/

USE DM_SatuDataITERA_DW;
GO

-- Membuat Schema stg
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg')
END
GO

-- Staging untuk Dataset (Sumber: Database Portal)
IF OBJECT_ID('stg.Dataset', 'U') IS NOT NULL DROP TABLE stg.Dataset;
CREATE TABLE stg.Dataset (
    Dataset_ID INT,              -- Natural Key
    Nama_Dataset VARCHAR(255),
    Deskripsi VARCHAR(MAX),
    Format VARCHAR(50),
    Kategori VARCHAR(100),
    Tingkat_Akses VARCHAR(50),
    Frekuensi_Update VARCHAR(50),
    Status VARCHAR(50),
    Load_Date DATETIME DEFAULT GETDATE()
);
GO

-- Staging untuk User (Sumber: Database User/SIAKAD)
IF OBJECT_ID('stg.User', 'U') IS NOT NULL DROP TABLE stg.[User];
CREATE TABLE stg.[User] (
    User_ID INT,                 -- Natural Key
    Username VARCHAR(100),
    Tipe_User VARCHAR(50),
    Unit_Organisasi VARCHAR(100),
    Status VARCHAR(20),
    Tanggal_Registrasi DATE,
    Load_Date DATETIME DEFAULT GETDATE()
);
GO

-- Staging untuk Log Akses (Sumber: Log Server/App)
IF OBJECT_ID('stg.Access_Log', 'U') IS NOT NULL DROP TABLE stg.Access_Log;
CREATE TABLE stg.Access_Log (
    Log_ID INT,
    Dataset_ID INT,
    User_ID INT,
    Waktu_Akses DATETIME,        -- Tanggal & Jam
    Tipe_Akses VARCHAR(50),      -- View/Download
    File_Size BIGINT,
    Response_Time INT,
    Status_Akses VARCHAR(20),    -- Success/Failed
    Load_Date DATETIME DEFAULT GETDATE()
);
GO

-- Staging untuk Log Kualitas (Sumber: Tools Data Quality)
IF OBJECT_ID('stg.Quality_Log', 'U') IS NOT NULL DROP TABLE stg.Quality_Log;
CREATE TABLE stg.Quality_Log (
    Log_ID INT,
    Dataset_ID INT,               -- Natural Key Dataset
    Tanggal_Cek DATE,             -- Tanggal pengecekan
    Completeness_Score DECIMAL(5,2),
    Accuracy_Score DECIMAL(5,2),
    Timeliness_Score DECIMAL(5,2),
    Consistency_Score DECIMAL(5,2),
    Overall_Quality_Score DECIMAL(5,2),
    Missing_Values INT,
    Duplicate_Records INT,
    Total_Records INT,
    Load_Date DATETIME DEFAULT GETDATE()
);
GO

-- Staging untuk Log Pencarian (Sumber: Log Aplikasi Portal)
IF OBJECT_ID('stg.Search_Log', 'U') IS NOT NULL DROP TABLE stg.Search_Log;
CREATE TABLE stg.Search_Log (
    Log_ID INT,
    User_ID INT,                  -- Bisa NULL jika user anonim
    Waktu_Search DATETIME,
    Keyword_Pencarian VARCHAR(MAX),
    Jumlah_Hasil INT,
    Is_Clicked INT,               -- 1 = Klik, 0 = Tidak
    Durasi_Search_MS INT,
    Load_Date DATETIME DEFAULT GETDATE()
);
GO

PRINT 'Tabel Staging berhasil dibuat.';