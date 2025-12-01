/* File: 05_Create_Partitions_FIXED.sql
   Deskripsi: Implementasi Table Partitioning
   Target Tabel: Fact_Dataset_Access
*/

USE DM_SatuDataITERA_DW;
GO

-- 1. Membuat Partition Function
IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_Yearly')
BEGIN
    CREATE PARTITION FUNCTION PF_Yearly (INT)
    AS RANGE RIGHT FOR VALUES 
    (
        20240101, 
        20250101, 
        20260101
    );
END
GO

-- 2. Membuat Partition Scheme
IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_Yearly')
BEGIN
    CREATE PARTITION SCHEME PS_Yearly
    AS PARTITION PF_Yearly
    ALL TO ([PRIMARY]);
END
GO

-- 3. Implementasi Partisi
BEGIN TRANSACTION;

    -- A. DROP COLUMNSTORE INDEX DULU
    -- Kita harus menghapusnya sementara agar tabel bisa dimodifikasi
    DROP INDEX IF EXISTS NCCIX_Fact_Dataset_Access ON dbo.Fact_Dataset_Access;

    -- B. Hapus PK lama (Clustered Index lama)
    DECLARE @pk_name NVARCHAR(128);
    SELECT @pk_name = name
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('dbo.Fact_Dataset_Access')
      AND type = 'PK';

    IF @pk_name IS NOT NULL
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = 'ALTER TABLE dbo.Fact_Dataset_Access DROP CONSTRAINT ' + @pk_name;
        EXEC sp_executesql @sql;
    END

    -- C. Buat ulang PK sebagai Clustered Index DI ATAS Partition Scheme
    ALTER TABLE dbo.Fact_Dataset_Access
    ADD CONSTRAINT PK_Fact_Dataset_Access_Partitioned 
    PRIMARY KEY CLUSTERED (Access_SK, Time_SK)
    ON PS_Yearly(Time_SK);

    -- D. BUAT ULANG COLUMNSTORE INDEX
    -- Dengan ini index akan otomatis selaras dengan partisi baru
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

COMMIT TRANSACTION;
GO

PRINT 'Sukses! Partitioning berhasil dan Columnstore Index telah dibuat ulang.';