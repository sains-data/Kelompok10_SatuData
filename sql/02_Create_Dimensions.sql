/* File: 02_Create_Dimensions.sql
   Deskripsi: Membuat Tabel Dimensi dengan Surrogate Keys (kunci buatan) dan SCD
*/

USE DM_SatuDataITERA_DW;
GO

-- 1. Dim_Time 
CREATE TABLE dbo.Dim_Time (
    Time_SK INT PRIMARY KEY,              -- Format: YYYYMMDD (misal 20241117)
    Date DATE NOT NULL,
    Tahun INT NOT NULL,
    Bulan INT NOT NULL,
    Nama_Bulan VARCHAR(20) NOT NULL,
    Minggu INT NOT NULL,
    Hari INT NOT NULL,
    Kuartal INT NOT NULL,
    Nama_Hari VARCHAR(20) NOT NULL,
    Hari_Kerja_Flag BIT NOT NULL,         -- 0 atau 1
    Tahun_Akademik VARCHAR(10),           -- Contoh: 2023/2024
    Semester VARCHAR(10)                  -- Ganjil/Genap
);
GO

-- 2. Dim_Category
CREATE TABLE dbo.Dim_Category (
    Category_SK INT IDENTITY(1,1) PRIMARY KEY,
    Kategori_ID INT NOT NULL,             -- Natural Key
    Nama_Kategori VARCHAR(100) NOT NULL,
    Parent_Kategori VARCHAR(100),         -- Hierarki kategori
    Level INT,                            -- Level hierarki
    Deskripsi TEXT                        -- Deskripsi kategori
);
GO

-- 3. Dim_Organization
CREATE TABLE dbo.Dim_Organization (
    Organization_SK INT IDENTITY(1,1) PRIMARY KEY,
    Unit_ID INT NOT NULL,                 -- Natural Key
    Nama_Unit VARCHAR(100) NOT NULL,
    Tipe_Unit VARCHAR(50),                -- Fakultas/Prodi/Unit_Kerja
    Parent_Unit VARCHAR(100),             -- Hierarki unit
    Level INT                             -- Level hierarki
);
GO

-- 4. Dim_Data_Source
CREATE TABLE dbo.Dim_Data_Source (
    Data_Source_SK INT IDENTITY(1,1) PRIMARY KEY,
    Data_Source_ID INT NOT NULL,          -- Natural Key
    Nama_Sumber VARCHAR(100),             -- SIAKAD/SIMKEU/dll
    Tipe_Sumber VARCHAR(50),              -- Database/API/File
    Unit_Pengelola VARCHAR(100),
    Status VARCHAR(20)
);
GO

-- 5. Dim_User (SCD Type 1)
-- Perubahan data user akan menimpa data lama (overwrite)
CREATE TABLE dbo.Dim_User (
    User_SK INT IDENTITY(1,1) PRIMARY KEY,
    User_ID INT NOT NULL,                 -- Natural Key
    Username VARCHAR(50),
    Tipe_User VARCHAR(50),                -- Mahasiswa/Dosen/Publik/Admin
    Unit_Organisasi VARCHAR(100),
    Status VARCHAR(20),
    Tanggal_Registrasi DATE
);
GO

-- 6. Dim_Dataset (SCD Type 2) 
-- Perubahan metadata akan membuat baris baru (history tracking)
CREATE TABLE dbo.Dim_Dataset (
    Dataset_SK INT IDENTITY(1,1) PRIMARY KEY,
    Dataset_ID INT NOT NULL,              -- Natural Key
    Nama_Dataset VARCHAR(200),
    Deskripsi TEXT,
    Format VARCHAR(50),                   -- CSV/JSON/Excel/API
    Kategori_Nama VARCHAR(100),
    Tingkat_Akses VARCHAR(20),            -- Public/Internal/Restricted
    Frekuensi_Update VARCHAR(50),
    Status_Dataset VARCHAR(20),           -- Active/Deprecated/Archived
    
    -- Kolom Khusus SCD Type 2
    Effective_Date DATE NOT NULL,         -- Tanggal mulai berlaku
    End_Date DATE,                        -- Tanggal berakhir (bernilai NULL jika aktif)
    Is_Current BIT DEFAULT 1              -- 1 = Record Aktif, 0 = Historis
);
GO

PRINT 'Tabel Dimensi berhasil dibuat.';