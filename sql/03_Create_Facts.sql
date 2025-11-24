/* File: 03_Create_Facts.sql
   Deskripsi: Membuat Tabel Fakta dan Definisi Relasi (FK)
*/

USE DM_SatuDataITERA_DW;
GO

-- 1. Fact_Dataset_Access
-- Mencatat setiap event akses (View/Download/API Call)
CREATE TABLE dbo.Fact_Dataset_Access (
    Access_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys
    Dataset_SK INT NOT NULL,
    User_SK INT NOT NULL,
    Category_SK INT NOT NULL,
    Organization_SK INT NOT NULL,
    Time_SK INT NOT NULL,
    Data_Source_SK INT NOT NULL,
    
    -- Measures 
    Jumlah_Akses INT DEFAULT 1,
    Jumlah_Download INT DEFAULT 0,
    Jumlah_View INT DEFAULT 0,            
    Jumlah_API_Call INT DEFAULT 0,       
    File_Size_Downloaded BIGINT,          -- Bytes
    Response_Time_MS INT,                 -- Milliseconds
    Success_Flag INT,                     -- 1 = Sukses, 0 = Gagal
    
    -- Hubungan
    CONSTRAINT FK_Access_Dataset FOREIGN KEY (Dataset_SK) REFERENCES dbo.Dim_Dataset(Dataset_SK),
    CONSTRAINT FK_Access_User FOREIGN KEY (User_SK) REFERENCES dbo.Dim_User(User_SK),
    CONSTRAINT FK_Access_Category FOREIGN KEY (Category_SK) REFERENCES dbo.Dim_Category(Category_SK),
    CONSTRAINT FK_Access_Organization FOREIGN KEY (Organization_SK) REFERENCES dbo.Dim_Organization(Organization_SK),
    CONSTRAINT FK_Access_Time FOREIGN KEY (Time_SK) REFERENCES dbo.Dim_Time(Time_SK),
    CONSTRAINT FK_Access_DataSource FOREIGN KEY (Data_Source_SK) REFERENCES dbo.Dim_Data_Source(Data_Source_SK)
);
GO

-- 2. Fact_Dataset_Quality
-- Snapshot kualitas dataset per periode pengumpulan
CREATE TABLE dbo.Fact_Dataset_Quality (
    Quality_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys
    Dataset_SK INT NOT NULL,
    Time_SK INT NOT NULL,                 -- Tanggal pengecekan
    
    -- Measures 
    Completeness_Score DECIMAL(5,2),      -- 0-100
    Accuracy_Score DECIMAL(5,2),
    Timeliness_Score DECIMAL(5,2),
    Consistency_Score DECIMAL(5,2),
    Overall_Quality_Score DECIMAL(5,2),
    Missing_Values INT,
    Duplicate_Records INT,
    Total_Records INT,
    
    -- Hubungan
    CONSTRAINT FK_Quality_Dataset FOREIGN KEY (Dataset_SK) REFERENCES dbo.Dim_Dataset(Dataset_SK),
    CONSTRAINT FK_Quality_Time FOREIGN KEY (Time_SK) REFERENCES dbo.Dim_Time(Time_SK)
);
GO

-- 3. Fact_Search_Query
-- Log pencarian user untuk analisis kata kunci
CREATE TABLE dbo.Fact_Search_Query (
    Search_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys
    User_SK INT,                          -- bisa anonim
    Time_SK INT NOT NULL,
    
    -- Measures
    Query_Text TEXT,                      -- Kata kunci pencarian
    Jumlah_Pencarian INT DEFAULT 1,
    Jumlah_Hasil INT,                     -- Jumlah dataset ditemukan
    Click_Through_Flag INT,               -- 1 jika user mengklik hasil
    Search_Time_MS INT,                   -- Lama waktu pencarian
    
    -- Hubungan
    CONSTRAINT FK_Search_User FOREIGN KEY (User_SK) REFERENCES dbo.Dim_User(User_SK),
    CONSTRAINT FK_Search_Time FOREIGN KEY (Time_SK) REFERENCES dbo.Dim_Time(Time_SK)
);
GO

-- 4. Fact_Institution_Metrics
-- Agregat metrik institusi (bulanan/kuartalan)
CREATE TABLE dbo.Fact_Institution_Metrics (
    Metric_SK INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys
    Organization_SK INT NOT NULL,
    Time_SK INT NOT NULL,
    
    -- Measures
    Total_Dataset_Published INT,
    Total_Downloads INT,
    Avg_Quality_Score DECIMAL(5,2),
    Total_Active_Users INT,
    
    -- Hubungan
    CONSTRAINT FK_Metric_Organization FOREIGN KEY (Organization_SK) REFERENCES dbo.Dim_Organization(Organization_SK),
    CONSTRAINT FK_Metric_Time FOREIGN KEY (Time_SK) REFERENCES dbo.Dim_Time(Time_SK)
);
GO

PRINT 'Tabel Fakta berhasil dibuat.';