/* File: 04_Create_Indexes.sql
   Deskripsi: Strategi Indexing untuk optimasi performa query
*/

USE DM_SatuDataITERA_DW;
GO

-- Non-Clustered Indexes untuk Foreign Keys
-- Mempercepat JOIN antara tabel fact dan Dimensi

-- Index untuk Fact_Dataset_Access
CREATE NONCLUSTERED INDEX IX_Fact_Access_DatasetSK ON dbo.Fact_Dataset_Access(Dataset_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Access_UserSK ON dbo.Fact_Dataset_Access(User_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Access_TimeSK ON dbo.Fact_Dataset_Access(Time_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Access_CategorySK ON dbo.Fact_Dataset_Access(Category_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Access_OrgSK ON dbo.Fact_Dataset_Access(Organization_SK);

-- Index untuk Fact_Dataset_Quality
CREATE NONCLUSTERED INDEX IX_Fact_Quality_DatasetSK ON dbo.Fact_Dataset_Quality(Dataset_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Quality_TimeSK ON dbo.Fact_Dataset_Quality(Time_SK);

-- Index untuk Fact_Search_Query
CREATE NONCLUSTERED INDEX IX_Fact_Search_UserSK ON dbo.Fact_Search_Query(User_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Search_TimeSK ON dbo.Fact_Search_Query(Time_SK);

-- Index untuk Fact_Institution_Metrics
CREATE NONCLUSTERED INDEX IX_Fact_Metric_OrgSK ON dbo.Fact_Institution_Metrics(Organization_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Metric_TimeSK ON dbo.Fact_Institution_Metrics(Time_SK);

-- Index untuk ETL Lookup Performance
CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_User_UserID ON dbo.Dim_User(User_ID);
CREATE NONCLUSTERED INDEX IX_Dim_Dataset_DatasetID_Current 
    ON dbo.Dim_Dataset(Dataset_ID, Is_Current) 
    INCLUDE (Dataset_SK, Kategori_Nama)
    WHERE Is_Current = 1;
CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Category_Nama ON dbo.Dim_Category(Nama_Kategori);
CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Organization_Nama ON dbo.Dim_Organization(Nama_Unit);

-- Composite Index untuk Duplicate Prevention di Facts
CREATE NONCLUSTERED INDEX IX_Fact_Access_DuplicateCheck 
    ON dbo.Fact_Dataset_Access(Dataset_SK, User_SK, Time_SK, Response_Time_MS);

-- Columnstore Index
-- Diperlukan untuk query agregasi pada tabel besar

-- Kita terapkan pada tabel transaksi terbesar: Fact_Dataset_Access karena tabel event utama
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCIX_Fact_Dataset_Access
ON dbo.Fact_Dataset_Access
(
    Dataset_SK, 
    User_SK, 
    Time_SK, 
    Jumlah_Akses, 
    Jumlah_Download, 
    File_Size_Downloaded
);
GO

PRINT 'Indexing berhasil dibuat.';